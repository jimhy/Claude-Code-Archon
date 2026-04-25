# Verification Playbook — 交付前真实度硬门槛

> ⚠️ **这是防止"骗人交付"的最后一道防线。** qa-agent / integration-agent / delivery-agent 在宣称完成前都必须按本 playbook 执行，主 agent 在批准交付前也必须复核。
>
> **起源**：用户反馈三类造假行为——(1) 声称测试通过但没真跑；(2) Mock 数据偷偷泄露到交付版；(3) Web/PC/Mobile 没用对应自动化工具真跑，凭空写测试结果。
>
> **核心原则**：**No evidence, no claim.** 任何"done / pass / works"的声明必须挂一个可打开的文件（录屏/截图/日志），且主 agent 会 Read 这个文件验真，不许只给路径字符串糊弄。

---

## 🚫 三大禁忌（违反即回退 + 重派）

### 禁忌 1：虚假测试（Fake Testing）

**禁止的行为**：
- ❌ 写了 `expect(true).toBe(true)` 这种废 assertion 混测试数
- ❌ 写了真 assertion 但**没跑测试**就说"通过"
- ❌ 只跑 1 个测试文件就说"整体测试通过"
- ❌ `test.skip` / `xit` / `test.only` 偷偷跳过
- ❌ 捕获异常不报错让测试"永远绿"
- ❌ 测试里 mock 掉被测代码本身（等于没测）
- ❌ 宣称"功能实现"但 E2E 只点到页面出现按钮就停（**没走完用户实际场景的数据流**）

**必须做的**：
- ✅ 每个功能至少 1 个 **端到端真实场景**（从点按钮 → 发请求 → 看到结果 → 验证数据落盘）
- ✅ 跑测试要用 `--reporter=html,json` 双份落盘到 `test-results/<task>/`
- ✅ 测试输出必须挂到 `evidence[]`，主 agent 会 Read 验真
- ✅ 失败的测试不许偷偷改绿；红灯就是红灯，回去修实现

### 禁忌 2：Mock 数据泄露（Mock Leak）

**禁止的行为**：
- ❌ `src/` 下散落 `const users = [{id: 1, name: 'test'}]` 之类硬编码数据但没标记
- ❌ API 调用被 fetch wrapper 偷偷返回 mock，没在 UI 提示"mock 模式"
- ❌ 交付给用户的版本还在用 `if (true) return mockData`
- ❌ delivery-agent 打包时没扫描 mock 标记就交付

**必须做的**：
- ✅ **所有** mock 数据必须在代码里带 `// MOCK: <reason> <issue-ref>` 注释
- ✅ Mock 数据**集中放** `src/mocks/` 或 `src/__mocks__/`，不许散落各组件
- ✅ Mock 启用由 **单一开关**控制（例：`VITE_USE_MOCK` / `NEXT_PUBLIC_MOCK_API`），生产 build 默认关
- ✅ 交付前 `grep -rn "MOCK:" src/` 扫描，列清单给用户
- ✅ 用户画像为**小白 / 非技术**时，**禁止交付 mock 版**——要么接真后端，要么 escalate 用户说明"我搞不定后端，建议用 Supabase/Firebase 免费版，我帮你接"

### 禁忌 3：平台验证错位（Platform Mismatch）

**禁止的行为**：
- ❌ Windows 桌面 app 只用 Playwright 浏览器测（Playwright 不测原生 Win32 窗口）
- ❌ Android app 没启模拟器/真机就说"E2E 通过"
- ❌ iOS app 不在 Mac 上跑 xcuitest 就说"iPhone 上没问题"
- ❌ 跨平台应用只测 Web 一端就交付所有端

**必须做的**：按目标平台**调用对应自动化工具**（见下表"平台验证矩阵"）。没对应工具时走"降级协议"——明确告诉用户哪端没真测，而不是假装测过。

---

## 📊 平台验证矩阵

**读 `docs/requirements.md` 的"主要平台"字段**，对号入座。每个平台**至少一条录屏证据**（Windows 的.webm / Mac 的.mov / Android 的.mp4 / iOS 的.mp4），主 agent 会真 Read 录屏文件大小 > 0 来验。

