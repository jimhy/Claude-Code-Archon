#!/usr/bin/env bash
# Stop hook：Claude 声称完成时，验证证据是否齐全
# 部署为：<project>/scripts/verify-deliverables.sh，chmod +x

set -euo pipefail

# 判断：本次 session 是否有 UI 相关改动？
UI_CHANGED=$(git diff --name-only HEAD~1 HEAD 2>/dev/null | grep -E '\.(tsx|jsx|vue|svelte|css|scss|html)$' | head -1 || true)

if [[ -n "$UI_CHANGED" ]]; then
  # 需要对应的 playwright 录屏或截图证据
  EVIDENCE_COUNT=$(find test-results -type f \( -name "*.webm" -o -name "*.mp4" -o -name "*.png" \) 2>/dev/null -newer .git/HEAD | wc -l || echo "0")

  if [[ "$EVIDENCE_COUNT" -eq 0 ]]; then
    cat >&2 <<EOF
⚠️  检测到 UI 文件变更但没有 Playwright 截图/录屏证据。

按项目 CLAUDE.md 的第 2 条铁律："UI 必须截图验证"。

请先让 qa-agent 跑 E2E 并录屏，确认没问题再结束本轮。

改动的 UI 文件：
$UI_CHANGED
EOF
    exit 2  # exit 2 = 阻断 Stop，提示 Claude 继续
  fi
fi

exit 0
