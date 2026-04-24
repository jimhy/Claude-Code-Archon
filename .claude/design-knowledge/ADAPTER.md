# ADAPTER：openpencil IR → HTML + Tailwind 映射

> 本目录知识库原生服务 openpencil 的 `.op` 节点树。我们在 `ai-self` 模式下用它产出 **HTML + Tailwind**。这份文档定义一套统一翻译规则，design-agent 读任何 [ADAPT] 标签文件时按此翻译。

---

## 一、节点类型映射

| openpencil 节点 | HTML 对应 | Tailwind 辅助 |
|----------------|----------|--------------|
| `frame`（layout 容器）| `<div>` / `<section>` | `flex` |
| `frame`（纯视觉块）| `<div>` | `bg-*` / `rounded-*` / `shadow-*` |
| `text` | `<h1>` / `<h2>` / `<p>` / `<span>`（按语义）| `text-*` / `font-*` |
| `rectangle` / `ellipse` | `<div>` | 用 `rounded-full` 做 ellipse |
| `path`（icon）| `<svg>` 或 `<Icon />`（lucide-react）| `w-* h-* text-*` |
| `image` | `<img>` / `<picture>` | `object-cover` / `object-contain` |

---

## 二、布局属性映射

### Layout 方向

| openpencil | Tailwind |
|-----------|----------|
| `layout: "vertical"` | `flex flex-col` |
| `layout: "horizontal"` | `flex flex-row`（或 `flex`）|
| `layout: "none"` | 不用 flex，用 `block` / `grid` / `relative` |

### 尺寸

| openpencil | Tailwind |
|-----------|----------|
| `width: "fill_container"` | `w-full` |
| `width: "fit_content"` | `w-fit` |
| `width: 1280` | `w-[1280px]` 或 `max-w-7xl`（常见尺寸用预设）|
| `height: "fill_container"` | `h-full` |
| `height: "fit_content"` | `h-fit`（通常省略，默认就是 auto）|
| `height: 64` | `h-16` |

**尺寸优先用 Tailwind 预设 scale**（4=1/8=2/12=3/16=4/20=5/24=6/32=8/40=10/48=12/56=14/64=16/80=20/96=24/112=28/128=32 px），非预设值才用 `[NNNpx]` 任意值。

### 间距（gap / padding）

| openpencil | Tailwind |
|-----------|----------|
| `gap: 4` | `gap-1` |
| `gap: 8` | `gap-2` |
| `gap: 12` | `gap-3` |
| `gap: 16` | `gap-4` |
| `gap: 20` | `gap-5` |
| `gap: 24` | `gap-6` |
| `gap: 32` | `gap-8` |
| `gap: 48` | `gap-12` |
| `gap: 64` | `gap-16` |
| `gap: 80` | `gap-20` |
| `gap: 96` | `gap-24` |
| `padding: N` | `p-<N/4>` |
| `padding: [top, right, bottom, left]` | `pt-* pr-* pb-* pl-*` 或简写 `py-*` / `px-*` |

### 对齐

| openpencil | Tailwind |
|-----------|----------|
| `justifyContent: "start"` | `justify-start` |
| `justifyContent: "center"` | `justify-center` |
| `justifyContent: "end"` | `justify-end` |
| `justifyContent: "space_between"` | `justify-between` |
| `justifyContent: "space_around"` | `justify-around` |
| `alignItems: "start"` | `items-start` |
| `alignItems: "center"` | `items-center` |
| `alignItems: "end"` | `items-end` |

### 视觉

| openpencil | Tailwind |
|-----------|----------|
| `cornerRadius: 4` | `rounded` |
| `cornerRadius: 6` | `rounded-md` |
| `cornerRadius: 8` | `rounded-lg` |
| `cornerRadius: 12` | `rounded-xl` |
| `cornerRadius: 16` | `rounded-2xl` |
| `cornerRadius: 9999` | `rounded-full` |
| `clipContent: true` | `overflow-hidden` |
| `fill: [{type:"solid", color:"#fff"}]` | `bg-white` / `bg-[#FFFFFF]` |
| `fill: []` | `bg-transparent` |
| `stroke: {thickness:1, fill:[#E5E7EB]}` | `border border-gray-200` |
| `stroke: {thickness:2, fill:[...]}` | `border-2` |
| `shadow` / elevation | `shadow-sm` / `shadow` / `shadow-md` / `shadow-lg` |
| `opacity: 0.5` | `opacity-50` |

### 文字

