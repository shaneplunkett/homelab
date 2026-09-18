#!/bin/sh
set -eu

SATISFACTORY_DIR="${SATISFACTORY_DIR:-/opt/satisfactory}"
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-sftp:u558795@u558795.your-storagebox.de:./satisfactory}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/root/.restic-password}"
SFTP_OPTS="${SFTP_OPTS:-sftp.args=-p 23}"
KUMA_PUSH_URL_FILE="${KUMA_PUSH_URL_FILE:-$SATISFACTORY_DIR/.backup-kuma-url}"
RUN_RESTIC_PRUNE="${RUN_RESTIC_PRUNE:-true}"

export RESTIC_REPOSITORY
export RESTIC_PASSWORD_FILE

log() {
  echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] $*"
}

ping_kuma() {
  push_status="$1"
  push_msg="$2"

  if [ -s "$KUMA_PUSH_URL_FILE" ]; then
    curl -fsS "$(cat "$KUMA_PUSH_URL_FILE")?status=$push_status&msg=$push_msg" >/dev/null 2>&1 || true
  fi
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

cleanup() {
  exit_status="$?"

  if [ "$exit_status" -eq 0 ]; then
    ping_kuma up OK
    log "Backup complete."
  else
    ping_kuma down FAILED
    log "Backup failed with status $exit_status."
  fi

  exit "$exit_status"
}

trap cleanup EXIT INT TERM

if [ ! -d "$SATISFACTORY_DIR/config/saved" ]; then
  log "Save directory has not materialised; refusing to report a successful backup."
  exit 1
fi

log "Pushing save data and deployment config to the storage box."
retry restic backup \
  "$SATISFACTORY_DIR/config/saved" \
  "$SATISFACTORY_DIR/config/backups" \
  "$SATISFACTORY_DIR/docker-compose.yml" \
  "$SATISFACTORY_DIR/backup.sh" \
  --option "$SFTP_OPTS" \
  --tag satisfactory \
  --host satisfactory

if [ "$RUN_RESTIC_PRUNE" = "true" ]; then
  log "Applying retention policy."
  retry restic forget \
    --option "$SFTP_OPTS" \
    --tag satisfactory \
    --keep-last 8 \
    --keep-daily 14 \
    --keep-weekly 4 \
    --prune
else
  log "Skipping retention prune."
fi
