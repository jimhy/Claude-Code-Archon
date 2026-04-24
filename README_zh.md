# Claude Code Archon

[English](README.md) | **中文**

> *把 Claude Code 升级为自主开发军团的执政官。*
> 主 agent 发号施令，一众子 agent 执行到底——你只在两个端点出场：需求挖掘和成品交付。

一套久经实战的 CLAUDE.md + agents 集合，把 Claude Code 从"助手"升级为**会自己开车的开发团队**。

**零命令、零安装脚本**。拷贝一个文件夹 → 打开 Claude Code → 自然语言说话就行。

---

## 怎么用（就两步）

### 第 1 步：拷贝 `.claude/` 文件夹

选一个位置：

| 位置 | 效果 |
|------|------|
| `~/.claude/`（全局）| 所有项目都能用 |
| `<你的项目>/.claude/`（项目级）| 只这个项目用，可覆盖全局 |

**Windows**：
```
把 .claude/ 拖到 C:\Users\你的用户名\.claude\
或拖到 项目根目录\.claude\
```

**Mac / Linux**：
```bash
cp -r .claude ~/.claude
# 或
cp -r .claude <你的项目>/.claude
```

> **提示**：如果目标目录已有 `.claude/`，手动合并（主要是 `agents/` 下的文件）。

### 第 2 步：打开 Claude Code，直接说话

```
你：我想做一个记账 app，自己用，能同步到云端。

Claude：（自动识别这是新项目 → 派 kickoff-agent）
  嘿，开始前我快速了解你 3 件事，后面按你的情况调整讲话方式：
  1. 你平时写代码吗？
  ...
```

**就这样**。不用记 `/kickoff`，不用读文档，不用跑脚本。

---

## 它会做什么

根据你说的话，Claude 自动判断意图并派对应子 agent。

| 你说的话 | 自动发生的事 |
|---------|-------------|
| "我想做一个 X" | 走完整需求挖掘（画像识别 → 5 问 → 竞品研究 → HTML 选项页 → A/B 追问 → 需求圣经） |
| "加一个功能 X" | 走简化版需求挖掘 |
| "修一下 X 的 bug" | qa-agent 先写复现用例 → dev-agent 修 → 回归测试 |
| "改 X 的样式" | dev-agent 改 + ui-critic 审视觉 |
| "X 看起来丑" | ui-critic 先诊断，再派 dev-agent |
| "X 用起来不顺手" | ux-critic 对 UX 清单打钩诊断 |
| "跑测试" / "看有没有问题" | qa-agent 跑 E2E + 录屏 |
| "打包 / 发布 / 上线" | integration-agent → delivery-agent 出交付包 |
| "总结反馈" | triage-agent 分类 bug/优化/新需求 |

**整个开发过程用户零打扰**。只在需求挖掘 + 交付使用两个端点参与。

---

## 这套 kit 解决什么问题

默认 Claude Code 在项目中后期常出这些问题：

- **UI 丑** — Claude 写完不看、没参照，出 Bootstrap 风
- **UX 差** — 只走 happy path，没 loading/empty/error、移动端崩
- **Bug 雪崩** — 改 A 坏 B，"顺手优化"制造新问题
- **测试不可靠** — Claude 说"测试通过"实际各种毛病
- **节奏失控** — 每个阶段都找用户确认，用户成瓶颈
- **沟通千篇一律** — 对小白讲 React，对专家讲基础

解决方案（本 kit 内置）：

1. **用户画像分层沟通** — 识别小白/非技术/技术/专家，按画像调整术语和决策权
2. **Kickoff 六阶段协议** — 画像识别 + 5 问 + 竞品研究 + HTML 选项页 + A/B 追问 + 需求圣经
3. **主 agent 只调度 + 13 个硬边界子 agent** — 每个 agent 职责/权限/输出格式写死
4. **独立评审闭环** — ui-critic / ux-critic / code-reviewer 独立上下文评审，不看写码过程
5. **客观证据验收** — 单元测试 + E2E 录屏 + 截图 + Lighthouse 全绿才算完成
6. **端点参与模型** — 用户只在需求和交付两端参与，中段 AI 全自主
7. **反馈闭环** — triage-agent 分类，批量增量交付

