# 贡献指南

感谢你想为 Claude Code Archon 出力！这份文档说明怎么贡献。

## 贡献方式

### 1. 报告 Bug / 提建议
开 issue，描述：
- 场景（你在做什么）
- 预期行为 vs 实际行为
- 复现步骤

### 2. 贡献新的 Agent 预设
特别欢迎你积累的**技术栈专用 agent**（Vue / Flutter / SwiftUI / Go / Rust ...）。

步骤：
1. 基于 `agents/presets/universal/dev-agent.md` 派生
2. 放到 `agents/presets/stacks/<stack>-dev-agent.md`
3. 保留硬边界模板结构（职责/禁令/权限/输出/越界处理）
4. 只加"增量"约束，不重写基础规则
5. 开 PR

### 3. 改善 Universal 预设
对已有 universal agent 的改进：
- 先开 issue 讨论（避免破坏他人依赖）
- PR 标题用 `[universal/<agent-name>] 简述`
- 说明"为什么这样改更好"+ 具体场景

### 4. 改善模板（CLAUDE.md / requirements.md / UX-checklist 等）
直接 PR 即可，但需附上"这条规则避免了什么具体问题"的说明。

### 5. 改善安装脚本
双平台保持一致：改了 install.sh 要同步改 install.ps1。

## 硬边界模板（所有子 agent 必守）

```markdown
---
name: <agent-name>
description: <一句话>
tools: <工具列表>
---

# <agent-name>

## 职责（MUST DO）
## 禁令（MUST NOT）
## 文件权限
## 工具权限
## 工作流
## 输出格式（结构化 JSON）
## 越界处理
```

任何缺项的 PR 会被要求补全。

## 测试

目前 kit 主要是文本资产，无自动化测试。贡献时请在你自己项目跑一遍，确认能用。

## 行为准则

- 先假设善意
- 批评代码/设计，不批评人
- 新手问题欢迎，没有"愚蠢的问题"

## 发布流程（维护者）

1. 合并 PR
2. 更新 `CHANGELOG.md`
3. 打 tag：`git tag -a v1.x.y -m "..."`
4. GitHub Release 写人话版更新说明

## License

所有贡献以 MIT 许可提交。
