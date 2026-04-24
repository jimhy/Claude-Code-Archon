# 需求圣经（开发必读）

> **本文件由 `kickoff-agent` 通过五阶段协议产出。**
> **所有开发必须对照本文档。任何偏离需 Orchestrator 明确告知用户确认。**

---

## 元信息

- **生成日期**：YYYY-MM-DD
- **生成 agent**：kickoff-agent v1.0
- **文档版本**：v1.0
- **下次 review**：每次大版本交付后 / 有重大反馈调整时

---

## 1. 产品定位

<一句话。不超过 30 字。例："面向远程团队的异步代办协作工具，替代 Trello 用在小团队。"哪些用户在什么场景下完成什么任务达到什么结果。>

## 2. 目标用户

### 用户画像
- **主要用户**：<画像，含岗位 / 年龄段 / 使用场景>
- **次要用户**：<可选>
- **非目标用户**：<明确排除>

### 使用场景
- **场景 1**：<用户什么时候会打开这个应用做什么>
- **场景 2**：<...>

## 3. Jobs-to-be-done（用户真实要完成的任务）

> 用 "As a <user>, I want to <action>, so that <outcome>" 格式

- JTBD-1: As a <user>, I want to <...>, so that <...>
- JTBD-2: ...

## 4. 竞品研究结果

> 由 kickoff-agent 阶段 2 产出。详细对比见 `docs/kickoff/competitor-analysis.md`

### 主要参考
- **产品名**：<Linear / Stripe / Notion ...>
- **对标方面**：交互 / 视觉 / 某功能
- **参考截图**：`docs/kickoff/competitors/<name>/`

### 次要参考
- **产品名**：<...>
- **对标方面**：<...>

### 明确不参考
- **产品名**：<...>
- **原因**：<如"太复杂、不符合我们简约定位">

## 5. 核心功能 P0（本轮必做）

> 由 kickoff-agent 阶段 3 + 阶段 4 确定

### 功能 1：<名称>
- **用户故事**：<如 "用户点击'新建任务'，填表单后提交，列表立即显示">
- **对标竞品**：<竞品名> 的哪个功能（见 `docs/kickoff/competitors/<name>/<screenshot>.png`）
- **验收标准**（用户可观察的行为）：
  - ☐ 点击 X 按钮，<发生 Y>
  - ☐ 输入错误数据，<显示 Z 错误>
  - ☐ 移动端表现：<...>
- **状态覆盖**：
  - Loading：<如何表现>
  - Empty：<如何表现>
  - Error：<如何表现>
  - Success：<如何表现>

### 功能 2：<名称>
<同上>

### 功能 3：...

## 6. 🚫 明确不做的功能（范围边界）

> 这是防止范围蔓延的硬边界。任何想做的新功能必须重新走 kickoff 评估。

- ❌ **<功能 A>**：<原因，如"超出 MVP 范围，等用户反馈再定">
- ❌ **<功能 B>**：<原因，如"技术复杂度高，P1 阶段再考虑">
- ❌ **<功能 C>**：<原因，如"与我们定位冲突">

## 7. UI/UX 决策

> 由 kickoff-agent 阶段 3 + 阶段 4 确定

### 布局风格
- **类型**：<Linear 风（侧边栏+命令面板）/ Notion 风 / ...>
- **参考截图**：`docs/kickoff/competitors/<name>/desktop.png`
- **理由**：<用户选择的一句话>

### 视觉风格
- **类型**：<商务严谨 / 极客酷感 / 温暖友好>
- **参考截图**：`docs/kickoff/competitors/<name>/style-reference.png`
- **主色调**：<#hex>

### 响应式策略
- **桌面**：<1440+ 主要场景>
- **平板**：<支持 / 不支持 / 简化版>
- **移动**：<简化版 / 全功能 / 纯查看>

### 深色模式
- <默认跟随系统 / 手动切换 / 仅浅色>

### 关键交互
- **导航**：<侧边栏 / 顶栏 / 底栏（移动）>
- **命令面板**：<Cmd+K 全局 / 仅当前视图 / 不做>
- **通知**：<右上角角标 / 抽屉面板 / 不做>
- **主要动作位置**：<右上角浮动 / 底部固定 / 上下文 inline>

## 8. 技术选型

### 已决定
- **语言**：<TypeScript / Python / ...>
- **框架**：<Next.js 14 / React + Vite / ...>
- **UI 库**：<shadcn/ui + Tailwind / ...>
- **状态管理**：<Zustand / ...>
- **数据请求**：<TanStack Query / ...>
- **表单**：<react-hook-form + zod>
- **动画**：<Framer Motion>
- **数据库**：<...>
- **部署**：<Vercel / ...>

### 待定（开发中决定）
- <如"CMS 方案，可能 Sanity 或自建">

### 明确不用
- <如"Redux（过度设计）、SCSS（我们用 Tailwind）">

## 9. 非功能需求

### 性能
- **首屏 LCP**：< 2s
- **Bundle size (gzipped)**：< 200KB
- **Lighthouse Performance**：≥ 80
- **支持的浏览器**：Chrome/Safari/Firefox 最近 2 个主版本，Edge 最近版本

### 安全
- **鉴权**：<方案>
- **敏感数据存储**：<加密方案>
- **HTTPS**：必须

### 可访问性
- **Lighthouse A11y**：≥ 90
- **键盘完全可用**
- **对比度**：WCAG AA 以上

## 10. 验收标准汇总

> 自动集成到 qa-agent 的 E2E 测试用例

对每个 P0 功能生成 Gherkin：

```gherkin
Feature: <功能名>

  Scenario: Happy path
    Given <前置>
    When <动作>
    Then <可观察结果>

  Scenario: 错误场景
    ...

  Scenario: 移动端
    ...
```

## 11. 反馈收集渠道（上线后）

- **飞书 bot**：<bot 名 / chat-id>
- **Telegram bot**：<bot 名 / username>
- **App 内反馈按钮**：<位置>
- **邮箱**：<...>

所有渠道汇总到 `feedback-inbox/`，由 `triage-agent` 分类。

## 12. 决策日志

> 每次需求圣经变更记录在这里，保持可追溯

| 日期 | 变更 | 原因 | 提议 agent |
|------|------|------|------------|
| YYYY-MM-DD | 初版 | kickoff 产出 | kickoff-agent |
| ... | ... | ... | ... |
