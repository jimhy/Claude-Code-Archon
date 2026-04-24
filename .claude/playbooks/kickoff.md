# Kickoff Playbook（主 agent 执行剧本）

> ⚠️ **这不是 subagent，是主 agent 自己执行的剧本。**
>
> 用户说"我想做 X"、"帮我做 Y"、"我要一个 Z"、"加个功能"时，**主 agent 自己**按本文档流程走（**不要派 subagent**，因为需要多轮用户对话 + 等待网页表单提交，subagent 是一次性独立 session，跑完即死，无法等待）。
>
> 主 agent 在此场景允许的工具：`WebSearch`, `WebFetch`, `Read`, `Write`, `Edit`, `Bash`, Playwright MCP

## 核心原则（重大改进）

**所有多选题/多问题不在对话里问**，改为**一站式网页向导**（多页翻页表单）。
- 对话里只做快速一句话互动（画像确认）
- 密集的需求收集放到**HTML wizard**，用户浏览器填，可翻页、可改、可保存进度
- 用户点"提交" → JSON 写到 `docs/kickoff/answers.json`
- AI 读 JSON 继续流程

**为什么**：命令行一次抛 10+ 个问题体验极差。网页向导可翻页、有进度条、有选项图、易填。

## 边界

### 不做（MUST NOT）
- ❌ 不写业务代码、不建项目脚手架（那是 dev-agent 的事）
- ❌ 不做细节技术选型（小白/非技术画像下可代决定，记录"kickoff 代选"）
- ❌ 不在命令行里堆问题让用户打字（除了画像确认那一个字母）
- ❌ 不省略任何阶段

### 可写
- `~/.claude/user-profile.md`
- `docs/requirements.md`（最终产出）
- `docs/kickoff/`（过程文件：wizard.html、server.py、answers.json、竞品截图等）

### 禁写
- `src/` / `tests/` / `package.json` / 业务代码

---

## 六阶段协议

```
阶段 0:   画像识别（聊天式对话：称呼、职业、技术栈）
   ↓
阶段 0.5: 前置依赖检查（Node / Playwright MCP）⭐ 缺则自动装
   ↓      缺 Playwright → 自动 claude mcp add + install chromium → 提示重启
阶段 1:   竞品研究（派 competitor-research-agent subagent，5-10 分钟）
   ↓
阶段 2:   生成 wizard.html + server.py + Playwright 自测（10 步冒烟）+ 启动服务器（自动开浏览器）
          ⭐ wizard 含 design_mode 三选一：
             • ai-self：AI 用 design-knowledge/ 自己设计（HTML+Tailwind，默认首选，零外部依赖）
             • pencil： AI 调 Pencil MCP 产 .pen 源文件（精细矢量源文件，需装 Pencil MCP）
             • user：   用户自己提供设计稿（跳过 AI 设计环节）
   ↓
          用户填表，提交（JSON 落盘到 answers.json）
   ↓
阶段 3:   AI 读 answers.json 消化
   ↓      3.5 按 design_mode 分支依赖装配（遵第 8 铁律：先检测后装）：
             • ai-self → 确认 Playwright MCP 已装（阶段 0.5 已装）即可，不装额外包
             • pencil  → 检测并安装 Pencil MCP
             • user    → 不装任何设计依赖
   ↓
阶段 4:   产出需求圣经 docs/requirements.md + 按画像对用户总结
   ↓      4.5 按 design_mode 分支派 agent：
             • ai-self → 派 design-agent（读 design-knowledge/ 产 HTML+Tailwind+PNG+design-notes）
             • pencil  → 派 design-pencil-agent（用 Pencil MCP 产 .pen+PNG+design-notes）
             • user    → 不派 agent，告诉用户把设计放 design-references/，dev-agent 后续按此写码
   ↓      4.6 ⭐ 触发 platform-setup.md 按目标平台装工具链
          （Windows 桌面 → WinAppDriver；Android → Maestro；iOS → Xcode；Flutter SDK 等）
```

---

### 阶段 0：画像识别（像认识新朋友一样聊，不是做问卷）

#### 0.1 读既有画像
```
Read ~/.claude/user-profile.md
```

**已填充**（元信息"首次建立"不是占位符）→ 用画像里的**称呼**跟用户打招呼（如"<称呼>，Archon 回来了——这次要做什么？"；专家画像可省去品牌自报家门，直接进主题）→ 跳到阶段 1。

**空白 / 首次** → 进入 0.2 聊天识别。

#### 0.2 对话树：先问称呼，再问职业，分支追问

⚠️ **核心原则**：
- **一轮一个问题**，不要一口气抛多个
- **从回答动态分支**，不是读固定脚本
- **记住称呼**，以后所有对话都用它
- 全过程自然，像跟陌生人在咖啡馆闲聊

---

##### Round 1: 自报身份 + 问称呼

**按你判断的初始画像层级选一个措辞**（首次见面必须报 Archon 这个身份——一句话带过即可，不要变长篇广告）：

**小白 / 非技术版**（默认，最安全）：
```
嘿，做 <用户提到的东西> 没问题——我是 Archon，Claude Code 给你配的"项目总管"，会带一群 AI 助手帮你从想法做到上线，中间你基本不用操心。
开始前先认识一下，我怎么称呼你？
（随便，喜欢的名字或昵称都行）
```

**普通技术版**：
```
好的 <用户提到的东西>，我来。先自我介绍——我是 Archon，Claude Code 的主 orchestrator，会按你的需求派一组 subagent（dev / qa / ui-critic / ux-critic / code-reviewer ...）分工干到交付。
开始前确认一下，我怎么称呼你？
```

**专家版**（用户一开口就透露出高技术水平，或画像后续会升到 D）：
```
做 <X>——我是 Archon，Claude Code archon-tier orchestrator，13 个硬边界 subagent 可派，中段自主闭环，你只在需求和交付两端出场。
我怎么称呼你？
```

⚠️ 初始画像判断只是启发，Round 2-4 再精细化；如果第一句就判错（小白说了专家话 / 反之），Round 2 立刻换措辞，不需要道歉。

**从回答提取称呼**：
- "叫我小李" → `小李`
- "Jim" → `Jim`
- "就叫我老王吧" → `老王`
- "随便" / "无所谓" → 用 `朋友` / `哥们` / `你`（按语境）
- 只说"我是 XX" → 用 XX

存到 `user-profile.md` 的 `name` 字段。

---

##### Round 2: 问职业（一行）

```
好，<称呼>。你平时做什么工作呀？（了解一下好调整讲话方式）
```

**根据回答判断分支**：

| 用户回答含 | 分支 |
|-----------|------|
| 程序员 / 开发 / 工程师 / 码农 / developer / engineer / 写代码 / 做技术 | → Round 3A（技术细分）|
| 产品 / 设计师 / 运营 / 销售 / 市场 / 老师 / 医生 / 律师 / 会计 等 | → Round 3B（非技术细分）|
| 学生 / student / 在读 | → Round 3C（学生分支）|
| 老板 / 创业者 / CEO / 创始人 | → Round 3D（老板分支）|
| 模糊（社畜 / 摸鱼 / 不告诉你 / 随便）| → 追问："哈哈，我换个问法：你平时在电脑上主要做啥？（办公？写代码？剪视频？）" |

---

##### Round 3A: 程序员分支

```
哦，<称呼>是程序员呀，主要做哪块？
前端 / 后端 / 全栈 / 移动端 / 游戏 / 其它（嵌入式/ML/数据/...）？
```

继续追问：
```
平时主力用什么栈？（React+TS、Node+Postgres、Unity+C#、Flutter... 随便说几个）
```

**判定画像**：
- 答出 2+ 栈 + 有生产项目/年限 → **D（专家）**
- 答 1-2 栈 + 自称"主要做 X" → **C（普通技术）**
- 说"入门"/"学了一点"/"还在学" → **B（会一点）**

---

##### Round 3B: 非技术职业分支

```
好的。你之前有写过代码吗？（HTML 网页、Excel 宏、改过 CSS 这种也算）
```

