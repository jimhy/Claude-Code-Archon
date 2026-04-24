#!/usr/bin/env bash
# Pre-commit 安全检查 hook 示例
# 部署为：<project>/scripts/check-commit-safety.sh，chmod +x
#
# 职责：
# - 若当前 Bash 命令是 git commit → 跑 lint + type + unit test，任一失败则阻断
# - 其它命令直接放行

set -euo pipefail

# Claude Code 会把工具输入传递到环境变量 CLAUDE_TOOL_INPUT（格式见文档）
# 这里用简单方式：从 stdin 读 tool_input JSON
TOOL_INPUT="$(cat)"

# 提取实际的 Bash 命令
COMMAND="$(echo "$TOOL_INPUT" | jq -r '.command // empty')"

# 不是 git commit → 放行
if ! echo "$COMMAND" | grep -qE '^git commit'; then
  exit 0
fi

echo "🔒 Pre-commit gate: 检查 lint / type / unit tests..."

# Lint
if [[ -f package.json ]] && jq -e '.scripts.lint' package.json > /dev/null; then
  if ! npm run lint --silent; then
    echo "❌ ESLint 失败 → 不能 commit"
    exit 1
  fi
fi

# Type check
if [[ -f tsconfig.json ]]; then
  if ! npx tsc --noEmit; then
    echo "❌ TypeScript 错误 → 不能 commit"
    exit 1
  fi
fi

# Unit tests（仅跑修改文件相关的）
if [[ -f package.json ]] && jq -e '.scripts.test' package.json > /dev/null; then
  # 只跑 unit test，不跑 E2E
  if ! npm run test -- --run tests/unit 2>/dev/null; then
    # fallback
    if ! npm test -- --run; then
      echo "❌ 单元测试失败 → 不能 commit"
      exit 1
    fi
  fi
fi

echo "✅ 通过 commit gate"
exit 0
