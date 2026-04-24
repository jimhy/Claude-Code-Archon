# Platform Setup Playbook（主 agent 执行剧本）

> ⚠️ **这是主 agent 自己按剧本执行**（可调 subagent 做封闭安装任务）。
>
> **何时触发**：
> - kickoff 阶段 4 产出需求圣经后（读"主要平台"字段）
> - 用户后期说"我要加 Android 端"/"改做桌面版" 等平台切换
> - dev-agent / qa-agent 派活前，检测到缺平台工具

## 职责

根据**目标平台**（从 `docs/requirements.md` 或用户明说提取）**检查 + 自动装**自动化/开发/测试所需的基础工具。用户画像决定措辞，但不影响是否装（该装就装）。

## 🚨 第 0 铁律：先检测，再安装（禁止重复下载/安装）

> **这条优先级最高，违反直接回退。** 对应 `.claude/CLAUDE.md` 八条铁律里的第 8 条。

每装一个工具前，**必须**先跑检测命令：

| 类型 | 检测命令（至少其一）|
|------|----------|
| 命令行工具（node/python/adb/maestro/appium/git/…）| `command -v X` / `which X` / `X --version` |
| Windows 包 | `winget list --id <Id>` / 路径 `ls "C:\\Program Files\\…"` |
| macOS 包 | `brew list <name>` / `ls /Applications/<name>.app` |
| Linux 包 | `dpkg -l <name>` / `apt list --installed 2>/dev/null \| grep <name>` |
| npm 全局 | `npm list -g --depth=0 \| grep <name>` |
| Python 包 | `pip show <name>` / `python -c "import <name>"` |
| MCP server | `claude mcp list \| grep -i <name>` |
| Appium driver | `appium driver list --installed \| grep -i <name>` |

**检测结果处理**：
- ✅ 已装 → 记录版本（`X --version`）→ **直接跳过**，写进 setup-log.md："已装 X=v1.2.3，跳过"
- ❌ 未装 → 才执行安装命令
- ⚠️ 版本过低 → 问用户是否升级（不要默默替换线上版本）

**绝对禁令**：
- ❌ 不许"保险起见再装一遍"
- ❌ 不许没检测就跑 `winget install` / `brew install` / `curl | bash`
- ❌ 不许因为"上次装失败"就再下载一次——先看本次检测结果，真未装才重试

## 边界

- ❌ 不装项目本身的业务依赖（`npm install` 那些是 dev-agent 的活）
- ❌ 不改业务代码
- ❌ 不跳过"需要用户参与的大安装"（Flutter SDK、Xcode、Android Studio）—— 明确告诉用户并等待
- ✅ 可以自动装的工具（winget / npm / brew / 脚本）直接装，不问用户，**但装之前必须先跑第 0 铁律的检测**

---

## 🛰 下载监控协议（防网络卡死）— 所有下载/安装必用

> **目的**：winget / brew / npm / curl | bash / pip / sdkmanager / playwright install chromium 这类动作会走网络。一旦镜像堵塞、DNS 超时、CDN 丢包，**进程会僵住不退出也无新输出**。不能同步 `Bash` 直接干等 10 分钟，那样主 agent 看不到任何信号。必须后台跑 + 周期 poll + 卡死判定 + 重启。
>
> **适用范围**：本 playbook 所有安装命令；kickoff 阶段 0.5 的 Playwright / chromium 下载；任何单次预期 > 30 秒的下载。快命令（`X --version`、检测）不适用。

### 协议三要素

**A. 启动方式**：必须用 `run_in_background: true` 启动 Bash，不要同步阻塞。把 stdout + stderr 都写到日志文件，方便主 agent 每次 poll 只读 tail：

```bash
# 示例模板
LOG=.claude/.setup-logs/<tool>-<attempt>.log
mkdir -p .claude/.setup-logs
(winget install --id Microsoft.WinAppDriver -e --silent) > "$LOG" 2>&1
echo "EXIT=$?" >> "$LOG"
```

（`curl | bash`、`npm i -g`、`playwright install chromium` 同样套这个壳。）

**B. Poll 策略**（主 agent 自己循环）：

| 参数 | 默认值 | 调整 |
|------|--------|------|
| Poll 间隔 | **30 秒** | 大包（chromium / Rust / Android SDK）用 45-60 秒 |
| 卡死判定 | 连续 **3 次** poll 日志**总字节数无增长** | 即 90 秒没新输出 |
| 总超时 | **预期时长 × 3**（最少 5 分钟，最多 15 分钟）| chromium ~170MB / 10 Mbps 预期 3 分钟 → 总超时 10 分钟 |
| 明确失败信号 | stderr 出现 `ECONNRESET` / `ETIMEDOUT` / `getaddrinfo` / `Could not resolve host` / `SSL` / `network is unreachable` | 立即判卡死，不等 3 次 poll |

