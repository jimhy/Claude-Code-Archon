# design-knowledge 索引

> design-agent 读取知识库前的导航。结合 [ADAPTER.md](./ADAPTER.md) 一起看。

## 适用性标签

| 标签 | 含义 | 处理方式 |
|------|------|---------|
| **[AS-IS]** | 可原样注入 AI prompt | 读进上下文直接用 |
| **[ADAPT]** | 规则通用但术语是 openpencil IR（frame/fill_container/cornerRadius 等）| 读时在脑子里按 ADAPTER.md 翻译成 HTML+Tailwind |
| **[PENCIL-ONLY]** | 严重依赖 openpencil 节点操作 API / JSONL / schema | 仅 `design-pencil-agent` 用，`design-agent` ai-self 模式**跳过** |
| **[IGNORE]** | 我们当前栈用不到（如其它框架的 codegen）| 保留归属，目前不读 |

---

## style-guides/ — 50 个视觉风格预设 [全部 AS-IS]

每个文件 frontmatter 带 `tags` 和 `platform`（webapp / mobile）。按**标签匹配**选风格，不要读全部。

### 按场景聚合

| 场景 | 候选风格（示例，按需挑 1） |
|------|-------------------------|
| **SaaS / B2B / Corporate** | `saas-clean-light`, `saas-modern-light`, `corporate-blue-light`, `enterprise-slate-dark`, `startup-gradient-dark` |
| **Fintech / 金融** | `fintech-dark-blue-light`, `crypto-dark-bold`, `finance-clean-mobile-light` |
| **Dashboard / 后台** | `dashboard-analytics-dark`, `enterprise-slate-dark`, `developer-terminal-dark` |
| **极简 / 北欧 / 日式** | `nordic-frost-light`, `scandinavian-minimal-light`, `japanese-swiss-light`, `zen-paper-light`, `midnight-minimal-dark`, `portfolio-minimal-light` |
| **大胆 / 表现** | `brutalist-luxury-dark`, `cyber-gradient-dark`, `industrial-neon-dark`, `bauhaus-geometric-light`, `monochrome-expressive-light` |
| **游戏 / 娱乐** | `gaming-electric-dark`, `music-dark-mobile`, `neon-purple-mobile-dark` |
| **奢华 / 时尚** | `luxury-brand-dark`, `luxury-fashion-mobile-dark`, `elegant-luxury-dark`, `noir-elegant-dark` |
| **温暖 / 柔和 / 生活** | `warm-food-mobile-light`, `pastel-soft-mobile-light`, `retro-warm-light`, `travel-warm-mobile-light` |
| **医疗 / 教育 / 公益** | `healthcare-trust-light`, `health-minimal-mobile-dark`, `wellness-organic-light`, `wellness-green-mobile-light`, `education-friendly-light`, `nonprofit-warm-light` |
| **开发者 / 终端 / AI** | `developer-terminal-dark`, `terminal-minimal-dark`, `tech-developer-dark`, `ai-product-dark` |
| **电商 / 消费** | `ecommerce-modern-light`, `luxury-fashion-mobile-dark` |
| **社交 / 内容** | `social-vibrant-mobile-light`, `clean-blue-mobile-light`, `agency-editorial-light`, `editorial-serif-light` |
| **创意 / 工作室** | `creative-bold-light`, `minimal-playful-light`, `dark-bold-mobile` |

### 选风格流程

先读 `phases/planning/style-guide-selector.md`，它定义了按用户请求的 tag 匹配规则。实际实现参考 ADAPTER.md 里的 `selectStyleGuide()` 伪代码。

---

## domains/ — 5 个领域指南 [全部 ADAPT]

> 结构规则通用，但文件内部用 openpencil 节点术语描述布局（width/height/padding/gap）。按 ADAPTER.md 翻译成 Tailwind class。

| 文件 | 用途 | 触发关键词 |
|------|------|-----------|
| `landing-page.md` | 落地页结构（Nav-Hero-Features-Social Proof-CTA-Footer）| landing / marketing / hero / homepage |
| `dashboard.md` | 管理后台 / 分析面板 | dashboard / analytics / admin |
| `form-ui.md` | 表单设计（登录/注册/设置）| form / signup / login / settings |
| `mobile-app.md` | 移动端专用 | mobile / app / ios / android |
| `cjk-typography.md` | 中日韩排版规则（**中文项目必读**）| chinese / japanese / korean / 中文 |

---

## knowledge/ — 通用知识

