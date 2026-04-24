# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added (Platform Setup Playbook — 按目标平台自动装工具链)
- 新增 `.claude/playbooks/platform-setup.md`：覆盖 Web / Windows / macOS / Linux / Android / iOS / Flutter / Electron / Tauri 九个平台
- kickoff 阶段 4 产出需求圣经后**自动触发**（读"主要平台"字段分支执行）
- **Windows 桌面**：自动 `winget install Microsoft.WinAppDriver` + Appium + appium-windows-driver
- **Android**：自动装 Maestro（推荐，YAML E2E）+ 引导用户装 Android Studio
- **iOS**：自动 xcode-select --install + Appium + xcuitest（仅 Mac），非 Mac 时告知限制
- **Flutter SDK / Xcode 完整版 / Android Studio** 这些大包无法无人值守，playbook 按画像措辞引导用户装，并等待"装好了"信号
- **Rust**（Tauri 用）：自动 rustup 脚本
- 装完后自动更新 `.claude/settings.json` 的 `permissions.allow` 加入新工具白名单
- CLAUDE.md 对话路由加"加个 Android 端/桌面版"意图 → 触发 platform-setup
- CLAUDE.md playbook 类任务列表加入 platform-setup
- README 依赖章节重写，列出九平台矩阵

### Added (自动安装 Playwright MCP)
- kickoff playbook 新增 **阶段 0.5：前置依赖检查**
- 检测 Playwright MCP 未装 → 自动 `claude mcp add playwright -s user -- npx -y @playwright/mcp@latest --headless`（headless 默认：AI 自测不弹浏览器打扰用户）
- 后台 `npx playwright install chromium` 预装 150MB 浏览器
- 检查 Node.js 可用性，没装则按画像引导用户去 nodejs.org
- 装完提示用户重启 Claude Code 让 MCP 生效，新会话自动从阶段 1 续上（不重新走画像）
- Windows 兼容：`claude.cmd` / `npx.cmd` fallback
- README 重写依赖章节，强调"自动安装"是默认路径

### Fixed (wizard 关键 bug + 信息重复 + 无自测)
- **CSS 选择器 bug 修复**：之前用 `input[type=radio]:checked + label`，但模板里 radio 大部分是 `<label><input></label>` 嵌套结构（不是 sibling），选择器失效 → 用户点了没视觉反馈。改用 `:has()` 选择器兼容两种 DOM + JS 兜底给老浏览器加 `.chosen` 类
- **信息重复收集**：生成 wizard 前必须读 `~/.claude/user-profile.md`，画像已知的信息（技术栈、规模、约束等）不再问或只做预填确认。playbook 新增"信息去重铁律"章节
- **AI 写完不自测**：playbook 新增 2.2.5 阶段"必做：自测生成的 HTML"，要求主 agent 用 Playwright MCP 跑完整冒烟测试（点每个 radio、checkbox、chip、图片放大、翻页、提交、验证 JSON 生成）才能交给用户
- **CLAUDE.md 第 2 条铁律加强**：UI 改动必须"实际跑起来 + 点一遍关键控件"，而不仅仅是截图

### Fixed (wizard UX 两个问题)
- **文案 UI 不一致**：开放式字段（技术栈、不想用什么、特殊约束）之前文案说"直接填"但 UI 是 radio 按钮，用户困惑。改成**文本框为主 + quick-pick chips 辅助**（点击 chip 把文字 append 到输入框，支持多个）
- **竞品图看不清**：所有 `<img>` 加 `zoomable` class，HTML 模板内置全局 lightbox（CSS + vanilla JS，零依赖）。点击任意竞品截图全屏放大（92vw/vh），点背景 / ×按钮 / Esc 键关闭
- playbook 新增 "UX 铁律：文案和 UI 必须一致" 章节，列清楚哪种字段配哪种 UI，给 AI 生成 HTML 时参考

### Changed (server.py 启动后自动开浏览器)
- kickoff 阶段 2 的 server.py 内嵌 `webbrowser.open()` + 后台线程，启动后自动打开用户默认浏览器访问 wizard.html
- 用户不用手动复制 URL 粘贴到浏览器
- playbook 里主 agent 措辞也从"打开 <URL>"改为"已经帮你在浏览器打开，我在这儿等你"
- 极端环境（headless/WSL）fallback：失败时打印警告，让用户手动开

### Fixed (解决"说完稍等就停"的失败模式)
- **新增 `competitor-research-agent` subagent**：kickoff 阶段 1 竞品研究改为派这个 subagent（原来是主 agent 自己做，容易 "Cogitated 2min 后停止什么都没做"）
- 用户在 `/agents` 面板能看到 subagent 跑进度
- kickoff playbook 阶段 1 改为"派 Task(competitor-research-agent)"
- 阶段 2 生成 wizard 也加"立即行动"约束
- **CLAUDE.md 新增"反模式：禁止说完稍等就停"章节**：说"我去做 X"后必须立即跟工具调用，不能期待下一个 turn 继续