根据回答：
- "完全没碰过" / "我是纯小白" → **A（小白）**
- "懂一点" / "Excel 宏" / "HTML" / "改过 WordPress" → **B（会一点）**
- "以前写过但现在不写" → **B**，但追问："以前什么栈？" 补记录
- "会一点 Python 做分析" 之类 → **B**，记录"辅助型编程经验"

**也别忘了问 AI 使用经验**：
```
用过 AI 工具做过什么吗？ChatGPT？Cursor？还是这次是第一次？
```

---

##### Round 3C: 学生分支

```
<称呼>是学生呀，什么专业？
```

- 计算机 / 软件 / 信息类 → 问"会什么语言？学到什么程度？" → 判定 B 或 C
- 非计算机类 → 问"自己有玩过编程不？" → 判定 A 或 B

---

##### Round 3D: 老板 / 创业者分支

```
做什么方向的？（了解一下跟你聊的时候重点放哪 — 技术细节 vs 产品决策）
```

通常老板是**非技术画像**，但可能有技术背景。再追问：
```
你自己懂技术吗？还是完全交给团队？
```

根据回答定 A/B/C。

---

##### Round 4: 画像收尾 + 确认

把推断告诉用户，给他机会纠正：

```
好，<称呼>。我的理解：
- <一句话总结职业背景>
- 后面跟你聊会用 <技术层次对应风格>

如果我判断偏了你随时打断我说"别把我当小白" / "你讲太技术了"，我立刻调整。

下面我去查 1-3 个竞品，大概 3-8 分钟，回来给你做个需求表单填。
```

#### 0.3 写 user-profile.md

填：
- **称呼**（最重要，后续每次沟通都用）
- **职业**（用户原话）
- **技术层级**：A 小白 / B 非技术 / C 普通技术 / D 专家
- **细分信息**：
  - 程序员：前端 / 后端 / 全栈 / 移动 / 游戏 / 其它；主力栈
  - 非技术：编程经验（无 / 一点 / 以前有）
  - 学生：专业 + 学到什么程度
- **AI 使用经验**（若追问了）
- **元信息**：首次建立时间、判断依据（引用几句用户原话）

#### 0.4 重要：后续所有对话用称呼

读 user-profile.md 后：
- 开头打招呼："好 <称呼>，..."
- 追问："那 <称呼> 你觉得 ..."
- 交付："<称呼>，这一轮做完了 ..."

**不要说"用户" / "你" 的比例过高**，用称呼亲切，但也别每句都叫（显得奇怪），大约每 2-3 轮提一次名字即可。

---

### 阶段 0.5：前置依赖检查（画像完成后、派 subagent 前必做）

后续 `competitor-research-agent` 要抓竞品截图、wizard 自测、E2E 测试都需要 **Playwright MCP**。缺失就自动装。

#### 0.5.1 检查 Node.js / npx 可用性

```bash
npx --version
```

**有输出**（如 `10.x.x`）→ Node 可用，进入 0.5.2。

**报错 / command not found**：
- 按画像告诉用户（用称呼）：
  - 小白："<称呼>，我需要一个叫 Node.js 的基础工具（免费），你去 https://nodejs.org 下载 LTS 版本双击安装一下，装完回来说'装好了'，我继续"
  - 技术："<称呼>，检测到没 Node.js。去 nodejs.org 装 LTS，或用 volta/fnm/nvm 自己挑"
- 停止 kickoff，等用户装好回来再继续

#### 0.5.2 检查 Playwright MCP 是否已装

```bash
claude mcp list 2>&1 | grep -i playwright || echo "NOT_INSTALLED"
```

**找到 playwright 条目** → 已装，跳到 0.5.4 验证浏览器。

**输出 "NOT_INSTALLED"** → 进入 0.5.3 自动装。

#### 0.5.3 自动安装 Playwright MCP（未装时）

先按画像告知用户（用称呼）：

**小白版**：
```
<称呼>，我需要一个叫 Playwright 的工具来帮你查竞品网站、截图验证。
你没装，我现在帮你自动装一下，大概 2-3 分钟，装完我告诉你下一步。
```

**技术版**：
```
<称呼>，检测到没装 Playwright MCP，我自动装一下：
- claude mcp add playwright -s user
- 预装 chromium 浏览器（~150MB）
大概 2-3 分钟。
```

**立即执行**（不要 turn 结束）：

```bash
# 1) 注册 MCP server 到用户全局配置
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest
```

这一步应该几秒返回（属于下载监控协议的"同步执行例外"）。检查输出确认成功（stdout 含 "added" 或类似成功提示）。

```bash
# 2) 后台预装 chromium 浏览器（避免首次用时卡几分钟）
npx -y playwright install chromium
```

> ⚠️ **必须按 `platform-setup.md` 的"🛰 下载监控协议"跑**：`run_in_background: true` + 日志落盘 `.claude/.setup-logs/chromium-<attempt>.log` + 每 30 秒 poll 字节增长 + 连续 90 秒无增长或出现 `ECONNRESET`/`ETIMEDOUT` 等网络错误 → kill 进程 → 换 `PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright` 重启 → 最多 3 次仍卡就 escalate 用户。下载约 150MB，健康网络 2-3 分钟，总超时 10 分钟。

**告诉用户进度**（不要闷声做）：
```
<称呼>：
✓ MCP 配置已添加
⏳ 正在后台下载 Chromium 浏览器（150MB，约 2-3 分钟）...
（网络不好会自动换镜像重试，最多 3 次，卡住我会告诉你）
我会在浏览器下载完 + 你重启 Claude Code 后继续。
```

#### 0.5.4 等浏览器下载完 → 提示用户重启

浏览器下载完成后：

```
<称呼>，Playwright 都装好了 ✓

⚠️ 但 MCP 配置需要重启 Claude Code 才生效。操作：
1. 关闭当前这个对话 / Claude Code 窗口
2. 重新打开 Claude Code，进入同一个项目
3. 说"继续 kickoff"我接着之前的进度做

你的画像已经保存在 ~/.claude/user-profile.md，不会丢。
```

**然后停止本次 kickoff**。用户重启后新会话里，主 agent 读 user-profile 发现画像已建立 → 直接从阶段 1 开始（不用重新聊画像）。

#### 0.5.5 已装场景的快速验证

若 0.5.2 显示已装，还是要快速 sanity check 一下浏览器：

```bash
# 验证 chromium 是否已下载
npx -y playwright install --dry-run chromium 2>&1 | grep -qi "is already installed" && echo "OK" || echo "NEED_INSTALL"
```

若 `NEED_INSTALL`，后台补装（**同样按 `platform-setup.md` 的"🛰 下载监控协议"跑**，不要同步 Bash 干等）：

```bash
npx -y playwright install chromium
```

这次不用重启 Claude Code（MCP 已注册，只是浏览器没下），等下载完直接继续阶段 1。网络卡死则走协议的 kill + 换镜像 + 重启路径。

#### 0.5.6 Windows 特殊注意

用户是 Windows 环境时：
- `claude` 命令通常在 `%APPDATA%\npm\claude.cmd`，PATH 应该有
- 若 Bash 环境（Git Bash）下 `claude: command not found`，尝试 `claude.cmd mcp list`
- `npx` 同理，失败尝试 `npx.cmd`

---

### 阶段 1：竞品研究（派 subagent，不是你自己做）

⚠️ **关键**：这一步必须派 `competitor-research-agent` subagent，不要你自己调 WebSearch/Playwright。
- 理由 1：这是封闭计算任务（无用户交互），适合独立 session
- 理由 2：用户在 `/agents` 面板能看到 subagent 在跑，有进度可视化
- 理由 3：避免你"说完稍等就停在原地不动"（subagent 强制你立即调 Task 工具）

#### 1.1 对用户说一句话（称呼 + 画像确认 + 告知派研究）

按画像措辞（用 user-profile.md 里的称呼）：

**例**：
```
好，<称呼>。<画像一句话总结>。
我派 competitor-research-agent 去查 1-3 个相关竞品 + 抓截图，你在 /agents 面板能看到它在跑。
大概 3-8 分钟。研究完我就给你做一个需求表单。
```