---

## 目录结构

```
claude-code-archon/
├── .claude/                      ← ⭐ 拷贝这个文件夹就行
│   ├── CLAUDE.md                  # 核心规则（对话路由 + 九条铁律 + Orchestrator 规则）
│   ├── user-profile.md            # 用户画像（首次对话自动填）
│   ├── playbooks/                 # 主 agent 自己执行的剧本（含多轮用户对话）
│   │   ├── kickoff.md               需求挖掘六阶段
│   │   └── platform-setup.md        按目标平台自动装测试/开发工具链
│   └── agents/                    # 13 个 subagent（封闭一次性任务）
│       ├── dev-agent.md                 写代码
│       ├── react-dev-agent.md           （示例）React 栈专用
│       ├── qa-agent.md                  E2E 测试
│       ├── ui-critic.md                 视觉评审
│       ├── ux-critic.md                 交互评审
│       ├── code-reviewer.md             代码审查
│       ├── integration-agent.md         打包部署
│       ├── delivery-agent.md            交付
│       ├── triage-agent.md              反馈分类
│       ├── agent-creator.md             动态生成新 agent
│       ├── competitor-research-agent.md 竞品研究（kickoff 阶段 1 用）
│       ├── design-agent.md              AI 自主 UI 设计（默认，HTML+Tailwind 产出）
│       └── design-pencil-agent.md       Pencil MCP 设计（.pen 源文件产出）
├── docs/                         ← 参考文档（不需拷贝）
│   ├── architecture.md              架构详解
│   ├── project-templates/           项目可选模板
│   │   ├── requirements.md            需求圣经模板（kickoff 会填）
│   │   └── UX-checklist.md            UX 清单
│   └── hooks-example/               可选 pre-commit hook
│       ├── settings-example.json
│       ├── check-commit-safety.sh
│       └── verify-deliverables.sh
├── README.md                     ← 英文（默认）
├── README_zh.md                  ← 你在看
├── LICENSE / CHANGELOG / CONTRIBUTING
```

只需要拷贝 `.claude/`。其它都是可选参考。

---

## 依赖：按需自动安装

kit 根据**项目目标平台**自动检测 + 安装所需工具，无需手动操作。

### Kickoff 阶段必装：Web 自动化（所有项目都要）
- **Node.js + Playwright MCP**（kickoff wizard 自测 + 任何 Web 项目都要）
- 自动：`claude mcp add playwright -s user -- npx -y @playwright/mcp@latest`
- 预装：`npx playwright install chromium`（~150MB）

### 按目标平台装（kickoff 产出需求圣经后自动触发）

| 目标平台 | 自动装工具 | 需要用户手动的 |
|---------|-----------|---------------|
| **Web** | Playwright MCP | — |
| **Windows 桌面** | WinAppDriver（winget）+ Appium + appium-windows-driver | — |
| **Android** | Maestro（推荐）/ Appium + uiautomator2 | Android Studio（引导链接）|
| **iOS**（Mac）| Xcode CLI + Appium + xcuitest + Maestro | Xcode 完整版（App Store）|
| **Flutter** | — | Flutter SDK（brew / 官网）|
| **Electron** | Playwright | — |
| **Tauri** | Rust toolchain（rustup）| — |

看 `.claude/playbooks/platform-setup.md` 完整流程。

