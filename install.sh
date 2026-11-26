#!/usr/bin/env bash
# Install the Claude Code status line for this user: symlinks statusline.sh into ~/.claude
# and sets statusLine in ~/.claude/settings.json (other settings are kept). Needs jq.
set -euo pipefail
command -v jq >/dev/null || { echo "jq is required (sudo apt install jq / brew install jq)"; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
mkdir -p ~/.claude
chmod +x "$here/statusline.sh"
ln -sfn "$here/statusline.sh" ~/.claude/statusline.sh   # symlink: git pull updates it
s=~/.claude/settings.json
[ -f "$s" ] || echo '{}' > "$s"
cp "$s" "$s.bak"
jq '.statusLine = {"type":"command","command":"bash \"$HOME/.claude/statusline.sh\""}' "$s.bak" > "$s"
echo "Installed. Restart Claude Code to see the status line. Backup: $s.bak"