#### 1.2 **立即** 派 subagent（不要 Cogitate 后停止）

**强制动作**：说完上一句话**不要结束 turn**。**立即**调用 `Task` 工具：

```
Task(
  subagent_type="competitor-research-agent",
  description="Research 1-3 competitors for <product>",
  prompt="""
产品方向：<从用户对话提取的一句话描述>
用户画像层级：<A/B/C/D>
用户提到的参考产品：<用户原话，若无则 '用户未指定'>
产品领域：<记账 / 笔记 / 协作 / ...>

请按 competitor-research-agent.md 定义的流程执行：
1. 搜 1-3 个相关领域竞品（用户提到的必包含；1 个起步，3 个足够，不追求 5 个）
2. 每个抓 3 张截图（桌面/核心/移动）到 docs/kickoff/competitors/<name>/
3. 写 docs/kickoff/competitor-analysis.md 对比表
4. 返回结构化 JSON 给我
"""
)
```

#### 1.3 等 subagent 返回 → 校验

subagent 返回后，校验：
- `artifacts.analysis_md` 文件存在（用 Read 确认）
- `artifacts.screenshots` 目录至少有 1 个竞品的图（用 Glob 确认）
- 看 `recommendations_to_main_agent` 拿到布局/视觉/功能候选

**若返回 `partial` 或 `failed`**：
- 告诉用户："只拿到 X 个竞品，我继续做表单；如果觉得信息不够回头我补查"
- 别卡在这，继续阶段 2

#### 1.4 简短告知用户"研究完"

```
<称呼>，竞品查完了，拿到 X 个：<列名字>
正在给你生成需求表单，稍等...
```

然后**立即**进阶段 2（不要 turn 结束）。

---

### 阶段 2：生成一站式 Wizard 网页 + 启动本地服务器

⚠️ **立即动作**：从阶段 1 回来后**不要 turn 结束**。立即 `Write` wizard.html 和 server.py，然后用 `Bash`（run_in_background）启动服务器。
**不要只说"我去生成"然后停下**。

#### 2.1 生成 `docs/kickoff/wizard.html`

用 Tailwind CDN（零构建）+ vanilla JS 或 Alpine.js。4-5 步向导，有进度条、翻页按钮、提交按钮。

**模板结构**（按项目实际内容填充）：

