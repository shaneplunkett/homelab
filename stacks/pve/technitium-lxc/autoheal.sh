#!/bin/sh
# Restart the technitium container when its Docker healthcheck reports
# unhealthy. Plain Docker only marks unhealthy; it never restarts on its own.
# Runs from root's crontab every 2 minutes.
set -eu

id=$(docker ps -q --filter "name=^technitium$" --filter "health=unhealthy")

if [ -n "$id" ]; then
  echo "[$(date '+%Y-%m-%dT%H:%M:%S%z')] technitium unhealthy, restarting."
  docker restart "$id"
fi
