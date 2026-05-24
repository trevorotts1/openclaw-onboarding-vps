#!/usr/bin/env bash
# install-pm2-restart-hook.sh — adds a pm2-resurrect-on-boot hook to a Hostinger
# OpenClaw client's docker-compose.yml. Run on the HOST (the Hostinger VPS),
# NOT inside the container.
#
# Usage:
#   ./install-pm2-restart-hook.sh /docker/<project>
#
# Idempotent. Detects an existing hook by looking for "v10.14.23" marker line.
set -euo pipefail

PROJ_DIR="${1:?Usage: $0 /docker/<project>}"
COMPOSE="$PROJ_DIR/docker-compose.yml"
[ -f "$COMPOSE" ] || { echo "no docker-compose.yml at $COMPOSE"; exit 1; }

if grep -q "v10.14.23: background pm2 resurrect" "$COMPOSE" 2>/dev/null; then
  echo "[install-pm2-restart-hook] hook already present in $COMPOSE — skipping"
  exit 0
fi

# Backup
BAK="$COMPOSE.bak-pre-pm2-hook-$(date +%s)"
cp "$COMPOSE" "$BAK"
echo "[install-pm2-restart-hook] backup: $BAK"

# Append `command:` block under the openclaw service. Strategy: if the file
# already has a `command:` directive under `openclaw:`, abort and tell operator
# to merge manually. Otherwise append.
if grep -qE "^\s+command:" "$COMPOSE"; then
  echo "[install-pm2-restart-hook] WARN: $COMPOSE already has a 'command:' directive — refusing to overwrite. Merge manually."
  exit 2
fi

# Append the command: block to the openclaw service
cat >> "$COMPOSE" << 'YAML_EOF'
    command:
      - "sh"
      - "-c"
      - |
        # v10.14.23: background pm2 resurrect after openclaw gateway warmup.
        # Waits 45s for openclaw gateway + plugins to finish booting, then
        # resurrects pm2's saved process list (command-center + cloudflare-tunnel)
        # from /data/.pm2/dump.pm2. Idempotent.
        ( sleep 45 && export PATH=/data/.npm-global/bin:/data/linuxbrew/.linuxbrew/bin:$PATH && pm2 resurrect 2>&1 | tee -a /tmp/pm2-boot-resurrect.log ) &
        exec node server.mjs
YAML_EOF

# Validate
if ! ( cd "$PROJ_DIR" && docker compose config >/dev/null 2>&1 ); then
  echo "[install-pm2-restart-hook] ERROR: compose config invalid after edit — reverting"
  mv "$BAK" "$COMPOSE"
  exit 3
fi

echo "[install-pm2-restart-hook] hook installed. Apply with:"
echo "  cd $PROJ_DIR && docker compose up -d --force-recreate"
