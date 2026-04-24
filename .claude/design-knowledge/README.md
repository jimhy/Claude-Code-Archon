# design-knowledge 设计知识库

> 驱动 **"AI 自己设计 UI/UX"**（design-agent 的 ai-self 模式）的核心资产。

## 这是什么

66 个结构化 Markdown 文件，涵盖：
- 50 个视觉风格预设（style-guides/）
- 5 个领域设计指南（domains/）
- 15 个通用知识（knowledge/）
- 23 个分阶段 prompt（phases/）

每个文件带 YAML frontmatter（`name`、`tags`、`phase`、`trigger`、`priority`、`budget`），供 AI 按阶段 + 关键词 + 预算检索。

## 来源与归属

本目录（不含 `README.md` / `INDEX.md` / `ADAPTER.md`）整体搬运自开源项目 **openpencil** 的 `packages/pen-ai-skills/skills/`：

- 仓库：https://github.com/ZSeven-W/openpencil
- License：**MIT**（见 [LICENSE-openpencil](./LICENSE-openpencil)）
- 原包 README：[SOURCE-README.md](./SOURCE-README.md)

使用时必须保留 LICENSE-openpencil 归属声明。

## 怎么用

### 读取顺序（design-agent 每次新设计会话）

```
1. ADAPTER.md      —— openpencil IR 语义 → HTML+Tailwind 翻译对照（必读）
2. INDEX.md        —— 按目录清单 + 适用性标签，决定读哪些
3. knowledge/design-principles.md  —— 通用铁律
4. knowledge/product-principles.md —— 产品决策原则
5. 按用户意图读对应 domain:
   - "做个落地页" → domains/landing-page.md
   - "Dashboard / 后台"  → domains/dashboard.md
   - "移动 App" → domains/mobile-app.md
   - "表单" → domains/form-ui.md
   - 涉及中/日/韩文本 → domains/cjk-typography.md
6. phases/planning/style-guide-selector.md
   → 从 style-guides/ 里选出 1 个匹配的风格
7. 读选中的 style-guides/<name>.md
8. phases/generation/ 下的通用规则（anti-slop / layout / text-rules / ...）
9. 开始产出（HTML + Tailwind）
10. phases/validation/vision-feedback.md 指导 critic 评审自己的截图
```

### 三模式回顾

| 模式 | agent | 怎么用本目录 |
|------|-------|------------|
| **ai-self** | `design-agent` | 整目录驱动，产出 HTML+Tailwind 草稿 + Playwright 截图 + critic 评审 |
| **pencil** | `design-pencil-agent` | 原样驱动（本来就是 openpencil 的），产出 `.pen` + PNG |
| **user** | （不派 agent）| 用户自己给设计，本目录不使用 |

## 目录结构

```
.claude/design-knowledge/
├── README.md              ← 本文件：入口
├── INDEX.md               ← 清单+适用性标签
├── ADAPTER.md             ← openpencil → HTML+Tailwind 映射表
├── LICENSE-openpencil     ← MIT 归属
├── SOURCE-README.md       ← 原包 README
├── style-guides/          ← 50 个视觉风格预设（全部 AS-IS）
├── domains/               ← 5 个领域指南（全部 AS-IS）
├── knowledge/             ← 通用知识（8 AS-IS + 7 codegen 备用）
└── phases/
    ├── planning/          ← 4 个阶段 prompt
    ├── generation/        ← 15 个（通用规则 + openpencil 特化）
    ├── validation/        ← 1 个视觉评审 prompt
    └── maintenance/       ← 3 个维护场景
```

## 维护约定

- **不破坏性修改 openpencil 文件** — 原样保留便于后续 pull upstream
- **补充只放在 ADAPTER.md 和项目级 design-knowledge-local/** — 和上游分离
- **INDEX.md 标签有争议时** — 实际用的时候 design-agent 再 sanity check 一次
- **搬新版本** — 直接 sparse clone openpencil 覆盖 style-guides/domains/knowledge/phases/ 即可