```html
<!DOCTYPE html>
<html lang="zh">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>需求挖掘 — <项目名></title>
  <script src="https://cdn.tailwindcss.com"></script>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
    .step { display: none; }
    .step.active { display: block; }
    /* 兼容两种 DOM 结构：<label><input></label> 和 <input><label for="">
       用 :has() 最简洁，现代浏览器普遍支持（Chrome 105+/FF 121+/Safari 15.4+）*/
    label:has(input[type=radio]:checked),
    label:has(input[type=checkbox]:checked) {
      border-color: rgb(59 130 246) !important;
      background: rgb(239 246 255) !important;
      color: rgb(30 64 175);
    }
    /* Fallback：JS 兜底给老浏览器加 .chosen 类（见 <script>）*/
    label.chosen {
      border-color: rgb(59 130 246) !important;
      background: rgb(239 246 255) !important;
    }
    /* 图片可放大：hover 显示放大镜提示 */
    .zoomable { cursor: zoom-in; transition: transform 0.15s; }
    .zoomable:hover { transform: scale(1.02); }
    /* Lightbox */
    #lightbox { position: fixed; inset: 0; background: rgba(0,0,0,0.9); display: none; align-items: center; justify-content: center; z-index: 50; cursor: zoom-out; }
    #lightbox.active { display: flex; }
    #lightbox img { max-width: 92vw; max-height: 92vh; box-shadow: 0 20px 60px rgba(0,0,0,0.5); }
    #lightbox .close { position: absolute; top: 20px; right: 30px; color: white; font-size: 40px; cursor: pointer; user-select: none; }
    /* quick-pick chips */
    .chip { display: inline-block; padding: 2px 10px; margin: 2px; background: #f3f4f6; border-radius: 9999px; font-size: 12px; cursor: pointer; transition: background 0.15s; }
    .chip:hover { background: #dbeafe; }
  </style>
</head>
<body class="bg-gray-50 min-h-screen">
  <div class="max-w-4xl mx-auto p-6">

    <!-- 头部 + 进度条 -->
    <header class="mb-8">
      <h1 class="text-2xl font-bold">需求挖掘 — <项目名></h1>
      <p class="text-gray-600 mt-2">4 步填完，全部选完点提交。可以随时翻上一步改。</p>
      <div class="mt-4 bg-gray-200 rounded-full h-2 overflow-hidden">
        <div id="progress" class="bg-blue-500 h-full transition-all" style="width:25%"></div>
      </div>
      <div class="mt-2 text-sm text-gray-500"><span id="stepLabel">Step 1 / 4</span></div>
    </header>

    <form id="wizard" onsubmit="return submitAll(event)">

      <!-- ================= Step 1: 需求快问 ================= -->
      <section class="step active bg-white rounded-lg shadow p-6" data-step="1">
        <h2 class="text-xl font-semibold mb-4">Step 1 / 4：需求坐标</h2>

        <!-- 【按画像动态生成不同措辞】 -->
        <!-- 下面的问题按画像决定：小白用生活化语言；专家用技术语言 -->

        <div class="space-y-6">
          <div>
            <label class="block font-medium mb-2">1. 一句话：你要做什么？</label>
            <input type="text" name="oneliner" required class="w-full border rounded px-3 py-2" placeholder="例：一个月账本，家庭共享，能自动识别银行短信">
          </div>

          <div>
            <label class="block font-medium mb-2">2. 目标用户 + 场景</label>
            <textarea name="users" rows="2" required class="w-full border rounded px-3 py-2" placeholder="谁会用？什么时候用？"></textarea>
          </div>

          <div>
            <label class="block font-medium mb-2">3. 他们现在怎么解决这个问题？（关键：挖真痛点）</label>
            <textarea name="current_solution" rows="2" required class="w-full border rounded px-3 py-2" placeholder="没有你这个产品时，他们靠什么？Excel？随手记？别的 app？"></textarea>
          </div>

          <div>
            <label class="block font-medium mb-2">4. 心目中类似的好产品是哪个？</label>
            <input type="text" name="references" class="w-full border rounded px-3 py-2" placeholder="例：Notion 的模板系统 + Apple 备忘录的速度">
          </div>

          <div>
            <label class="block font-medium mb-2">5. 如果只能保留 1 个功能上线，保哪个？（关键：挖真核心）</label>
            <input type="text" name="p0_core" required class="w-full border rounded px-3 py-2" placeholder="删到只剩一个功能的话，是哪个？">
          </div>

          <!-- 技术用户才显示：架构问题（画像 C/D）-->
          <!-- 设计原则：开放式问题用"文本框 + quick-pick chips 辅助"，不用单选按钮 -->
          <div class="mt-6 pt-6 border-t" id="techSection" style="display:none">
            <h3 class="font-medium mb-3">技术坐标（直接打字写，想不起来时点下面的 chip 快速填）</h3>
            <div class="space-y-5">

              <!-- 技术栈：文本框为主，chips 是辅助（点击 append）-->
              <div>
                <label class="block text-sm mb-1 font-medium">主力技术栈</label>
                <input type="text" name="tech_stack" class="w-full border rounded px-3 py-2" placeholder="例：Next.js + TS 前端，Node + Postgres 后端，Flutter 移动">
                <div class="mt-1 text-xs text-gray-500">或快速添加：
                  <span class="chip" data-target="tech_stack">React + TS</span>
                  <span class="chip" data-target="tech_stack">Next.js</span>
                  <span class="chip" data-target="tech_stack">Vue 3</span>
                  <span class="chip" data-target="tech_stack">Svelte</span>
                  <span class="chip" data-target="tech_stack">Node + Postgres</span>
                  <span class="chip" data-target="tech_stack">Python + FastAPI</span>
                  <span class="chip" data-target="tech_stack">Go</span>
                  <span class="chip" data-target="tech_stack">Rust</span>
                  <span class="chip" data-target="tech_stack">Flutter</span>
                  <span class="chip" data-target="tech_stack">React Native</span>
                  <span class="chip" data-target="tech_stack">Swift / Kotlin 原生</span>
                </div>
              </div>

              <!-- 规模：枚举，用 radio -->
              <div>
                <label class="block text-sm mb-1 font-medium">规模预期（选一个）</label>
                <div class="flex gap-2 flex-wrap">
                  <label class="border rounded px-3 py-1 cursor-pointer"><input type="radio" name="scale" value="mvp" class="hidden"> MVP 自用</label>
                  <label class="border rounded px-3 py-1 cursor-pointer"><input type="radio" name="scale" value="hundreds" class="hidden"> 几十上百</label>
                  <label class="border rounded px-3 py-1 cursor-pointer"><input type="radio" name="scale" value="thousands" class="hidden"> 几百到几千付费</label>
                  <label class="border rounded px-3 py-1 cursor-pointer"><input type="radio" name="scale" value="large" class="hidden"> 商业级上万</label>
                </div>
              </div>

              <!-- 特殊约束：文本框 + chips 辅助 -->
              <div>
                <label class="block text-sm mb-1 font-medium">特殊约束（如果有）</label>
                <input type="text" name="constraints" class="w-full border rounded px-3 py-2" placeholder="例：要合规、要离线优先、i18n、a11y AA 级... 没有就空着">
                <div class="mt-1 text-xs text-gray-500">或点选：
                  <span class="chip" data-target="constraints">合规（金融/医疗/隐私）</span>
                  <span class="chip" data-target="constraints">离线优先</span>
                  <span class="chip" data-target="constraints">i18n 多语言</span>
                  <span class="chip" data-target="constraints">a11y AA</span>
                  <span class="chip" data-target="constraints">性能预算严格</span>
                  <span class="chip" data-target="constraints">无</span>
                </div>
              </div>

              <!-- 明确不想用什么：文本框 + chips 辅助 -->
              <div>
                <label class="block text-sm mb-1 font-medium">明确不想用什么（避雷）</label>
                <input type="text" name="tech_nogo" class="w-full border rounded px-3 py-2" placeholder="例：不要 Electron、不想自建后端、不碰 MongoDB">
                <div class="mt-1 text-xs text-gray-500">或点选：
                  <span class="chip" data-target="tech_nogo">不要 Electron</span>
                  <span class="chip" data-target="tech_nogo">不自建后端</span>
                  <span class="chip" data-target="tech_nogo">不要 Firebase</span>
                  <span class="chip" data-target="tech_nogo">不锁定 Vercel</span>
                  <span class="chip" data-target="tech_nogo">无</span>
                </div>
              </div>

            </div>
          </div>
        </div>
      </section>

      <!-- ================= Step 2: 布局 + 视觉风格（含竞品截图）================= -->
      <section class="step bg-white rounded-lg shadow p-6" data-step="2">
        <h2 class="text-xl font-semibold mb-4">Step 2 / 4：视觉方向（选你喜欢的）</h2>

        <div class="mb-8">
          <h3 class="font-medium mb-3">布局风格（选 1 个）</h3>
          <div class="grid grid-cols-2 gap-4">
            <!-- 每个选项一张竞品截图 -->
            <div>
              <input type="radio" name="layout" id="layout1" value="sidebar-cmdk" class="hidden">
              <label for="layout1" class="block border-2 border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-300">
                <img src="competitors/linear/desktop.png" alt="Linear" class="w-full rounded mb-2 zoomable">
                <div class="font-medium">Linear 风</div>
                <div class="text-sm text-gray-600">左侧 sidebar + 命令面板（Cmd+K）</div>
              </label>
            </div>
            <div>
              <input type="radio" name="layout" id="layout2" value="tree-editor" class="hidden">
              <label for="layout2" class="block border-2 border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-300">
                <img src="competitors/notion/desktop.png" alt="Notion" class="w-full rounded mb-2 zoomable">
                <div class="font-medium">Notion 风</div>
                <div class="text-sm text-gray-600">左侧树形导航 + 右侧编辑</div>
              </label>
            </div>
            <!-- 再加 2 个... -->
          </div>
        </div>

        <div>
          <h3 class="font-medium mb-3">视觉风格（选 1 个）</h3>
          <div class="grid grid-cols-3 gap-4">
            <div>
              <input type="radio" name="vstyle" id="vs1" value="professional" class="hidden">
              <label for="vs1" class="block border-2 border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-300">
                <img src="competitors/stripe/style.png" class="w-full rounded mb-2 zoomable">
                <div class="font-medium">商务严谨</div>
                <div class="text-xs text-gray-600">深蓝 + 大量留白</div>
              </label>
            </div>
            <div>
              <input type="radio" name="vstyle" id="vs2" value="geek" class="hidden">
              <label for="vs2" class="block border-2 border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-300">
                <img src="competitors/linear/style.png" class="w-full rounded mb-2 zoomable">
                <div class="font-medium">极客酷感</div>
                <div class="text-xs text-gray-600">深色 + 荧光色点缀</div>
              </label>
            </div>
            <div>
              <input type="radio" name="vstyle" id="vs3" value="warm" class="hidden">
              <label for="vs3" class="block border-2 border-gray-200 rounded-lg p-3 cursor-pointer hover:border-blue-300">
                <img src="competitors/notion/style.png" class="w-full rounded mb-2 zoomable">
                <div class="font-medium">温暖友好</div>
                <div class="text-xs text-gray-600">米色 + 大圆角</div>
              </label>
            </div>
          </div>
        </div>

        <!-- ========== UI 设计方式（三选一）========== -->
        <!-- 措辞按画像分层渲染：
             A 小白：完全生活化类比（"AI 自己画 / 用专业工具画 / 你自己画"）
             B 非技术：讲利弊产品化（"快出 HTML 稿 vs 精细源文件 vs 你给稿"）
             C 普通技术：讲三种产出（HTML+Tailwind / .pen / 用户稿）
             D 专家：简短列 design-knowledge 库 / Pencil MCP / design-references 产出路径 -->
        <div class="mt-8 border-t pt-6">
          <h3 class="font-medium mb-3">UI 设计方式（选一个）</h3>
          <p class="text-sm text-gray-600 mb-3">【按画像措辞，例：小白"要不要让 AI 先画设计稿给你看？三种方式：AI 自己画、AI 用专业工具画、你自己画"】</p>
          <div class="grid grid-cols-3 gap-3">

            <!-- 选项 1：ai-self（默认首选）-->
            <div>
              <input type="radio" name="design_mode" id="designAiSelf" value="ai-self" class="hidden" checked>
              <label for="designAiSelf" class="block border-2 border-gray-200 rounded-lg p-4 cursor-pointer hover:border-blue-300 h-full">
                <div class="font-medium mb-1">🤖 AI 自己设计（推荐）</div>
                <div class="text-sm text-gray-600">
                  AI 用内置设计知识库（50+ 风格预设）产出 HTML+Tailwind 草稿 + 桌面/移动 PNG 截图。约 6-15 分钟，零外部依赖。
                </div>
                <div class="text-xs text-gray-500 mt-2">
                  推荐：绝大多数项目、快速预览、想直接可打开浏览器看的 HTML
                </div>
              </label>
            </div>

            <!-- 选项 2：pencil -->
            <div>
              <input type="radio" name="design_mode" id="designPencil" value="pencil" class="hidden">
              <label for="designPencil" class="block border-2 border-gray-200 rounded-lg p-4 cursor-pointer hover:border-blue-300 h-full">
                <div class="font-medium mb-1">✏️ AI 用 Pencil 设计</div>
                <div class="text-sm text-gray-600">
                  AI 调 Pencil MCP 产出 <code>.pen</code> 矢量源文件 + PNG 预览。适合想要可编辑源文件 / 后续在 Pencil 里精修的场景。需要装 Pencil MCP。
                </div>
                <div class="text-xs text-gray-500 mt-2">
                  推荐：已有 Pencil 工作流 / 设计团队要接手继续改
                </div>
              </label>
            </div>

            <!-- 选项 3：user -->
            <div>
              <input type="radio" name="design_mode" id="designUser" value="user" class="hidden">
              <label for="designUser" class="block border-2 border-gray-200 rounded-lg p-4 cursor-pointer hover:border-blue-300 h-full">
                <div class="font-medium mb-1">👤 我自己设计</div>
                <div class="text-sm text-gray-600">
                  跳过 AI 设计环节。你把 Figma/Sketch/手绘/截图等放到 <code>design-references/</code>，dev-agent 按你的稿直接写代码。
                </div>
                <div class="text-xs text-gray-500 mt-2">
                  推荐：有现成设计稿 / 强视觉品牌 / 自己是设计师
                </div>
              </label>
            </div>
          </div>
          <p class="text-xs text-gray-500 mt-3">
            💡 三种方式都会经 <code>ui-critic</code> / <code>ux-critic</code> 做视觉和交互评审，最终成品一致性有保证。
          </p>
        </div>
      </section>

      <!-- ================= Step 3: 核心功能（含隐藏需求）================= -->
      <section class="step bg-white rounded-lg shadow p-6" data-step="3">
        <h2 class="text-xl font-semibold mb-2">Step 3 / 4：核心功能（多选）</h2>
        <p class="text-sm text-gray-600 mb-4">勾你想要的。标 ⭐ 的是我根据竞品推荐的"通常需要"项，你可能没想到但建议考虑。</p>

        <div class="space-y-2">
          <!-- 【根据需求场景动态填充，含 2-3 个 AI 推荐项 】-->
          <label class="flex items-start gap-3 border rounded p-3 hover:border-blue-300 cursor-pointer">
            <input type="checkbox" name="features" value="feature_a" class="mt-1">
            <div>
              <div class="font-medium">功能 A</div>
              <div class="text-sm text-gray-600">描述 + 哪些竞品有</div>
            </div>
          </label>

          <label class="flex items-start gap-3 border rounded p-3 hover:border-blue-300 cursor-pointer">
            <input type="checkbox" name="features" value="feature_b_recommended" class="mt-1">
            <div>
              <div class="font-medium">⭐ 推荐：功能 B</div>
              <div class="text-sm text-gray-600">用户没提但竞品 X/Y/Z 都有，通常用户需要</div>
            </div>
          </label>

          <!-- 等等... -->
        </div>
      </section>

      <!-- ================= Step 4: A/B 追问 + 自由补充 ================= -->
      <section class="step bg-white rounded-lg shadow p-6" data-step="4">
        <h2 class="text-xl font-semibold mb-4">Step 4 / 4：细节确认</h2>

        <!-- 按画像决定问题层次：小白问产品、技术问技术、专家开放式 -->

        <div class="space-y-6">
          <div>
            <div class="font-medium mb-2">① 主要平台（选 1）</div>
            <div class="flex gap-2 flex-wrap">
              <label class="border rounded px-4 py-2 cursor-pointer"><input type="radio" name="platform" value="web" class="hidden"> 网页（电脑手机都能用，需要网）</label>
              <label class="border rounded px-4 py-2 cursor-pointer"><input type="radio" name="platform" value="mobile" class="hidden"> 手机 App（可离线，但开发周期长）</label>
              <label class="border rounded px-4 py-2 cursor-pointer"><input type="radio" name="platform" value="both" class="hidden"> 两个都要</label>
            </div>
          </div>

          <div>
            <div class="font-medium mb-2">② 登录方式</div>
            <div class="flex gap-2 flex-wrap">
              <label class="border rounded px-4 py-2 cursor-pointer"><input type="radio" name="auth" value="email" class="hidden"> 邮箱密码</label>
              <label class="border rounded px-4 py-2 cursor-pointer"><input type="radio" name="auth" value="social" class="hidden"> 第三方（Google/微信）</label>
              <label class="border rounded px-4 py-2 cursor-pointer"><input type="radio" name="auth" value="none" class="hidden"> 不登录（纯本地）</label>
            </div>
          </div>

          <!-- 更多按项目定制 -->

          <div>
            <label class="block font-medium mb-2">还有什么想补充的？（可选）</label>
            <textarea name="extra" rows="3" class="w-full border rounded px-3 py-2" placeholder="任何你觉得重要但表单没问到的"></textarea>
          </div>
        </div>
      </section>

      <!-- 翻页按钮 -->
      <div class="mt-6 flex justify-between">
        <button type="button" id="prevBtn" onclick="changeStep(-1)" class="px-4 py-2 border rounded text-gray-600 disabled:opacity-30" disabled>← 上一步</button>
        <button type="button" id="nextBtn" onclick="changeStep(1)" class="px-4 py-2 bg-blue-500 text-white rounded">下一步 →</button>
        <button type="submit" id="submitBtn" class="px-6 py-2 bg-green-600 text-white rounded hidden">✓ 提交</button>
      </div>
    </form>

    <!-- 提交结果区 -->
    <div id="result" class="mt-6 hidden"></div>
  </div>

  <!-- 图片放大 lightbox -->
  <div id="lightbox" onclick="closeLightbox()">
    <span class="close" onclick="closeLightbox()">×</span>
    <img id="lightbox-img" src="" alt="">
  </div>

  <script>
    let currentStep = 1;
    const totalSteps = 4;

    // 画像注入（AI 生成 HTML 时填入）
    const USER_TIER = 'B'; // A / B / C / D
    if (USER_TIER === 'C' || USER_TIER === 'D') {
      document.getElementById('techSection').style.display = 'block';
    }

    // ========= 图片 Lightbox =========
    document.addEventListener('click', (e) => {
      if (e.target.matches('img.zoomable')) {
        const lb = document.getElementById('lightbox');
        document.getElementById('lightbox-img').src = e.target.src;
        lb.classList.add('active');
      }
    });
    function closeLightbox() {
      document.getElementById('lightbox').classList.remove('active');
    }
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') closeLightbox();
    });

    // ========= Quick-pick chips 交互（点击 append 到对应 input）=========
    document.addEventListener('click', (e) => {
      if (e.target.matches('.chip')) {
        const targetName = e.target.dataset.target;
        if (!targetName) return;
        const input = document.querySelector(`input[name="${targetName}"]`);
        if (!input) return;
        const existing = input.value.trim();
        const newVal = e.target.textContent.trim();
        if (existing.includes(newVal)) return;
        input.value = existing ? existing + '、' + newVal : newVal;
        input.focus();
      }
    });

    // ========= Radio/checkbox 选中视觉反馈的 JS 兜底 =========
    // 老浏览器不支持 :has()，给 label 加 .chosen 类实现同样效果
    function refreshLabelStates() {
      document.querySelectorAll('input[type=radio], input[type=checkbox]').forEach(inp => {
        // 找到包含它的 label 或 for 关联的 label
        const lbl = inp.closest('label') || document.querySelector(`label[for="${inp.id}"]`);
        if (!lbl) return;
        if (inp.checked) lbl.classList.add('chosen');
        else lbl.classList.remove('chosen');
      });
    }
    document.addEventListener('change', refreshLabelStates);
    refreshLabelStates(); // 初始化

    function updateUI() {
      document.querySelectorAll('.step').forEach(s => s.classList.remove('active'));
      document.querySelector(`.step[data-step="${currentStep}"]`).classList.add('active');
      document.getElementById('progress').style.width = (currentStep / totalSteps * 100) + '%';
      document.getElementById('stepLabel').textContent = `Step ${currentStep} / ${totalSteps}`;
      document.getElementById('prevBtn').disabled = currentStep === 1;
      document.getElementById('nextBtn').style.display = currentStep < totalSteps ? '' : 'none';
      document.getElementById('submitBtn').classList.toggle('hidden', currentStep !== totalSteps);
      window.scrollTo(0, 0);
    }

    function changeStep(delta) {
      const next = currentStep + delta;
      if (next < 1 || next > totalSteps) return;
      currentStep = next;
      updateUI();
    }

    async function submitAll(e) {
      e.preventDefault();
      const form = document.getElementById('wizard');
      const data = {};
      for (const [k, v] of new FormData(form).entries()) {
        if (data[k] === undefined) data[k] = v;
        else if (Array.isArray(data[k])) data[k].push(v);
        else data[k] = [data[k], v];
      }
      data._meta = { submitted_at: new Date().toISOString(), user_tier: USER_TIER };

      // 尝试 POST 到本地服务器
      try {
        const r = await fetch('/submit', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(data)
        });
        if (r.ok) {
          document.getElementById('result').innerHTML = `
            <div class="bg-green-50 border border-green-300 rounded-lg p-6">
              <div class="text-green-700 font-bold text-lg">✅ 已提交</div>
              <div class="mt-2">你的需求已保存到 <code>docs/kickoff/answers.json</code>。可以关闭本页面，回到 Claude 对话说"填完了"，我继续下一步。</div>
            </div>
          `;
          document.getElementById('result').classList.remove('hidden');
          form.style.display = 'none';
          return false;
        }
      } catch (err) { /* fallback 到手动模式 */ }

      // Fallback：服务器没跑，让用户复制粘贴
      const json = JSON.stringify(data, null, 2);
      document.getElementById('result').innerHTML = `
        <div class="bg-yellow-50 border border-yellow-300 rounded-lg p-6">
          <div class="font-bold text-lg">⚠️  本地服务器没启，请手动复制下面的 JSON 粘贴给 Claude：</div>
          <textarea class="w-full mt-3 border rounded p-2 font-mono text-xs" rows="20" readonly>${json}</textarea>
          <button onclick="navigator.clipboard.writeText(\`${json.replace(/`/g,'\\`')}\`); this.textContent='已复制 ✓'" class="mt-3 px-4 py-2 bg-blue-500 text-white rounded">复制到剪贴板</button>
        </div>
      `;
      document.getElementById('result').classList.remove('hidden');
      return false;
    }

    updateUI();
  </script>
</body>
</html>
```