poll 用 `Read` 读日志文件 tail（20 行），比对上一次的字节数。**不要用 sleep 循环**——用 `ScheduleWakeup(delaySeconds: 30)` 让自己回来，或用 `Monitor` 工具跟踪日志流。

**C. 卡死后动作**（按顺序）：

1. **Kill 卡死进程**：
   ```bash
   # 后台 Bash 返回的 shell_id 可直接 kill（Claude Code 内置能力）
   # 或 pkill 兜底：
   pkill -f "winget install"   # 或 curl / npm / playwright 对应关键字
   ```
2. **清残留**（如有）：删半成品目录、临时文件。`winget` 可能需要 `winget uninstall <Id>` 再装。
3. **换镜像/换源**后重启（见下表）。
4. **重启 attempt++**，最多 **3 次**。
5. 仍失败 → **escalate** 给用户，按 `.claude/CLAUDE.md` 卡点报告模板。

### 镜像/源 fallback 表

| 工具 | 默认 | 备选 1 | 备选 2 |
|------|------|--------|--------|
| `npm` | registry.npmjs.org | `npm config set registry https://registry.npmmirror.com` | `https://registry.npm.taobao.org`（旧）|
| `pip` | pypi.org | `pip install -i https://pypi.tuna.tsinghua.edu.cn/simple <pkg>` | `https://mirrors.aliyun.com/pypi/simple/` |
| `curl \| bash`（rustup / maestro / 各种 installer）| 官方 URL | 手动下 release 二进制放 PATH | 用 `cargo install` / `brew` 替代路径 |
| `winget` | MS store | 直接去 GitHub Releases 下 MSI/EXE | chocolatey: `choco install <name>` |
| `brew` | homebrew CDN | `HOMEBREW_BOTTLE_DOMAIN=https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles` | 手动下 bottle |
| `playwright install chromium` | playwright.azureedge.net | `PLAYWRIGHT_DOWNLOAD_HOST=https://npmmirror.com/mirrors/playwright` | 手动下 zip 解到 `%LOCALAPPDATA%/ms-playwright/` |
| `apt` / `apt-get` | 默认源 | 换 `/etc/apt/sources.list` 到国内镜像 | — |
| `gem` / `sdkmanager` / `cargo` | 官方 | 对应中国镜像（见各自文档）| — |

重启时**先 export 环境变量或 `--registry` 传参**再跑，确保走新源。

### 卡死判定伪代码

```
启动下载 → 拿到 shell_id / log 路径
prev_bytes = 0
stuck_count = 0
start = now()

loop:
  wait 30s （用 ScheduleWakeup，非 sleep）
  tail = Read(log, last 20 lines)
  cur_bytes = filesize(log)

  # 明确网络错误 → 立刻判卡死
  if tail 含 "ECONNRESET|ETIMEDOUT|getaddrinfo|unreachable|SSL":
    goto restart

  # 字节无增长
  if cur_bytes == prev_bytes:
    stuck_count += 1
    if stuck_count >= 3:
      goto restart
  else:
    stuck_count = 0
    prev_bytes = cur_bytes

  # 总超时
  if now() - start > total_timeout:
    goto restart

  # 正常完成
  if tail 含 "EXIT=0" 或工具特定成功信号:
    记录版本 → 下一步

restart:
  kill 进程
  attempt += 1
  if attempt > 3:
    escalate 用户（卡点报告）
  else:
    换镜像/换参数 → 重新启动下载 → 回 loop 开头
```

### 同步执行的唯一例外

只有**预期 < 30 秒**的动作允许同步 Bash（如 `npx --version` / `which adb` / `git --version` / `winget list` 查询）。凡是走网络拉包、编译、unzip 百 MB 的动作，**一律后台 + 协议**。

### 日志必须落盘

`.claude/.setup-logs/<tool>-<attempt>.log` 必须保留（即使成功），便于：
- 用户后来说"刚才装 X 哪一步卡的" → 可追溯
- 下一轮迭代 triage-agent 分析"哪些工具在当前网络下总失败" → 决定默认换镜像

### 套用到本 playbook 的所有自动装段落

下面每个平台分支（Windows / Android / iOS / Flutter / Electron·Tauri）里写的 `winget install ...` / `npm install -g ...` / `curl ... | bash` / `brew install ...` / `appium driver install ...` / `xcode-select --install`，**全部**必须走本协议启动，而不是同步 `Bash`。分支里为了可读性写成一行命令，但执行时套壳子（日志 + 后台 + poll）。

---

## 执行流程

### 1. 读取目标平台

```
Read docs/requirements.md 的 "主要平台" 字段
```

