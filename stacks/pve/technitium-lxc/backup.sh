#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/opt/technitium/backup-staging}"
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-sftp:u558795@u558795.your-storagebox.de:./backups}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/opt/technitium/.restic-password}"
SFTP_OPTS="${SFTP_OPTS:-sftp.args=-p 23}"
KUMA_PUSH_URL_FILE="${KUMA_PUSH_URL_FILE:-/opt/technitium/.backup-kuma-url}"
RUN_RESTIC_PRUNE="${RUN_RESTIC_PRUNE:-true}"
ADMIN_PASSWORD_FILE="${ADMIN_PASSWORD_FILE:-/opt/technitium/admin-password.txt}"
API="http://127.0.0.1:5380/api"

export RESTIC_REPOSITORY
export RESTIC_PASSWORD_FILE

log() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*"
}

ping_kuma() {
  push_status="$1"
  push_msg="$2"

  if [ -s "$KUMA_PUSH_URL_FILE" ]; then
    wget -qO- "$(cat "$KUMA_PUSH_URL_FILE")?status=$push_status&msg=$push_msg" >/dev/null 2>&1 || true
  fi
}

cleanup() {
  exit_status="$?"
  rm -rf "$BACKUP_DIR"

  if [ "$exit_status" -eq 0 ]; then
    ping_kuma up OK
    log "Backup complete."
  else
    ping_kuma down FAILED
    log "Backup failed with status $exit_status."
  fi

  exit "$exit_status"
}

retry() {
  attempt=1
  while [ "$attempt" -le 3 ]; do
    if "$@"; then
      return 0
    fi

    log "Attempt $attempt failed: $*"
    attempt=$((attempt + 1))
    sleep 30
  done

  return 1
}

trap cleanup EXIT INT TERM

log "Starting backup."
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR/technitium" "$BACKUP_DIR/config"

log "Exporting Technitium config zip via API."
TOKEN=$(wget -qO- "$API/user/login?user=admin&pass=$(cat "$ADMIN_PASSWORD_FILE")" | sed -n 's/.*"token":"\([a-f0-9]*\)".*/\1/p')
[ -n "$TOKEN" ] || { log "API login failed"; exit 1; }
wget -qO "$BACKUP_DIR/technitium/technitium-config.zip" \
  "$API/settings/backup?token=$TOKEN&blockLists=false&logs=false&scopes=true&stats=false&zones=true&allowedZones=true&blockedZones=true&dnsSettings=true&authConfig=true&logSettings=true&apps=true"
wget -qO- "$API/user/logout?token=$TOKEN" >/dev/null 2>&1 || true

log "Copying config volume (raw)."
cp -r /var/lib/docker/volumes/technitium_config/_data "$BACKUP_DIR/technitium/config-volume"

log "Copying stack config."
cp /opt/technitium/docker-compose.yml "$BACKUP_DIR/config/technitium-docker-compose.yml"
cp "$ADMIN_PASSWORD_FILE" "$BACKUP_DIR/config/admin-password.backup"

log "Writing backup manifest."
{
  echo "created_at=$(date '+%Y-%m-%dT%H:%M:%S%z')"
  echo "host=$(hostname)"
  echo "restic_repository=$RESTIC_REPOSITORY"
  echo "config_zip_bytes=$(wc -c < "$BACKUP_DIR/technitium/technitium-config.zip")"
} > "$BACKUP_DIR/manifest.txt"

log "Pushing to storage box."
retry restic backup "$BACKUP_DIR" --option "$SFTP_OPTS" --tag technitium

if [ "$RUN_RESTIC_PRUNE" = "true" ]; then
  log "Applying retention policy."
  retry restic forget --option "$SFTP_OPTS" \
    --tag technitium \
    --keep-daily 7 \
    --keep-weekly 4 \
    --prune
else
  log "Skipping retention prune."
fi