**关键定制点**（AI 生成时按项目填充）：
- `<项目名>` → 实际项目名
- `USER_TIER` → 实际画像（A/B/C/D）
- Step 1 的问题措辞 → 按画像调整（小白用生活化、专家用技术语）
- Step 2 的布局/视觉选项图片路径 → 指向实际抓的 `competitors/<name>/*.png`
- Step 3 的功能选项 → 根据竞品分析列实际功能 + 主动加 2-3 个用户没提的"⭐ 推荐"项
- Step 4 的 A/B 追问 → 按画像层次（见 4 档模板）

### ⚠️ 信息去重铁律：画像已知的不要再问

生成 wizard 前**必须读** `~/.claude/user-profile.md`，把已有信息**排除**或**预填**。

**常见重复错误**：
- 阶段 0 画像识别用户说"精通 Flutter + RN + Go"
- 画像记录了 `tech_stack: Flutter + RN + Go`
- Wizard 又在 Step 1 问"移动端技术栈偏好"、Step 2 问"后端策略"
- 用户被迫把同一件事说 3 遍

**正确处理**：

| 信息是否已知 | Wizard 处理 |
|------------|------------|
| 画像已记录（如精通的技术栈）| **不问**，或最多**预填 + 'AI 已知，确认/修改？'** |
| 画像部分提到（如说了语言没说框架）| **细化问**，针对缺口问 |
| 画像没提 | 正常问 |