### [AS-IS] 直接用的（8 个）

| 文件 | 用途 |
|------|------|
| `design-principles.md` | **核心设计铁律**（type scale / 8px grid / WCAG AA）— 必读 |
| `product-principles.md` | 产品设计原则 |
| `component-composition.md` | 组件组合规则 |
| `copywriting.md` | 文案指南（headline hierarchy、CTA 措辞）|
| `icon-catalog.md` | Lucide 图标目录（我们默认图标库）|
| `examples.md` | 设计示例库 |
| `role-definitions.md` | AI 设计师角色定义 |
| `codegen-react.md` | **我们主栈** React + Tailwind 生成指南 |
| `codegen-html.md` | 纯 HTML+Tailwind 生成指南 |

### [IGNORE] 其它框架 codegen（6 个）

`codegen-vue.md`, `codegen-svelte.md`, `codegen-flutter.md`, `codegen-swiftui.md`, `codegen-compose.md`, `codegen-react-native.md`

保留归属，将来项目技术栈切换时可启用。

---

## phases/ — 分阶段 prompt

### planning/ [全部 ADAPT]

| 文件 | 用途 |
|------|------|
| `decomposition.md` | 把页面切成空间子任务（hero / features / footer）|
| `design-type.md` | 识别用户想要的设计类型 |
| `landing-page-predesign.md` | 落地页预设计 |
| `style-guide-selector.md` | **选风格**（core prompt，必读）|

### generation/ [混合]

| 文件 | 标签 | 用途 |
|------|------|------|
| `anti-slop.md` | **[AS-IS]** | **反 AI 套路化**，强制视觉多样性（必读） |
| `layout.md` | **[ADAPT]** | 布局规则（**宽度数学公式必读**，其它术语翻译）|
| `overflow.md` | [ADAPT] | 溢出处理 |
| `text-rules.md` | **[AS-IS]** | 文字规则（大小/权重/行高，IR-agnostic） |
| `style-defaults.md` | [AS-IS] | 样式默认值 |
| `design-system.md` | [AS-IS] | 设计系统构建规则 |
| `variables.md` | [ADAPT] | 设计变量（CSS vars 对应）|
| `design-code.md` | [ADAPT] | 节点生成对应代码 |
| `design-md.md` | [ADAPT] | design.md 文件生成（可改写成 design-notes.md）|
| `codegen-planning.md` | **[PENCIL-ONLY]** | codegen 子系统规划 |
| `codegen-chunk.md` | **[PENCIL-ONLY]** | codegen 分块 |
| `codegen-assembly.md` | **[PENCIL-ONLY]** | codegen 组装 |
| `jsonl-format.md` | **[PENCIL-ONLY]** | openpencil JSONL 输出格式 |
| `jsonl-format-simplified.md` | **[PENCIL-ONLY]** | JSONL 简化版 |
| `schema.md` | **[PENCIL-ONLY]** | openpencil 节点 schema |

**ai-self 模式读清单**：anti-slop + text-rules + style-defaults + design-system + （ADAPT 后）layout + overflow + variables

### validation/ [1 个]

| 文件 | 标签 | 用途 |
|------|------|------|
| `vision-feedback.md` | [ADAPT] | 视觉 QA 评审 12 项清单（规则通用，输出 schema 需按 HTML 场景重写）|

### maintenance/ [全部 ADAPT]

| 文件 | 用途 |
|------|------|
| `incremental-add.md` | 增量添加新模块 |
| `local-edit.md` | 局部编辑已有设计 |
| `style-consistency.md` | 风格一致性检查 |

---

## 快速检索场景

| 场景 | 读这些文件 |
|------|----------|
| **新项目首次设计** | design-principles + product-principles + domains/<type> + style-guide-selector → style-guides/<picked> + anti-slop + layout(ADAPT) |
| **评审自己的设计** | vision-feedback(ADAPT) + anti-slop（反套路检查）|
| **风格想改** | style-consistency + style-guide-selector + 新 style |
| **只想改一小块** | local-edit + incremental-add |
| **中文项目** | 上面任何场景 + domains/cjk-typography |

---

## 首次使用检查

design-agent 第一次跑时建议做一次自检：
1. `ls .claude/design-knowledge/` 确认 5 个子目录 + 3 个 md 都在
2. Read LICENSE-openpencil 确认归属完好
3. Read ADAPTER.md 把映射表装进上下文
4. 按 README.md "读取顺序" 分层拉文件
