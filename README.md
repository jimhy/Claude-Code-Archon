# Claude Code Archon

**English** | [中文](README_zh.md)

> *The orchestrator that turns Claude Code into a full autonomous dev team.*
> One archon conducts, a pantheon of subagents executes — you only show up at the two ends: requirements and delivery.

A battle-tested CLAUDE.md + agents bundle that upgrades Claude Code from a coding assistant into a **self-driving engineering team**.

**Zero commands, zero install scripts.** Copy one folder → open Claude Code → talk in plain language.

---

## Get started (just two steps)

### Step 1 — Copy the `.claude/` folder

Pick one location:

| Where | Effect |
|-------|--------|
| `~/.claude/` (global) | Available to every project |
| `<your-project>/.claude/` (project-scoped) | Only this project; overrides global |

**Windows**:
```
Drag .claude/ into C:\Users\<you>\.claude\
or into <project-root>\.claude\
```

**Mac / Linux**:
```bash
cp -r .claude ~/.claude
# or
cp -r .claude <your-project>/.claude
```

> **Tip**: if `.claude/` already exists at the destination, merge manually (mostly files under `agents/`).

### Step 2 — Open Claude Code and just talk

```
You: I want to build an expense-tracking app for myself, with cloud sync.

Claude: (auto-detects new project → dispatches kickoff-agent)
  Hey, before we start I'll quickly learn 3 things about you so
  I can tune how I talk to you going forward:
  1. Do you write code day-to-day?
  ...
```

**That's it.** No `/kickoff` to memorize, no docs to read, no scripts to run.

---

## What it does for you

Based on what you say, Claude infers intent and dispatches the right subagent automatically.

| What you say | What happens |
|--------------|-------------|
| "I want to build X" | Full requirements discovery (profile detection → 5 questions → competitor research → HTML option page → A/B follow-ups → requirements bible) |
| "Add feature X" | Simplified requirements discovery |
| "Fix the bug in X" | qa-agent writes repro first → dev-agent fixes → regression test |
| "Change the style of X" | dev-agent edits + ui-critic reviews visuals |
| "X looks ugly" | ui-critic diagnoses first, then dispatches dev-agent |
| "X feels clunky to use" | ux-critic runs the UX checklist |
| "Run the tests" / "check for issues" | qa-agent runs E2E + records video |
| "Package / release / ship it" | integration-agent → delivery-agent produces a delivery bundle |
| "Summarize the feedback" | triage-agent classifies bugs / improvements / new requests |

**Zero interruption during development.** You only participate at the two endpoints: requirements discovery and delivery.

---

## What this kit solves

Out of the box, Claude Code tends to stumble mid- and late-project with:

- **Ugly UI** — Claude writes it without looking, no reference, ends up Bootstrap-flavored
- **Weak UX** — only happy path; missing loading/empty/error states; mobile breaks
- **Bug avalanches** — fixing A breaks B; "while I'm here" optimizations spawn new issues
- **Untrustworthy tests** — Claude claims "tests pass" while things are actually broken
- **Rhythm collapse** — asking for confirmation at every step; the user becomes the bottleneck
- **One-size-fits-all comms** — lecturing a beginner about React; explaining basics to an expert

Solutions baked in:

1. **Profile-driven communication** — detects beginner / non-technical / technical / expert and tunes jargon depth and decision rights
2. **Six-phase kickoff protocol** — profile detection + 5 questions + competitor research + HTML option page + A/B follow-ups + requirements bible
3. **Orchestrator-only main agent + 13 hard-bounded subagents** — each subagent has pinned responsibilities, permissions, and output format
4. **Independent review loop** — ui-critic / ux-critic / code-reviewer review in fresh contexts, blind to the coding process
5. **Evidence-based acceptance** — unit tests + E2E recordings + screenshots + Lighthouse all green before "done"
6. **Endpoint participation model** — you show up at requirements and delivery; AI drives the middle autonomously
7. **Feedback loop** — triage-agent categorizes, batched incremental delivery

---

## Repo layout

```
claude-code-archon/
├── .claude/                      ← ⭐ just copy this folder
│   ├── CLAUDE.md                  # Core rules (conversation routing + 9 iron rules + orchestrator rules)
│   ├── user-profile.md            # User profile (auto-filled on first conversation)
│   ├── playbooks/                 # Plays the main agent runs itself (multi-turn user dialog)
│   │   ├── kickoff.md               # Six-phase requirements discovery
│   │   └── platform-setup.md        # Auto-install test/dev toolchain per target platform
│   └── agents/                    # 13 subagents (closed one-shot tasks)
│       ├── dev-agent.md                 # Writes code
│       ├── react-dev-agent.md           # (example) React-stack specialist
│       ├── qa-agent.md                  # E2E tests
│       ├── ui-critic.md                 # Visual review
│       ├── ux-critic.md                 # Interaction review
│       ├── code-reviewer.md             # Code review
│       ├── integration-agent.md         # Packaging & deploy
│       ├── delivery-agent.md            # Delivery bundle
│       ├── triage-agent.md              # Feedback classification
│       ├── agent-creator.md             # Spawn new agents dynamically
│       ├── competitor-research-agent.md # Competitor research (used in kickoff phase 1)
│       ├── design-agent.md              # AI-self UI design (default, HTML+Tailwind output)
│       └── design-pencil-agent.md       # Pencil MCP design (produces .pen source files)
├── docs/                         ← Reference docs (no need to copy)
│   ├── architecture.md              # Architecture deep-dive
│   ├── project-templates/           # Optional project templates
│   │   ├── requirements.md            # Requirements bible template (kickoff fills this)
│   │   └── UX-checklist.md            # UX checklist
│   └── hooks-example/               # Optional pre-commit hooks
│       ├── settings-example.json
│       ├── check-commit-safety.sh
│       └── verify-deliverables.sh
├── README.md                     ← English (default, you're here)
├── README_zh.md                  ← 中文版
├── LICENSE / CHANGELOG / CONTRIBUTING
```

