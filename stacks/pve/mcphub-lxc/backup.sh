#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/opt/mcphub/backup-staging}"
RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-sftp:u558795@u558795.your-storagebox.de:./backups}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-/opt/mcphub/.restic-password}"
SFTP_OPTS="${SFTP_OPTS:-sftp.args=-p 23}"
KUMA_PUSH_URL_FILE="${KUMA_PUSH_URL_FILE:-/opt/mcphub/.backup-kuma-url}"
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
mkdir -p "$BACKUP_DIR/mcphub" "$BACKUP_DIR/vex-brain" "$BACKUP_DIR/config"

log "Dumping MCPHub PostgreSQL."
docker exec mcphub-postgres-1 pg_dump -U mcphub mcphub > "$BACKUP_DIR/mcphub/mcphub-postgres.sql"

log "Dumping vex-brain PostgreSQL."
docker exec vex-brain-postgres pg_dump -U vex_brain -d vex_brain -Fc --no-owner --no-acl > "$BACKUP_DIR/vex-brain/vex-brain.dump"
docker exec -i vex-brain-postgres pg_restore -l < "$BACKUP_DIR/vex-brain/vex-brain.dump" > "$BACKUP_DIR/vex-brain/vex-brain.dump.toc"
sha256sum "$BACKUP_DIR/vex-brain/vex-brain.dump" > "$BACKUP_DIR/vex-brain/vex-brain.dump.sha256"

log "Copying Neo4j data volume."
cp -r /var/lib/docker/volumes/mcphub_neo4j_data/_data "$BACKUP_DIR/mcphub/neo4j-data"

log "Copying MCPHub memory and config."
cp /opt/mcphub/mcp-memory/memory.jsonl "$BACKUP_DIR/mcphub/" 2>/dev/null || true
cp /opt/mcphub/docker-compose.yml "$BACKUP_DIR/config/mcphub-docker-compose.yml"
cp /opt/mcphub/mcp_settings.json "$BACKUP_DIR/config/mcp_settings.json"
cp /opt/mcphub/graphiti-config.yaml "$BACKUP_DIR/config/graphiti-config.yaml"
cp /opt/mcphub/.env "$BACKUP_DIR/config/mcphub.env.backup"
cp -r /opt/mcphub/patches "$BACKUP_DIR/config/"
cp /opt/vex-brain/docker-compose.yml "$BACKUP_DIR/config/vex-brain-docker-compose.yml"
cp /opt/vex-brain/docker-compose.override.yml "$BACKUP_DIR/config/vex-brain-docker-compose.override.yml" 2>/dev/null || true
cp /opt/vex-brain/.env "$BACKUP_DIR/config/vex-brain.env.backup" 2>/dev/null || true
cp -r /opt/mcphub/.google_workspace_mcp "$BACKUP_DIR/config/" 2>/dev/null || true

log "Writing backup manifest."
{
  echo "created_at=$(date '+%Y-%m-%dT%H:%M:%S%z')"
  echo "host=$(hostname)"
  echo "restic_repository=$RESTIC_REPOSITORY"
  echo "mcphub_postgres_bytes=$(wc -c < "$BACKUP_DIR/mcphub/mcphub-postgres.sql")"
  echo "vex_brain_dump_bytes=$(wc -c < "$BACKUP_DIR/vex-brain/vex-brain.dump")"
  echo "vex_brain_toc_entries=$(wc -l < "$BACKUP_DIR/vex-brain/vex-brain.dump.toc")"
} > "$BACKUP_DIR/manifest.txt"

log "Pushing to storage box."
retry restic backup "$BACKUP_DIR" --option "$SFTP_OPTS" --tag mcphub --tag vex-brain

if [ "$RUN_RESTIC_PRUNE" = "true" ]; then
  log "Applying retention policy."
  retry restic forget --option "$SFTP_OPTS" \
    --tag mcphub \
    --keep-last 6 \
    --keep-daily 7 \
    --keep-weekly 4 \
    --prune
else
  log "Skipping retention prune."
fi