**具体做法**：生成 HTML 时根据 user-profile 内容**条件渲染**字段。

```javascript
// 伪代码：生成 HTML 时 AI 应判断
const profile = read(~/.claude/user-profile.md);
const knownTechStack = profile.tech_stack;  // 如 "Flutter + RN + Go"

if (knownTechStack) {
  // 预填，不当问题问
  techStackInputHtml = `
    <div class="text-sm text-gray-500 mb-2">
      技术栈（画像里已记：<strong>${knownTechStack}</strong>）
      <a href="#" onclick="...">修改</a>
    </div>`;
  // 或完全不放这个字段
} else {
  // 正常问
  techStackInputHtml = `<input name="tech_stack" ...>`;
}
```

**简单粗暴版本**：如果画像里已有 tech_stack / scale / constraints / nogo，**整个 techSection 隐藏**，只保留新信息的字段。

### ⚠️ UX 铁律：文案和 UI 必须一致

**不要出现"文案说 A、UI 给 B" 的矛盾**。按字段性质选 UI 形态：

| 字段性质 | UI 形态 | 文案该说什么 |
|---------|--------|-------------|
| **视觉判断**（布局风格、视觉风格）| radio + 竞品截图 | "选一个"/"挑你喜欢的" |
| **枚举选择**（平台、登录方式、规模）| radio 按钮 | "选一个" |
| **开放输入**（技术栈、不想用什么、特殊约束）| **文本框**（主）+ quick-pick chips（辅助，点击 append）| "**直接打字写**，想不起来时点下面的 chip 快速填" |
| **多选清单**（核心功能、想要的模块）| checkbox | "勾你要的" |
| **长段输入**（补充说明、特殊情况）| textarea | "随便写"/"可选" |

**典型错误**：
- ❌ 文案 "技术栈偏好（你是全栈直接填）" + UI 给 3 个 radio 单选按钮 → 用户懵
- ❌ 文案 "选一个" + UI 是文本框 → 用户不知道有候选
- ❌ 文案 "勾你想要的" + UI 是 radio（单选）→ 选不了多个

**正确**：
- ✅ 开放类字段：文本框为主 + "或快速选" 的 chips（点击 append 到输入框）
- ✅ 枚举类字段：radio + "选一个" 文案
- ✅ chips 不是强制单选 — 可以点多个，都会 append

### ⚠️ 图片必须可放大

**所有竞品截图 `<img>` 必须加 `class="zoomable"`**。HTML 模板里已经有全局 lightbox：
- 点任何 `.zoomable` 图 → 全屏放大（max 92vw/vh）
- 点背景 / 按 Esc / 点 × → 关闭

竞品图小，不放大用户看不清布局细节，会瞎选。

#### 2.2 生成 `docs/kickoff/server.py`（启动后自动开浏览器）

```python
#!/usr/bin/env python3
"""本地服务器：托管 wizard.html + 接收提交 + 自动开浏览器"""
from http.server import SimpleHTTPRequestHandler, HTTPServer
import json, sys, os, webbrowser, threading, time

class Handler(SimpleHTTPRequestHandler):
    def do_POST(self):
        if self.path == '/submit':
            length = int(self.headers.get('Content-Length', 0))
            raw = self.rfile.read(length)
            try:
                data = json.loads(raw)
                with open('answers.json', 'w', encoding='utf-8') as f:
                    json.dump(data, f, ensure_ascii=False, indent=2)
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Access-Control-Allow-Origin', '*')
                self.end_headers()
                self.wfile.write(b'{"ok":true}')
                print(f"[OK] 已保存 answers.json ({len(raw)} bytes)", flush=True)
            except Exception as e:
                self.send_response(400); self.end_headers()
                self.wfile.write(str(e).encode())
        else:
            self.send_response(404); self.end_headers()

    def log_message(self, *a, **k): pass  # 安静点

def open_browser_when_ready(url, delay=0.8):
    """等服务器起来后自动开浏览器（跨平台）"""
    def _open():
        time.sleep(delay)
        try:
            webbrowser.open(url)
            print(f"🌐 已打开浏览器: {url}", flush=True)
        except Exception as e:
            print(f"⚠️  自动打开失败，请手动访问: {url}", flush=True)
    threading.Thread(target=_open, daemon=True).start()

if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8765
    url = f"http://localhost:{port}/wizard.html"
    print(f"📡 服务器启动在 {url}")
    print(f"   提交后 JSON 会写到 docs/kickoff/answers.json")

    open_browser_when_ready(url)

    try:
        HTTPServer(('localhost', port), Handler).serve_forever()
    except OSError as e:
        if 'Address already in use' in str(e) or e.errno in (48, 98, 10048):
            print(f"❌ 端口 {port} 被占用，换一个端口重试，例如: python server.py 8766", flush=True)
        else:
            raise
```