**前提**：装了 Node.js（npx 可用）。没装的话 Claude 会引导你去 [nodejs.org](https://nodejs.org)。

### 手动安装（高级用户）

```bash
# 加 MCP
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest

# 预装浏览器
npx -y playwright install chromium
```

或手动编辑 `~/.claude.json` / 项目 `.mcp.json`：
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

参考 [@playwright/mcp 官方](https://github.com/microsoft/playwright-mcp)。

---

## 可选：项目增强

如果你想让项目更严谨，可以拷贝这些：

```bash
# 需求圣经模板（kickoff-agent 会按此填）
cp docs/project-templates/requirements.md <项目>/docs/requirements.md

# UX 清单（ux-critic 按此打钩）
cp docs/project-templates/UX-checklist.md <项目>/docs/UX-checklist.md

# pre-commit hook（lint/type/test 不过不让 commit）
cp docs/hooks-example/settings-example.json <项目>/.claude/settings.json
cp docs/hooks-example/*.sh <项目>/scripts/
chmod +x <项目>/scripts/*.sh
```

不拷贝也能用，只是少了一层保障。

---

## 分发给其他人

### 公开分享（GitHub）
```bash
cd claude-code-archon
git init && git add . && git commit -m "init"
gh repo create claude-code-archon --public --source=. --push
```

别人这样用：
```bash
git clone https://github.com/<你>/claude-code-archon.git
cp -r claude-code-archon/.claude ~/.claude
# 或拖到项目 .claude/
```

### 私仓（团队内）
```bash
gh repo create <org>/claude-kit --private --source=. --push
```

### 压缩包
```bash
tar -czf claude-kit.tar.gz .claude docs README.md LICENSE
# 发给同事
```

### 改造为团队专属版
Fork 本仓库，改 `.claude/CLAUDE.md` 加入公司品牌/规范/内部 agent，团队内分发你的 fork。

---

## 更新

```bash
# 拉最新
cd claude-code-archon
git pull

# 合并到已部署位置（覆盖 agent 定义，但保留你的 user-profile.md）
cp -rn .claude/agents/* ~/.claude/agents/
cp .claude/CLAUDE.md ~/.claude/CLAUDE.md
# user-profile.md 不覆盖（除非你想重置画像）
```

---

## 自定义扩展

### 加自己的 stack agent
参考 `react-dev-agent.md` 写法。保存到 `~/.claude/agents/<stack>-dev-agent.md` 或 `<项目>/.claude/agents/`。

### 加团队特有的铁律
编辑 `~/.claude/CLAUDE.md` 或项目 `CLAUDE.md` 里加。

### 删掉你不需要的 agent
直接从 `.claude/agents/` 删文件。例如你永远不做前端，可以删 `ui-critic.md` / `ux-critic.md`。

---

## FAQ

**Q: 为什么不用 slash command？**
A: 对小白不友好。用户该能说"我想做个 X"就开始，不用学命令。CLAUDE.md 里的"对话路由"规则让 Claude 自动识别意图。

**Q: 为什么没有安装脚本？**
A: 你问过我了。拷贝文件夹足够简单，脚本反而是心智负担。

**Q: 我没装 Playwright MCP 能用吗？**
A: 能，但 ui-critic / ux-critic / qa-agent 退化为"只能读已有截图"，无法自己生成证据。强烈建议装。

**Q: 我项目已经有 CLAUDE.md 了怎么办？**
A: 合并。把本 kit 的对话路由 + 九条铁律追加到你的 CLAUDE.md，把 agents/ 合并过来即可。

**Q: 我是专家/已有一套工作流，这对我有用吗？**
A: 可以只拿你需要的。比如只拷贝 `kickoff-agent.md` + `ui-critic.md` + `ux-critic.md`，其它自己有。kit 是菜单不是套餐。

**Q: 这和 /metaskill / /metamemory / /metabot 怎么配合？**
A: 互补。agent-creator 内部用 /metaskill 生成新 agent；反馈存储可用 /metamemory；分布式 bot 任务用 /metabot。

---

## License

MIT — 见 [LICENSE](LICENSE)

贡献见 [CONTRIBUTING.md](CONTRIBUTING.md)，版本历史见 [CHANGELOG.md](CHANGELOG.md)，架构详解见 [docs/architecture.md](docs/architecture.md)。