| 平台 | 必用自动化工具 | 录屏产物路径 | 验证最小动作 |
|------|---------------|-------------|-------------|
| **Web**（桌面浏览器）| Playwright（headless） | `test-results/web-desktop/main-flow.webm` | 跑完 happy path + 1 错误场景，视口 1440×900 |
| **Web**（移动浏览器）| Playwright（`viewport: 375×812`，emulated）| `test-results/web-mobile/main-flow.webm` | 同上但 375 视口，验证键盘不挡输入框 |
| **Windows 桌面** | WinAppDriver + Appium（see `platform-setup.md`）| `test-results/win-desktop/main-flow.webm` | 启动 app → 主流程 → 关闭；窗口不能一直白屏 |
| **macOS 桌面** | XCTest（native）/ Playwright（Electron）/ Appium mac2 driver | `test-results/mac-desktop/main-flow.mov` | 启动 → 主流程 → 关闭 |
| **Linux 桌面** | dogtail（GTK）/ Playwright（Electron）| `test-results/linux-desktop/main-flow.webm` | 启动 → 主流程 |
| **Android** | **Maestro**（首选，YAML）/ Appium + uiautomator2 | `test-results/android/main-flow.mp4` | 在模拟器（AVD）或真机跑；必须有 `adb devices` 真返回设备 |
| **iOS** | Appium + xcuitest / Maestro iOS | `test-results/ios/main-flow.mp4` | Mac + Simulator 或真机；`xcrun simctl list devices` 必须返回 Booted |
| **Flutter**（跨端）| `flutter test integration_test/` + 各端真机 | `test-results/flutter-<platform>/` | 每个目标端（Android/iOS）都跑一次 |
| **React Native** | Detox / Maestro | `test-results/rn-<platform>/` | 每端都跑 |
| **Electron** | `_electron` API of Playwright | `test-results/electron/main-flow.webm` | 启 app 实例 → 主流程 |
| **Tauri** | Playwright 测 WebView + `cargo test` 测 Rust | `test-results/tauri/` | Both |

### 录屏不可伪造的检查

主 agent（或 integration-agent）验收时必须：

1. **文件存在**：`ls test-results/<platform>/` 有录屏文件
2. **文件大小 > 50KB**（空录屏通常 < 10KB）：`stat -c %s <file>` 或 `ls -la`
3. **时长 > 3 秒**：`ffprobe -v error -show_entries format=duration <file>`（ffmpeg 必装或降级为 size 检查）
4. **内容采样**（可选但推荐）：用 ffmpeg 抽首/中/末三帧 PNG，Read 进来看是否是真应用截图，不是白屏/黑屏

---

## ✅ Definition of Done（DoD）清单 — 每个功能必过

交付任何**功能**前，dev-agent + qa-agent + integration-agent 联合确认：

```
[ ] 该功能在需求圣经 docs/requirements.md 里有验收标准
[ ] 实现代码不是 stub / TODO / console.log —— 实际有业务逻辑
[ ] 单元测试真实运行（不是 expect(true)），test-results/unit/ 有 junit.xml
[ ] E2E 覆盖该功能主路径，视频 > 3 秒 + > 50KB
[ ] E2E 覆盖至少 1 个错误/边界场景，视频落盘
[ ] 该功能走的数据链是真实的（真 API / 真 DB / 真第三方服务）——
    或明确标记 MOCK 并在交付说明里告知
[ ] 该功能的所有 mock（若有）都在 src/mocks/ 并有 MOCK: 注释
[ ] 跨端项目的每端都按"平台验证矩阵"跑过
[ ] 移动端视窗（375×667 或真机）跑过
[ ] 截图通过 ui-critic，录屏通过 ux-critic
[ ] 无 console.error（或明确白名单）
```

**任一项未打勾 → 不算完成，回修或 escalate。** 禁止"10 项勾 8 项就交付"。

---

## 🔍 交付前真实度扫描（delivery-agent 必做）

delivery-agent 在生成交付包前，必须跑以下扫描：

### 1. Mock 残留扫描

```bash
# 扫所有 MOCK 标记
grep -rn "MOCK:" src/ > delivery/<ts>/mock-scan.txt || echo "No MOCK markers found"

# 扫硬编码的可疑测试数据
grep -rniE "test@|example\.com|1234567890|localhost:3000|TODO|FIXME" src/ \
  > delivery/<ts>/suspicious-scan.txt
```

**判定规则**：
- `mock-scan.txt` **非空** + 用户画像是小白/非技术 → **拒绝交付**，`escalate` 主 agent："Mock 未清理，不适合向非技术用户交付"
- `mock-scan.txt` 非空 + 用户画像是技术/专家 → 允许交付，但 README 里**必须列全部** mock 清单 + 每项"如何替换为真实服务"
- `suspicious-scan.txt` 有 `TODO`/`FIXME` → 列在 README 的"已知未做"里

### 2. 功能实现度扫描

对照 `docs/requirements.md` 的功能清单，逐项核对：

```
对每个"P0 功能"：
  1. 找到对应的 E2E 录屏（按命名 test-results/**/<feature-id>*.webm）
  2. 录屏不存在 → 标记 "未验证"
  3. 录屏 < 50KB → 标记 "空录屏，未验证"
  4. 录屏 OK → 标记 "已验证"
```

`未验证` 项数 > 0 → 拒绝交付 → escalate 主 agent。

### 3. 平台覆盖扫描

