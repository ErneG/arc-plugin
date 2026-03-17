# Tide Generic Variant

Framework-agnostic version of Tide for use with any project. Strips out all
Medusa, Neon, and Coolify-specific functionality while keeping the core
autonomous development workflow.

## What's Different from the Default Variant

### Removed (Medusa-specific)
- **Business logic guard hook** — Medusa money fields, workflow composition, ledger rules
- **Single hook handler guard** — Medusa workflow hook file enforcement
- **Admin UI lint hook** — Medusa UI component pattern checks
- **Module integrity verifier** — `medusa-config.ts` / `MODULE_NAMES.ts` cross-reference
- **Route validation checker** — Medusa `validatedBody` / zod schema checks
- **Data integrity checker** — Medusa-specific SQL checks
- **Scaffold skill** — Medusa module/route/widget/link/page generation
- **Medusa UI skill** — `@medusajs/ui` component reference
- **UI enforcer agent** — Medusa component compliance checking

### Removed (Neon-specific)
- **Neon DB branching** — automatic branch creation/deletion on worktree lifecycle
- Neon configuration in `config.json` and `STATE.json`

### Changed
- **Worktree hooks** — generic .env copying, auto-detect package manager (yarn/pnpm/npm)
- **DB branching** — configurable via `db.branch_command` / `db.cleanup_command` in config
- **Verifier agent** — gates: typecheck → lint → tests → browser (no modules/routes gates)
- **Deploy skill** — generic CI/CD (no Coolify references), just merges PR + health check
- **Browser verify** — no `--profile ~/.medusa-admin`, no `/health` endpoint assumption
- **TDD skill** — generic test patterns, no Medusa test runner templates
- **ESLint setup** — generic a11y rules, no Medusa component banning
- **OTel setup** — standard OpenTelemetry SDK, not Medusa's `registerOtel`
- **Default port** — 3000 instead of 9000

### Unchanged (already generic)
- Core workflow: `/tide:start` → `/tide:plan` → `/tide:go` → `/tide:ship`
- Planner, executor, reviewer, test-writer agents
- Coherence checker (generalized for any project)
- UX explorer (generalized for any project)
- Quality sentinel, semgrep scan, typecheck-on-edit hooks
- Rework tracking, progress writing scripts
- Design rules skill
- Setup skills: a11y, postgres-mcp, debugger-mcp

## Install

```bash
# Load the generic variant instead of the default
claude --plugin-dir ~/path/to/tide/variants/generic
```

## Project Setup

Create `.tide/config.json` in your project:

```json
{
  "db_strategy": "none",
  "deploy": {
    "health_url": "https://your-app.com/health"
  }
}
```

### Optional: DB Branching

If your database supports branching (e.g., PlanetScale, Neon, Supabase branching):

```json
{
  "db_strategy": "custom",
  "db": {
    "branch_command": "your-cli branch create $TIDE_DB_BRANCH",
    "cleanup_command": "your-cli branch delete $TIDE_DB_BRANCH"
  }
}
```

Environment variables available to DB commands:
- `TIDE_WORKTREE_NAME` — the worktree name
- `TIDE_DB_BRANCH` — suggested branch name (`wt/<worktree-name>`)
- `TIDE_WORKTREE_PATH` — absolute path to the worktree

### Optional: Custom Install Command

```json
{
  "install_command": "pnpm install --frozen-lockfile"
}
```

If not set, the hook auto-detects from lock files (yarn.lock → yarn, pnpm-lock.yaml → pnpm, default → npm).

## Prerequisites

- [agent-browser](https://github.com/vercel-labs/agent-browser) — `npm i -g agent-browser && agent-browser install`
- [semgrep](https://semgrep.dev/) — `brew install semgrep` (for security scanning)
- [jq](https://jqlang.github.io/jq/) — `brew install jq`

## Commands

| Command | What it does |
|---------|-------------|
| `/tide:start <name>` | Create worktree + env setup |
| `/tide:plan <description>` | UX-aware planning with coherence check |
| `/tide:go` | Approve plan, start implement → verify → review loop |
| `/tide:verify` | Standalone verification (typecheck + lint + tests + browser) |
| `/tide:ship` | Push + create PR with metrics |
| `/tide:deploy` | Merge PR + health check |
| `/tide:teardown <name>` | Clean up worktree |
| `/tide:status` | Show feature progress |
| `/tide:metrics` | Rework rate + cost summary |
| `/tide:fix <desc>` | Quick fix without full pipeline |