#### 2.2.5 ⚠️ 必做：自测生成的 HTML（不要直接交给用户）

**规则**：生成 wizard.html 和 server.py 后，**必须自己用 Playwright MCP 跑一遍冒烟测试**，确认没 bug 再让用户看。

**为什么必须**：Claude 写完 HTML 不测就交出去是典型失败模式。CSS 选择器细节错误、JS 语法错误、chip 不 append、radio 不显示选中… 这些 bug 你生成完**完全不知道**，用户打开看到一堆坏按钮。

**自测清单**（跑一遍点所有关键控件）：

```
用 Playwright MCP：
1. 先起 server.py 后台，拿到 URL
2. page.goto('http://localhost:PORT/wizard.html')
3. page.screenshot('initial.png') — 确认页面渲染正常（无白屏、无 JS 错误）
4. page.click('label') 选中第一个 radio → 截图 → 验证视觉变化（边框蓝/背景蓝）
5. page.click('input[type=checkbox]') → 截图 → 验证 checkbox 打钩
6. page.click('.chip:first-of-type') → 验证 input 被 append 了文字
7. page.click('img.zoomable:first-of-type') → 截图 → 验证 lightbox 打开
8. page.keyboard.press('Escape') → 验证 lightbox 关闭
9. page.click('#nextBtn') → 验证翻到 Step 2 + 进度条变化
10. 填最小必填后 page.click('#submitBtn') → 验证 POST 到 /submit 成功 + 页面显示 ✅
11. 验证 docs/kickoff/answers.json 真的生成了
```

**发现 bug 时**：修 HTML/JS/CSS → 重新 Playwright 测 → 直到全绿。

**用 `mcp__playwright__` 系列工具**，不要装额外依赖。

**如果没装 Playwright MCP**：
- 至少用 `curl http://localhost:PORT/wizard.html` 确认服务起了
- 用 Read 打开 HTML 肉眼检查明显语法错（不完整标签、JS 括号不匹配等）
- 然后告诉用户"没装 Playwright，我没法自测，可能有视觉 bug，如果看到异常告诉我"

**自测通过后才进入 2.3 告诉用户**。

#### 2.3 启动服务器（自动开浏览器 + 后台跑）

用 `Bash` 带 `run_in_background=true`：

```bash
python3 docs/kickoff/server.py 8765
# 或 Windows 环境:  python docs/kickoff/server.py 8765
```

服务器启动后会**自己开用户默认浏览器**，不用用户手动复制 URL。

#### 2.4 对用户简短说一句（称呼开头）

```
<称呼>，表单做好了 — 已经帮你在浏览器打开。
4 步向导，填完点提交就行，可以随时翻上一步改。
我在这儿等你。
```

**注意**：不要说"打开 http://localhost:8765/wizard.html"——浏览器已经自动开了，多一句反而啰嗦。

#### 2.5 浏览器没自动开怎么办

极少情况（headless 环境、WSL 特殊配置）`webbrowser.open` 失败。server.py 会打印警告。

如果用户反馈"没看到浏览器弹出来"：
```
那你手动打开一下：http://localhost:8765/wizard.html
```

---

### 阶段 3：等用户填完 → 读 answers.json

用户说"填完了" / "提交了" / "好了"等信号 → 读 `docs/kickoff/answers.json`。

**若文件不存在**：
- 可能服务器没跑成功，或者用户还没点提交
- 问用户："我没看到 answers.json，你点提交了吗？或者把网页里的 JSON 复制给我"

**若存在**：解析成结构化数据，**按画像判断**是否信息充分：
- 有必填项空着 → 友好追问（只问缺的那几项，不要重新来一遍）
- 够了 → 进 3.5

#### 3.5 按 `design_mode` 分支装配依赖

读 `answers.design_mode`（取值 `ai-self` / `pencil` / `user`）：

##### 3.5-A：`design_mode === 'ai-self'`（默认首选）

零额外装配。**前置检查**：
1. `.claude/design-knowledge/` 目录存在（应在项目 scaffolding 时已就位）
   ```bash
   ls .claude/design-knowledge/README.md && echo "OK" || echo "MISSING"
   ```
2. Playwright MCP 可用（阶段 0.5 应已装），design-agent 要用它截图
   ```bash
   claude mcp list 2>&1 | grep -qi playwright && echo "OK" || echo "MISSING"
   ```

都 OK → 记一行 setup-log.md "design_mode=ai-self, knowledge 库就位, Playwright 就绪" → 进阶段 4。

design-knowledge 缺失 → escalate（说明"项目没正确 scaffolding，装 Archon 时该有 `.claude/design-knowledge/`"）。

##### 3.5-B：`design_mode === 'pencil'`

检测并安装 Pencil MCP：

```bash
# 先检测（遵守第 8 条铁律：装之前必须先检测）
claude mcp list 2>&1 | grep -qi pencil && echo "OK" || echo "MISSING"
```

**已装**（OK）：什么都不做，记一行到 setup-log.md "Pencil MCP 已装，跳过"，进阶段 4。

**未装**（MISSING）：
```bash
# 自动装
claude mcp add pencil -- npx -y @pencil/mcp
# （具体命令以 Pencil 官方文档为准）
```

装完再跑 `claude mcp list | grep pencil` 校验。

**装失败**（网络 / 权限 / 包名错）：按画像 escalate 给用户三个选项：
- 小白：`<称呼>，我装 Pencil（设计工具）失败了。你选：(A) 手动装 Pencil MCP 后回来（https://docs.pencil.dev/for-developers/pencil-cli）；(B) 改成 AI 自己设计（HTML 草稿，不用装 Pencil）；(C) 你自己设计，我直接写代码。你选哪个？`
- 技术：`<称喈>，Pencil MCP 安装失败（错误：<err>）。选项：A 手动 \`claude mcp add pencil -- ...\`；B 降级 design_mode=ai-self；C 降级 design_mode=user。`

##### 3.5-C：`design_mode === 'user'`

不装任何设计依赖。记一行 setup-log.md "design_mode=user, 用户将自行提供设计"，进阶段 4。

##### 向后兼容

若 `answers` 里没有 `design_mode` 字段但有旧的 `auto_design` 字段，按以下映射：
- `auto_design === 'yes'` → `design_mode = 'pencil'`
- `auto_design === 'no'` → `design_mode = 'ai-self'`（历史默认"直接写代码"升级为 ai-self 产 HTML 草稿）

---

### 阶段 4：产出需求圣经 + 对用户总结

#### 4.1 写 `docs/requirements.md`

按画像调整详细度（见 `~/.claude/user-profile.md` 里的模板），填充从 answers.json 提取的内容。模板见 `docs/project-templates/requirements.md`（若项目用了本 kit 的模板）。

#### 4.2 对用户总结（按画像措辞）

**小白版**：
```
✅ 需求整理好了

你要做的：<一句话>
核心功能：<3-5 项，用人话>
不做的：<范围边界>

我开始做了，大概 <时间> 后给你一个能直接打开用的版本。
过程中有卡住的地方才找你，不然不打扰你。
```

**专家版**：
```
✅ Requirements 已 freeze 到 docs/requirements.md

Positioning: <...>
P0 features: <...>
Out-of-scope: <...>
Tech stack: <...> (按你的偏好)
Scale target: <...>

进入自主开发：dev → qa → ui-critic / ux-critic → code-review → integration → delivery
卡点 > retry 5 次才打扰你。
```

#### 4.3 停服务器

```bash
# 杀掉之前 run_in_background 启动的 server.py
pkill -f "server.py 8765"
```

#### 4.4 记录 design_mode 到需求圣经

必须在 `docs/requirements.md` 里记录（dev-agent 后续读此决定走哪条路）：