```
对需求圣经里的每个目标平台：
  1. test-results/<platform>/ 是否存在？
  2. 是否至少有一个 > 50KB 的录屏？
  3. 是否有该平台对应工具链的测试 log（如 maestro-output.log / appium.log）？
```

任一平台缺失 → 拒绝交付 → escalate。

### 4. 真实度报告（交付说明必带一节）

不论通过与否，delivery-agent 的 README.md 里必须包含"真实度报告"章节：

```markdown
## 🔬 真实度报告

### 功能实现度
- ✅ <功能 A>：已实现 + E2E 覆盖（见 `demo/feature-A.webm`）
- ✅ <功能 B>：已实现 + E2E 覆盖
- ⚠️ <功能 C>：**仅实现 UI，数据走 mock**（见 `src/mocks/featureC.ts`；替换指引：接入 <服务名> 的 <endpoint>）
- ❌ <功能 D>：**未实现**，留在下一轮

### 数据真实性
- 真实数据：<列表，如"用户登录走真实 Supabase"、"支付走 Stripe 测试模式"）
- Mock 数据：<列表，每项含"为什么 mock" + "如何替换"；如无则写"本次无 mock"）

### 平台覆盖
- Web 桌面：✅ `test-results/web-desktop/main-flow.webm`（12MB / 45 秒）
- Web 移动：✅ `test-results/web-mobile/main-flow.webm`（8MB / 38 秒）
- Android：⚠️ **未测**（理由：本次需求圣经定的是 Web MVP，Android 留在 Phase 2）

### 已知"声称了但没真跑"的项 — 必须诚实列出
- <若无→写"None"；若有→列出并给补救时间表>
```

**诚实字段不许省略**。宁可交付时用户看到"Android 未测"，也不要交付后用户发现"你说测了其实没测"。

---

## 🎛 按用户画像的交付门槛差异

| 画像 | 允许带 mock 交付吗？ | 交付前平台覆盖硬度 |
|------|--------------------|------------------|
| **小白** | ❌ 完全不允许。mock = 假完成，必须接真后端或 escalate | 主 + 移动两端必录屏 |
| **非技术** | ⚠️ 可以但必须 UI 上有"示例数据"标记，README 顶部大字提示 | 主 + 移动两端必录屏 |
| **普通技术** | ✅ 允许，按需求圣经范围 | 目标平台全覆盖 |
| **专家** | ✅ 允许，mock 清单详列，含"如何切真实"指南 | 目标平台全覆盖 + 边界端口列表 |

---

## 🔧 降级协议（某平台工具链装不上时）

如果某平台的自动化工具（如 Maestro、Appium、xcuitest）装不起来（网络/权限/非 Mac 环境）：

1. **不许假装测过**
2. **必须在真实度报告里明确标注**："<平台> 未自动化测试，原因 <...>"
3. **让用户知情**：按画像措辞，小白版→"这一端我没测，你先试试，有问题告诉我"；技术版→"<端> 缺 <工具链> 无法自动测；手动验证路径见 docs/manual-test-<platform>.md"
4. **escalate 给主 agent 决策**：是否阻塞交付？是否改需求圣经缩小范围？

---

## 🚨 主 agent 验收时的"第二道眼"

subagent 返回 `status=success` 时，主 agent 必须做**独立校验**（对应 CLAUDE.md 第 5 条"不信子 agent 的完成"）：

```
1. Read subagent 返回的每一个 evidence 路径 → 确认文件存在 + 非空
2. 对录屏类证据 → `stat` 确认 > 50KB
3. 对测试报告类证据 → Read 文件内容抽样，确认不是空 JSON / 空 HTML
4. 对照本 playbook 的 DoD 清单 → 逐项核对 subagent 是否真的全过
5. grep 有 "MOCK:" 标记 → 对照交付画像判断是否允许
6. 任一项不过 → reject subagent，附带"哪项不过、为什么"，要求补证据或重跑
```

**硬规矩**：subagent 说 success 但 evidence 假/缺 → 视为 `failed` + 该 subagent 本轮 trust score -1（连续 3 次虚报 → 主 agent 应派 code-reviewer 审它的输出流程是否有系统性问题）。

---

## 与其它 playbook / 铁律的关系

- **CLAUDE.md 铁律 11**（反偷懒——证据挂钩）引用本 playbook 的 DoD 清单 + 三大禁忌
- **CLAUDE.md 铁律 12**（真实数据 + Mock 隔离）引用本 playbook 的 Mock 隔离章节
- **platform-setup.md**：本 playbook 的"平台验证矩阵"前提是 platform-setup 已把工具装好
- **qa-agent.md**：必读本 playbook 的 DoD + 三大禁忌，跑测试要按矩阵
- **delivery-agent.md**：必跑本 playbook 的"交付前真实度扫描"
- **integration-agent.md**：发布前跑"平台覆盖扫描" + 录屏验真
- **dev-agent.md**：mock 标记规则 + 不许在实现里留 stub 假装完成