| openpencil | Tailwind |
|-----------|----------|
| `fontSize: 11` | `text-[11px]` |
| `fontSize: 12` | `text-xs` |
| `fontSize: 14` | `text-sm` |
| `fontSize: 16` | `text-base` |
| `fontSize: 18` | `text-lg` |
| `fontSize: 20` | `text-xl` |
| `fontSize: 24` | `text-2xl` |
| `fontSize: 30` | `text-3xl` |
| `fontSize: 36` | `text-4xl` |
| `fontSize: 48` | `text-5xl` |
| `fontSize: 56` | `text-6xl` |
| `fontWeight: 400` | `font-normal` |
| `fontWeight: 500` | `font-medium` |
| `fontWeight: 600` | `font-semibold` |
| `fontWeight: 700` | `font-bold` |
| `textAlign: "left/center/right"` | `text-left` / `text-center` / `text-right` |
| `letterSpacing: -1` | `tracking-tight` |
| `letterSpacing: -2` | `tracking-tighter` |
| `letterSpacing: 2` | `tracking-wider` |
| `lineHeight: 1.05` | `leading-none` |
| `lineHeight: 1.2` | `leading-tight` |
| `lineHeight: 1.5` | `leading-normal` |
| `lineHeight: 1.6` | `leading-relaxed` |
| `color: "#111827"` | `text-gray-900` |

---

## 三、Style Guide token → CSS/Tailwind

openpencil style-guide 里的颜色 token（如 `Primary Accent: #4F46E5`）直接作为：

- **Inline HTML**：`bg-[#4F46E5]` / `text-[#4F46E5]`（最快可用）
- **Tailwind config**：写到 `tailwind.config.js` `theme.extend.colors`（推荐）
- **CSS vars**：`--color-primary: #4F46E5;` + `bg-[var(--color-primary)]`

**dev-agent 接手时**：design-agent 产出的 HTML 建议用 `[#NNNNNN]` 任意值，dev-agent 负责在实现阶段沉淀到 Tailwind config。

---

## 四、反模式翻译

openpencil 的反模式（如 `layout.md` 里提到的）有的不适用于 CSS：

| openpencil 反模式 | CSS/Tailwind 情况 |
|-----------------|------------------|
| "无 position: fixed" | **CSS 有**，bottom tabbar / sticky header 用 `fixed` / `sticky` 完全 OK，不用怕"占位 spacer" |
| "child width 超过 parent 会被 clip" | CSS 默认不 clip，但 `overflow-hidden` 或 `min-w-0` flex 子项仍需注意 |
| "layout=none + 绝对定位不可靠" | CSS 里 `relative` + `absolute` 是标准做法，**可用** |
| "ring+文字居中用 frame(cornerRadius=w/2)" | 用 `<div class="rounded-full flex items-center justify-center">` 等价 |
| "宽度数学必须精确" | CSS flex `flex-1` / `w-full` 自动分配，不需手算，**但固定尺寸场景仍要算** |

---

## 五、Validation schema 翻译

`phases/validation/vision-feedback.md` 的输出 schema 是 openpencil 特化的 nodeId + property fixes。ai-self 模式下改用：

```json
{
  "qualityScore": 8,
  "issues": [
    { "severity": "major", "selector": "header nav", "problem": "间距不均", "fix": "把 gap-4 改成 gap-8" }
  ],
  "fixes": [
    { "file": "docs/design/home.html", "css_class": "rounded-lg → rounded-xl 提高现代感" }
  ]
}
```

`selector` 用 CSS selector（优先 data-testid / id）替代 nodeId。

---

## 六、不翻译的部分

以下 openpencil 概念在我们场景下**没有对应**，遇到忽略即可：

- `.op` 文件格式、JSONL streaming、pen-codegen 多框架输出
- `get_editor_state` / `batch_design` 等 Pencil MCP 工具调用
- `variables` 节点（openpencil 的内置变量系统）— 我们用 Tailwind class / CSS vars 代替
- `path` 节点的 SVG 路径自己绘制 — 我们用 lucide-react 图标库

---

## 七、产出约定（ai-self 模式）

design-agent 的 HTML 草稿产出必须遵守：

1. **根元素带 `<html lang="zh">`**（中文项目）或 `lang="en"`
2. **引入 Tailwind CDN**（draft 阶段用 `<script src="https://cdn.tailwindcss.com"></script>`）
3. **引入字体**：`<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">`（按 style-guide 里的 font family 定）
4. **移动 + 桌面双版本**：用响应式 class（`md:*` / `lg:*`）一个 HTML 搞定；或分开两份 `*-desktop.html` / `*-mobile.html`
5. **图标用 lucide**：`<i data-lucide="check-circle" class="w-5 h-5"></i>` + 页尾加载 lucide script；后续 dev-agent 换成 `<Check />` 组件
6. **图片用 placeholder**：`<img src="https://placehold.co/800x400" alt="...">` 标注用途，dev-agent 替换
7. **所有颜色、字号、间距、圆角 class** 严格对应 style-guide 里的 token 数值
8. **Playwright 截图前必须起本地 HTTP server**（`python -m http.server 8765`）— Playwright MCP 默认禁 `file://` 协议，只能访问 `http://127.0.0.1:PORT/...`。详见 `.claude/agents/design-agent.md` 步骤 6.0
