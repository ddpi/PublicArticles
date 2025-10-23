#!/usr/bin/env bash
# .claude/hooks/assistant_response_complete.sh
# アシスタント応答完了時にClaude応答をSlackに投稿

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
transcript_path="$(echo "$payload" | jq -r '.transcript_path')"
cwd="$(echo "$payload" | jq -r '.cwd // ""')"

# ---- Extract Claude response from transcript ----
if [ -f "$transcript_path" ]; then
  # Get the last assistant response UUID to find all parts of the response
  last_assistant_uuid="$(tail -20 "$transcript_path" | jq -r 'select(.type == "assistant" and .message.role == "assistant") | .uuid' | tail -1)"

  # Get all text content from the last assistant response
  last_assistant_text="$(tail -20 "$transcript_path" | jq -r --arg uuid "$last_assistant_uuid" 'select(.type == "assistant" and .uuid == $uuid) | .message.content[] | select(.type == "text") | .text' | paste -sd "\n" -)"

  # Prepare display content
  display_assistant_message="${last_assistant_text:-（応答なし）}"

  # Truncate message if longer than 15000 characters
  if [ ${#display_assistant_message} -gt 15000 ]; then
    truncated_message="${display_assistant_message:0:15000}..."
  else
    truncated_message="$display_assistant_message"
  fi

  # Build Slack message
  TEXT=$(printf "🤖 *Claude応答完了*\n\n%s" "$truncated_message")
else
  # Fallback if transcript file not found
  TEXT=$(printf "🤖 *Claude応答完了*\n\n📁 *Project:* \`%s\`\n⚠️ *エラー:* トランスクリプトファイルが見つかりません\nPath: \`%s\`" \
    "${cwd##*/}" \
    "$transcript_path")
fi

# Post to Slack
curl -sS -X POST \
  -H 'Content-type: application/json' \
  --data "$(jq -Rn --arg txt "$TEXT" '{text:$txt}')" \
  "$SLACK_WEBHOOK_URL" >/dev/null

# Exit 0 so Claude Code continues normal operation
exit 0
