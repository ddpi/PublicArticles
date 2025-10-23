#!/usr/bin/env bash
# .claude/hooks/user_prompt_submit.sh
# ユーザプロンプト送信時にユーザ指示をSlackに投稿

set -euo pipefail

# ---- Load .env file if exists ----
if [ -f "${CLAUDE_PROJECT_DIR}/.env" ]; then
  export $(grep -v '^#' "${CLAUDE_PROJECT_DIR}/.env" | grep -v '^$' | xargs)
fi

# ---- Config ----
: "${SLACK_WEBHOOK_URL:?Set SLACK_WEBHOOK_URL in your env or .env file}"

# ---- Read Hook JSON (from Claude Code) ----
payload="$(cat)"
session_id="$(echo "$payload" | jq -r '.session_id')"
prompt="$(echo "$payload" | jq -r '.prompt // ""')"
cwd="$(echo "$payload" | jq -r '.cwd // ""')"

# ---- Extract user prompt content ----
if [ -n "$prompt" ] && [ "$prompt" != "null" ]; then
  display_user_message="$prompt"
else
  display_user_message="（プロンプトなし）"
fi

# Build Slack message
# Truncate to 500 chars and add ellipsis if needed
truncated_message="${display_user_message:0:500}"
if [ ${#display_user_message} -gt 500 ]; then
  truncated_message="${truncated_message}..."
fi
TEXT=$(printf "💬 *ユーザ指示受信*\n\n%s" "$truncated_message")

# Post to Slack
curl -sS -X POST \
  -H 'Content-type: application/json' \
  --data "$(jq -Rn --arg txt "$TEXT" '{text:$txt}')" \
  "$SLACK_WEBHOOK_URL" >/dev/null

# Exit 0 so Claude Code continues normal operation
exit 0