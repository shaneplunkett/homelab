#!/bin/sh
set -eu

PALWORLD_DIR="${PALWORLD_DIR:-/opt/palworld}"
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-sftp:u558795@u558795.your-storagebox.de:./palworld}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/root/.restic-password}"
SFTP_OPTS="${SFTP_OPTS:-sftp.args=-p 23}"
KUMA_PUSH_URL_FILE="${KUMA_PUSH_URL_FILE:-$PALWORLD_DIR/.backup-kuma-url}"
RUN_RESTIC_PRUNE="${RUN_RESTIC_PRUNE:-true}"
server_was_running=false

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

server_is_running() {
  docker compose --project-directory "$PALWORLD_DIR" ps \
    --status running \
    --services |
    grep -qx palworld-server
}

start_server() {
  if [ "$server_was_running" = true ]; then
    log "Starting Palworld server."
    docker compose --project-directory "$PALWORLD_DIR" up -d palworld-server
    server_was_running=false
  fi
}

cleanup() {
  exit_status="$?"
  start_server || exit_status="$?"

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

if [ ! -d "$PALWORLD_DIR/Saved" ]; then
  log "Save directory has not materialised; refusing to report a successful backup."
  exit 1
fi

log "Starting backup."
if server_is_running; then
  server_was_running=true
  log "Stopping Palworld cleanly for a consistent save snapshot."
  docker compose --project-directory "$PALWORLD_DIR" stop -t 120 palworld-server
fi

log "Pushing save data and deployment config to the storage box."
retry restic backup \
  "$PALWORLD_DIR/Saved" \
  "$PALWORLD_DIR/docker-compose.yml" \
  "$PALWORLD_DIR/palserver-entrypoint.sh" \
  "$PALWORLD_DIR/backup.sh" \
  --option "$SFTP_OPTS" \
  --tag palworld \
  --host palworld

if [ "$RUN_RESTIC_PRUNE" = "true" ]; then
  log "Applying retention policy."
  retry restic forget \
    --option "$SFTP_OPTS" \
    --tag palworld \
    --keep-last 8 \
    --keep-daily 14 \
    --keep-weekly 4 \
    --prune
else
  log "Skipping retention prune."
fi

start_server