**解析出的值**可能是：
- `Web`（浏览器端）
- `Windows 桌面`
- `macOS 桌面`
- `Linux 桌面`
- `Android`
- `iOS`
- `Flutter`（跨平台移动）
- `Electron` / `Tauri`（跨平台桌面）
- 组合（如 `Web + Android + iOS`）

**若未明确写**：按画像措辞问用户一句：
> `<称呼>，你这个 <项目名> 最终要跑在哪儿？Web（浏览器）/ 手机 App / 桌面程序？`

### 2. 检测操作系统

```bash
uname -s 2>/dev/null || ver 2>/dev/null
```

- `Darwin` → macOS
- `Linux` → Linux
- Windows → 见 `ver` 或 `%OS%`

决定后续用哪种包管理器（winget / brew / apt / 直装脚本）。

### 3. 按平台执行分支

对**每个**目标平台，依次跑下面的分支。已装的跳过。

---

## 平台分支

### 🌐 Web

**工具**：Playwright MCP（kickoff 阶段 0.5 已装过）。

```bash
claude mcp list 2>&1 | grep -qi playwright && echo "OK" || echo "MISSING"
```

若 MISSING：回 kickoff 阶段 0.5 流程重装。

---

### 🪟 Windows 桌面

需要：
- **WinAppDriver**（Microsoft 官方 UI 自动化）
- **Appium + appium-windows-driver**（封装 WinAppDriver，node 生态）
- **Node.js**（Appium 要）

#### 检测

```bash
# Node.js
npx --version

# WinAppDriver（安装路径）
ls "C:/Program Files (x86)/Windows Application Driver/WinAppDriver.exe" 2>/dev/null \
  || powershell -Command "Get-Command WinAppDriver -ErrorAction SilentlyContinue"

# Appium Windows driver
appium driver list --installed 2>/dev/null | grep -i windows
```

#### 自动装

```bash
# 1) WinAppDriver（优先 winget）
winget install --id Microsoft.WinAppDriver -e --silent

# 失败 fallback：提示用户
# "winget 装 WinAppDriver 失败，请手动下载：
#  https://github.com/microsoft/WinAppDriver/releases"

# 2) Appium 全局
npm install -g appium

# 3) Windows driver
appium driver install --source=npm appium-windows-driver

# 4) Python 客户端（如果项目用 Python 写测试）
# pip install Appium-Python-Client
```

**说明按画像措辞**：
- 小白：`<称呼>，你这个是 Windows 桌面应用，我需要装几个工具来帮你做自动化测试，大概 3-5 分钟，我来搞定。`
- 技术：`<称呼>，装 Windows 自动化栈：WinAppDriver (winget) + Appium + appium-windows-driver。`

**本工作区有 `winappdriver` skill 可参考**（已经在 MetaBot 安装的 skills 里）。

---

### 🤖 Android

**推荐：Maestro**（最简单，YAML 脚本即可）。Appium + uiautomator2 作为备选。

#### 检测

```bash
# Maestro
maestro --version 2>/dev/null

# Android SDK / adb
adb --version 2>/dev/null

# Android Studio（路径检测）
ls ~/Library/Application\ Support/Google/AndroidStudio* 2>/dev/null   # Mac
ls "$LOCALAPPDATA/Google/AndroidStudio*" 2>/dev/null                  # Windows
ls ~/.config/Google/AndroidStudio* 2>/dev/null                        # Linux
```

#### 自动装

**Maestro**（跨平台）：

```bash
# Mac / Linux
curl -Ls "https://get.maestro.mobile.dev" | bash

# Windows（PowerShell）
powershell -Command "iwr -useb https://get.maestro.mobile.dev/windows | iex"
```

**ADB / Android SDK**：
- 通常随 Android Studio 安装，**需要用户手动**装 Android Studio
- 无 Android Studio 但有命令行需求：用 sdkmanager

**Android Studio 引导**（需要用户参与）：

按画像说：
- 小白：`<称呼>，Android 开发需要 Android Studio（免费，300MB）。我这里没法自动装，你去 developer.android.com/studio 下载 → 双击安装 → 第一次打开会自动装 SDK。装完说"装好了"我继续。`
- 技术：`<称呼>，需要 Android Studio / SDK / adb。如果你有 Android Studio 跳过；否则去 developer.android.com/studio。`

**Appium + uiautomator2**（备选）：

```bash
npm install -g appium
appium driver install uiautomator2
```

---

### 🍎 iOS（仅 macOS 可开发）

#### 检测

```bash
# 必须 Mac
[ "$(uname -s)" = "Darwin" ] || echo "FAIL: iOS 只能在 Mac 开发"

# Xcode CLI
xcode-select -p 2>/dev/null

# Appium xcuitest driver
appium driver list --installed 2>/dev/null | grep -i xcuitest
```

#### 自动装