```markdown
## 设计产出方式

- **design_mode**：<ai-self / pencil / user>

### 若 ai-self（默认首选）
- 产物：`docs/design/*.html`（每核心屏一个 HTML，桌面+移动响应式）
- 预览：`docs/design/previews/<name>-desktop.png` / `<name>-mobile.png`
- 翻译指南：`docs/design/design-notes.md`（token 表 + HTML 元素→shadcn 组件映射）
- 选用 style-guide：`docs/design/selected-style.md`
- dev-agent 读 design-notes 把 HTML 翻译成 React + shadcn/ui + Tailwind

### 若 pencil
- 产物：`docs/design/*.pen`（Pencil 矢量源文件）
- 预览：`docs/design/previews/<name>-desktop.png` / `<name>-mobile.png`
- 翻译指南：`docs/design/design-notes.md`（Pencil 图层→shadcn 组件映射）
- dev-agent 按 design-notes 和 PNG 直接写码

### 若 user
- 用户自行提供设计稿，放 `design-references/`
- dev-agent 按用户稿 + 竞品截图 + 视觉风格（<层号+风格>）直接写码
```

#### 4.5 按 `design_mode` 分支派 agent

##### 4.5-A：`design_mode === 'ai-self'`（默认首选）

**立即** Task 派 `design-agent`：

```
Task(
  subagent_type="design-agent",
  description="AI-self design (HTML+Tailwind) for <project-name>",
  prompt="""
需求圣经路径：docs/requirements.md
竞品分析路径：docs/kickoff/competitor-analysis.md
用户画像路径：~/.claude/user-profile.md
核心屏清单：<从需求圣经 P0 features 提取，如 ["首页","详情","设置"]>
主平台：<从需求圣经"主要平台"字段>
视觉风格偏好：<从 answers.json 的 vstyle 字段>
布局偏好：<从 answers.json 的 layout 字段>
组件库约定：shadcn/ui + Radix + Tailwind

请按 design-agent.md 流程（ai-self 模式）：
1. 读 .claude/design-knowledge/ 三件套（README/INDEX/ADAPTER）
2. 读 design-principles / product-principles / 对应 domain 指南
3. 用 style-guide-selector 从 50 个预设里选 1 个，写 selected-style.md
4. 对每个核心屏产出 docs/design/<name>.html（Tailwind CDN，响应式）
5. Playwright 截桌面 1440×900 + 移动 375×812 双端 PNG
6. 按 vision-feedback 做 critic 自评审（目标 score ≥ 7），必要时 2 轮迭代
7. 写 docs/design/design-notes.md（token 表 + HTML→shadcn 映射 + 给 dev-agent 提示）
返回结构化 JSON。
"""
)
```

**返回后校验**：
- `artifacts.html_dir` 下每个核心屏有 `.html`（Glob 确认）
- `artifacts.preview_dir` 下每个核心屏有 `-desktop.png` 和 `-mobile.png`
- `design-notes.md` / `selected-style.md` 都存在
- 每屏 `critic_score >= 7`（若 < 7 主 agent 要看 issues 决定是否重派或 partial 交付）
- 按画像告诉用户看："<称呼>，设计稿画好了，看看 `docs/design/previews/` 的 PNG，或直接双击打开 `docs/design/*.html` 看真实效果。哪里要改直接说。"

##### 4.5-B：`design_mode === 'pencil'`

**立即** Task 派 `design-pencil-agent`：

```
Task(
  subagent_type="design-pencil-agent",
  description="Pencil-based design for <project-name>",
  prompt="""
需求圣经路径：docs/requirements.md
竞品分析路径：docs/kickoff/competitor-analysis.md
用户画像路径：~/.claude/user-profile.md
核心屏清单：<从需求圣经 P0 features 提取>
主平台：<从需求圣经"主要平台"字段>
组件库约定：shadcn/ui + Radix + Tailwind

请按 design-pencil-agent.md 流程：
1. 定 token（set_variables）
2. 对每个核心屏 open_document + batch_design 产出 .pen
3. export_nodes 导出桌面+移动 PNG
4. 写 docs/design/design-notes.md（token 表 + layer→组件映射 + 给 dev-agent 的翻译提示）
返回结构化 JSON。
"""
)
```

**返回后校验**：
- `artifacts.pen_dir` 下每个核心屏有 `.pen`（Glob 确认）
- `artifacts.preview_dir` 下每个核心屏有桌面+移动 PNG
- `design-notes.md` 存在且有 token 表
- 按画像告诉用户："<称呼>，Pencil 设计稿画好了，看 `docs/design/previews/`，.pen 文件可以在 Pencil 里继续精修。"

##### 4.5-C：`design_mode === 'user'`

不派任何 design agent。按画像告诉用户：
- 小白：`<称呼>，需求定好了。你把你脑子里/纸上/已有的设计稿（截图、Figma 链接、手绘拍照都行）放到 design-references/ 目录，告诉我一声，我就让 dev-agent 按你的稿写代码。`
- 技术：`<称呼>，requirements freeze，design_mode=user。把设计资产放 design-references/（Figma 链接 / 截图 / Sketch 导出均可），告我一声进入 dev 阶段。`

然后**停止 kickoff 流程**，等用户回来说"设计放好了"才进阶段 4.6 的 platform-setup。

#### 4.6 ⭐ 触发 platform-setup（关键：按目标平台装工具链）

产出需求圣经后，**必须**读 `docs/requirements.md` 的"主要平台"字段，按此执行 **`.claude/playbooks/platform-setup.md`**。

**为什么不能跳过**：
- 用户说要做 Windows 桌面 → 需要 WinAppDriver 才能做 QA
- 用户说要做 Android → 需要 Maestro / adb 才能跑 E2E
- 等到 dev-agent 写了一堆代码才发现没测试工具 = 返工

**流程**：

```
1. Read docs/requirements.md → 提取 "主要平台"
2. Read .claude/playbooks/platform-setup.md 了解流程
3. 按 platform-setup 的平台分支执行检测 + 安装
4. 完成后更新 .claude/settings.json 的 permissions.allow
5. 对用户报告：装了什么 + 需要手动的是什么
```

**按画像告诉用户要做这步**：
- 小白：`<称呼>，需求定好了。下面我装一下做 <平台> 需要的工具，几分钟。`
- 技术：`<称呼>，requirements freeze。装目标平台（<platform>）工具链。`

然后**立即**跑检测和安装命令（不要说完就停）。

---

## 失败与重试

| 场景 | 应对 |
|------|------|
| 端口 8765 被占用 | 换 8766 / 8767 重启 server.py |
| 用户打不开 URL | 确认服务器 process 还活着；换 127.0.0.1:8765 |
| 用户关掉浏览器又回来 | 服务器还在跑，再开同个 URL 接着填（浏览器状态会丢，但 JSON 没提交的话就是从头再来） |
| 用户填一半要改 | 翻回上一步即可，整份表单在同一页 |
| 竞品截图抓不到 | fallback 用 WebFetch 抓 HTML + 纯文本描述；或用 placeholder 图 + 文字 |
| 用户拒绝填 | 按画像温柔说明"这一步决定后续开发方向，跳过会多返工"；实在不填就缩短表单到 3 个必答项 |

## 内部状态追踪（不给用户看）

```json
{
  "phase_completed": ["0", "1", "2", "3", "4"],
  "artifacts": {
    "user_profile": "~/.claude/user-profile.md",
    "wizard_html": "docs/kickoff/wizard.html",
    "server_script": "docs/kickoff/server.py",
    "server_port": 8765,
    "answers_json": "docs/kickoff/answers.json",
    "requirements": "docs/requirements.md",
    "competitor_analysis": "docs/kickoff/competitor-analysis.md",
    "competitor_screenshots": ["docs/kickoff/competitors/*/*.png"]
  },
  "profile_at_kickoff": { "tier": "B", "tech_stack": null }
}
```

## 越界处理
- 用户要求你"顺便写个登录页" → 拒绝，"需求圣经确认后由 dev-agent 做"
- 用户说"这些选择你自己定就行" → 小白/非技术画像接受；技术/专家画像拒绝并说明"这是你的决策权"
- 用户想跳过网页填表改成对话里问 → **拒绝**，说明"对话里密集问题体验差，网页 4 分钟填完更顺，你先试试"