### Changed (画像识别改为聊天式 — 像认识新朋友)
- **kickoff 阶段 0 重写**：从"选 A/B/C/D 问卷式"改为**自然对话聊天式**
- 新流程：Round 1 问称呼 → Round 2 问职业 → 根据职业分支（程序员追问前/后/全栈 + 技术栈；非技术追问"写过代码吗"；学生追问专业；老板追问方向+技术背景）→ Round 4 确认画像
- **记住称呼**：后续所有对话用用户告诉的称呼（"小李"/"Jim"），不用"用户"/"你"
- `user-profile.md` 顶部新增"基本信息"章节（称呼、职业），置于最前
- `CLAUDE.md` 第 3 条补充"先用称呼打招呼"规则
- 第 7 条铁律明确"用称呼，不用'用户'/'你'"

### Changed (需求收集体验升级 — 从命令行问答改为网页向导)
- **Kickoff playbook 全面重做**：命令行里一次抛 10+ 个问题体验极差，改为**一站式网页 wizard**
- 新流程：对话里一个字母问画像 → 静默做竞品研究 → 生成 `docs/kickoff/wizard.html`（4 步向导 + 进度条 + 可翻页）→ 启动 `docs/kickoff/server.py`（Python 本地 HTTP）→ 用户浏览器填完提交 → JSON 落地 `docs/kickoff/answers.json` → AI 读 JSON 产出需求圣经
- wizard 含：需求 5 问（按画像措辞）+ 布局/视觉选择（配竞品截图）+ 功能多选（含 AI 推荐的隐藏需求）+ A/B 追问 + 自由补充
- Fallback：若本地服务器没起来，wizard 自动切换到"复制 JSON 粘贴给 Claude"模式
- playbook 内嵌完整 HTML 模板 + Python server 脚本，AI 按项目实际内容填充

### Fixed (关键架构修复 — playbook vs subagent)
- **把 kickoff 从 subagent 改为 playbook**：Claude Code 的 subagent 是独立一次性 session，无法中途等用户回答。kickoff 需要多轮用户对话（5 问、HTML 选择、A/B 追问），错误地做成 subagent 会导致子 agent 直接生成"请回答 3 个问题"后结束，用户看不到问题也没法回答
- 新增 `.claude/playbooks/kickoff.md`（主 agent 自己按剧本执行）
- 删除 `.claude/agents/kickoff-agent.md`
- `.claude/CLAUDE.md` 新增"Playbook 任务 vs Subagent 任务"区分说明
- 意图识别表里 kickoff 行动从"派 subagent"改为"主 agent 自己按 playbook 执行"

### Changed (重大重构 — 零命令体验)
- **取消 slash command 依赖**：不再需要 `/kickoff`。CLAUDE.md 新增"对话路由"规则，Claude 从用户自然语言自动识别意图并派对应 agent
- **取消安装脚本**：删除 install.sh / install.ps1 / init-project.sh / init-project.ps1。用户直接拷贝 `.claude/` 文件夹即可
- **目录结构扁平化**：
  - agents 从 `agents/presets/{universal,stacks}/` 扁平到 `.claude/agents/`
  - Orchestrator 系统提示合并进 `.claude/CLAUDE.md`
  - templates/ 拆分到 `.claude/`（CLAUDE.md、user-profile.md）和 `docs/project-templates/`（requirements.md、UX-checklist.md）
  - hooks 从 `templates/scripts-example/` 移到 `docs/hooks-example/`
- **Agent description 改为意图触发式**：每个 agent 的 description 写明"用户说什么时调用"，Claude 能从自然语言识别

### Removed
- `install.sh` / `install.ps1`
- `init-project.sh` / `init-project.ps1`
- `commands/kickoff.md`（slash command，不再需要）
- `agents/orchestrator-system-prompt.md`（合并进 CLAUDE.md）
- `agents/presets/` 分层结构
- `templates/` 目录（内容重组到 `.claude/` 和 `docs/`）


## [0.1.0] - 2026-04-23

### Added

**核心架构**
- Orchestrator（主 agent）系统提示词：只调度不执行
- 10 个 universal 子 agent 预设（完整硬边界）：
  - `kickoff-agent` — 需求挖掘（六阶段协议，含用户画像识别）
  - `dev-agent` — 写代码 + 单元测试
  - `qa-agent` — 独立 E2E
  - `ui-critic` — 视觉评审（独立上下文）
  - `ux-critic` — 交互评审（独立上下文）
  - `code-reviewer` — 代码审查（独立上下文）
  - `integration-agent` — 打包 + smoke + 部署
  - `delivery-agent` — 交付包生成（按画像四档）
  - `triage-agent` — 反馈分类分发
  - `agent-creator` — 元 agent，动态生成新 agent
- Stack 专用 agent 示例：`react-dev-agent`

**用户画像系统（知己知彼）**
- 全局 `user-profile.md`，四维度画像
- kickoff-agent 阶段 0 识别
- 所有对用户沟通按画像适配

**项目模板**
- `CLAUDE.md`：七条铁律 + UX 清单 + 架构规则 + 端点参与
- `requirements.md`：需求圣经模板
- `UX-checklist.md`：六大类 50+ 项
- `settings.json`：pre-commit hook 配置
- `scripts-example/`：hook 脚本参考

**Slash Commands**
- `/kickoff` — 启动新项目需求挖掘

**分发工具**
- `install.sh` / `install.ps1` — 全局安装
- `init-project.sh` / `init-project.ps1` — 项目初始化
- LICENSE (MIT)
- CONTRIBUTING.md

**文档**
- README：快速上手、三层使用、分发方式
- docs/architecture.md：10 节架构详解