You only need to copy `.claude/`. Everything else is optional reference material.

---

## Dependencies: installed on demand

The kit detects your project's **target platform** and installs the required tools automatically — no manual wiring.

### Required during kickoff: Web automation (always)
- **Node.js + Playwright MCP** (needed by the kickoff wizard self-test and any Web project)
- Auto: `claude mcp add playwright -s user -- npx -y @playwright/mcp@latest`
- Pre-install: `npx playwright install chromium` (~150 MB)

### Installed per target platform (triggered after kickoff produces the requirements bible)

| Target platform | Auto-installed | Needs your hands |
|-----------------|----------------|------------------|
| **Web** | Playwright MCP | — |
| **Windows desktop** | WinAppDriver (winget) + Appium + appium-windows-driver | — |
| **Android** | Maestro (recommended) / Appium + uiautomator2 | Android Studio (guided link) |
| **iOS** (Mac) | Xcode CLI + Appium + xcuitest + Maestro | Full Xcode (App Store) |
| **Flutter** | — | Flutter SDK (brew / official site) |
| **Electron** | Playwright | — |
| **Tauri** | Rust toolchain (rustup) | — |

See `.claude/playbooks/platform-setup.md` for the complete flow.

**Prerequisite**: Node.js installed (`npx` available). If not, Claude will guide you to [nodejs.org](https://nodejs.org).

### Manual install (power users)

```bash
# Register MCP
claude mcp add playwright -s user -- npx -y @playwright/mcp@latest

# Pre-install browser
npx -y playwright install chromium
```

Or edit `~/.claude.json` / the project's `.mcp.json` by hand:
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

See [@playwright/mcp](https://github.com/microsoft/playwright-mcp) upstream.

---

## Optional: project hardening

If you want extra rigor, copy these too:

```bash
# Requirements bible template (kickoff-agent fills it in)
cp docs/project-templates/requirements.md <project>/docs/requirements.md

# UX checklist (ux-critic ticks this)
cp docs/project-templates/UX-checklist.md <project>/docs/UX-checklist.md

# pre-commit hook (block commits when lint/type/test fails)
cp docs/hooks-example/settings-example.json <project>/.claude/settings.json
cp docs/hooks-example/*.sh <project>/scripts/
chmod +x <project>/scripts/*.sh
```

It works without them — you just lose a safety net.

---

## Share it with others

### Public (GitHub)
```bash
cd claude-code-archon
git init && git add . && git commit -m "init"
gh repo create claude-code-archon --public --source=. --push
```

Others can then:
```bash
git clone https://github.com/<you>/claude-code-archon.git
cp -r claude-code-archon/.claude ~/.claude
# or drop into a project's .claude/
```

### Private (within a team)
```bash
gh repo create <org>/claude-kit --private --source=. --push
```

### Tarball
```bash
tar -czf claude-kit.tar.gz .claude docs README.md LICENSE
# send to a teammate
```

### Fork it into a team edition
Fork the repo, edit `.claude/CLAUDE.md` to inject company branding / conventions / internal agents, distribute your fork inside your team.

---

## Updating

```bash
# Pull latest
cd claude-code-archon
git pull

# Merge into deployed location (overwrite agent definitions, keep your user-profile.md)
cp -rn .claude/agents/* ~/.claude/agents/
cp .claude/CLAUDE.md ~/.claude/CLAUDE.md
# user-profile.md is left alone (unless you want to reset your profile)
```

---

## Customize & extend

### Add your own stack agent
Model it on `react-dev-agent.md`. Save to `~/.claude/agents/<stack>-dev-agent.md` or `<project>/.claude/agents/`.

### Add team-specific iron rules
Edit `~/.claude/CLAUDE.md` or the project's `CLAUDE.md`.

### Drop agents you don't need
Just delete files from `.claude/agents/`. Never doing frontend? Remove `ui-critic.md` / `ux-critic.md`.

---

## FAQ

**Q: Why not slash commands?**
A: Not beginner-friendly. Users should be able to say "I want to build X" and go, without memorizing commands. The "conversation routing" rules in CLAUDE.md let Claude infer intent.

**Q: Why no install script?**
A: You asked already. Copying a folder is simple enough; scripts add mental overhead.

**Q: Does it work without Playwright MCP?**
A: Yes, but ui-critic / ux-critic / qa-agent degrade to "read existing screenshots only" and can't generate fresh evidence. Strongly recommended to install.

**Q: My project already has a CLAUDE.md — now what?**
A: Merge. Append this kit's conversation routing + 9 iron rules to your CLAUDE.md, and merge `agents/` on top.

**Q: I'm an expert with my own workflow — is this useful to me?**
A: Cherry-pick. Copy just `kickoff-agent.md` + `ui-critic.md` + `ux-critic.md` if that's what you lack. The kit is a menu, not a set meal.

**Q: How does it relate to /metaskill / /metamemory / /metabot?**
A: Complementary. agent-creator uses /metaskill internally to generate new agents; feedback storage can live in /metamemory; distributed bot jobs go through /metabot.

---

## License

MIT — see [LICENSE](LICENSE).

Contributing: [CONTRIBUTING.md](CONTRIBUTING.md). Version history: [CHANGELOG.md](CHANGELOG.md). Architecture deep-dive: [docs/architecture.md](docs/architecture.md).
