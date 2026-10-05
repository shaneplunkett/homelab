#!/usr/bin/env bash
# headersHelper for the Cloudflare MCP server in .mcp.json.
# Reads the API token from rbw so it never lands in a config file.
set -euo pipefail
token=$(rbw get homelab_cf_token)
jq -cn --arg t "$token" '{Authorization: "Bearer \($t)"}'