```bash
# Xcode Command Line Tools
xcode-select --install

# Appium + xcuitest
npm install -g appium
appium driver install xcuitest

# Maestro（也支持 iOS）
curl -Ls "https://get.maestro.mobile.dev" | bash
```

**Xcode full**（App Store 下载，要登录）—— 无法完全自动，告诉用户：
- `<称呼>，iOS 完整开发需要 Xcode（App Store 免费，~12GB）。装完后我继续。`

**非 Mac 环境做 iOS**：
- 可以写代码（Flutter / React Native 跨平台），但无法真机测试/发布
- 告诉用户：`<称呼>，你这不是 Mac，iOS 没法真机测试。我可以用 Flutter/RN 写跨平台代码，真要发布 iOS 得找台 Mac（或 EAS Build 云编译）。`

---

### 🐦 Flutter

Flutter SDK 是大包（~1GB 压缩），无法完全无人值守。

#### 检测

```bash
flutter --version 2>/dev/null
```

#### 引导用户装（大包，需要交互）

- Mac：`brew install --cask flutter`（用 Homebrew 可自动）
- Windows / Linux：引导去 https://docs.flutter.dev/get-started/install
- 装完 `flutter doctor` 看缺什么（Android toolchain / iOS toolchain）

**按画像说**：
- 小白：`<称呼>，你要做 Flutter 的话需要装 Flutter SDK（官方工具，1GB）。去 docs.flutter.dev/get-started/install 按你系统选指引。装完说"装好了"。`
- 技术：`<称呼>，flutter SDK 太大不能自动装（1GB）。brew install --cask flutter（Mac）或官网下载。装完 flutter doctor 看缺啥。`

---

### 🖥️ Electron / Tauri（跨平台桌面）

**Electron**：Playwright 可以直接测（有 `_electron` API），无需额外工具。
**Tauri**：Playwright 测 webview + Rust 单元测试（`cargo test`）。

```bash
# 检查 Rust（Tauri 需要）
cargo --version 2>/dev/null
rustc --version 2>/dev/null
```

Rust 未装：

```bash
# Mac / Linux
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Windows
# 引导下载 rustup-init.exe 从 https://rustup.rs
```

---

### 🐧 macOS / Linux 桌面

Electron/Tauri 优先。原生开发：
- **macOS 原生**：Swift + Xcode（同 iOS 工具链）
- **Linux 原生**：Qt / GTK + 对应测试框架（场景较少）

小众场景，遇到再问用户细节。

---

## 4. 自动装完成后更新 `.claude/settings.json`

把新工具加入 permissions allow 列表，避免每次弹权限确认：

```json
{
  "permissions": {
    "allow": [
      "Bash(maestro *)",
      "Bash(adb *)",
      "Bash(appium *)",
      "Bash(flutter *)",
      "Bash(WinAppDriver *)"
    ]
  }
}
```

按项目实际装了哪些工具动态追加。

---

## 5. 完成后对用户报告（按画像）

**小白版**：
```
<称呼>，开发环境搞定 ✓
装了：<工具列表用人话>
没装（需要你自己动手）：<如果有 Flutter/Xcode 等>
下面我开始写代码了。
```

**技术版**：
```
<称呼>，工具链就绪 ✓
Auto-installed: <list>
Pending manual: <list with URLs if any>
Permissions allowlist updated in .claude/settings.json.
Proceeding to dev phase.
```

---

## 失败与应对

| 场景 | 应对 |
|------|------|
| `winget` 不存在（Win 10 旧版）| Fallback 给下载 URL 让用户手动 |
| `brew` 不存在（Mac 全新）| 告诉用户先装 Homebrew：`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` |
| 权限不够（企业电脑）| `escalate`：告诉用户"需要管理员权限装 X，你有吗？没有我们用 portable 版" |
| 网络封锁某 URL | 换镜像（如 npm 用 taobao、rustup 用 ustc）或让用户挂梯子 |
| 工具装了但运行报错 | 看 stderr，按错误提示 fix；常见是 PATH 没更新，提示用户 `source ~/.bashrc` 或重开终端 |

---

## 跨平台推荐：Maestro（覆盖 Web + Android + iOS）

如果项目需要**多平台**，强烈建议主推 Maestro：
- 一套 YAML 语法测 Web / Android / iOS
- 学习成本低（比 Appium 简单）
- 本地 + 云（Maestro Cloud）都支持

在需求圣经的 UI/UX 决策里可以建议用户："这个跨平台项目建议用 Maestro 做 E2E，一套脚本多端跑。"

---

## 与其它 playbook 的关系

- **kickoff playbook 阶段 0.5**：只装 Playwright（kickoff wizard 要用）
- **本 playbook**：kickoff 阶段 4 后触发，装项目目标平台的工具
- **dev-agent / qa-agent 派活前**：主 agent 确认对应平台工具就绪，否则先跑本 playbook
