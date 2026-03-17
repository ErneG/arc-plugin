---
name: tide:plan
description: >
  UX-aware feature planning. Explores existing UI first, then produces a plan with
  user flows, coherence checks, and concrete options (not questions). The plan that
  prevents "3 translation UIs" problems.
  Triggers: "tide plan", "plan feature", "plan this".
allowed-tools: Read, Write, Bash, Grep, Glob, Agent
---

# /tide:plan — UX-Aware Feature Planning

Plans a feature by understanding what ALREADY EXISTS before proposing anything new.
Produces plans with user flows, not just technical task lists.

## Arguments

- `<description>` — what the feature should do (from the user's perspective)

## Process

### Step 1: Set Up Feature State

```bash
FEATURE=$(cat .tide/active-feature 2>/dev/null)
mkdir -p .tide/features/$FEATURE
```

If no active feature, ask the user to run `/tide:start <name>` first.

### Step 2: Explore Existing UI

Spawn the **ux-explorer** agent to map what already exists:

```
Agent: ux-explorer
Task: Map the existing UI in the area related to: $ARGUMENTS
Output: .tide/features/$FEATURE/UX-MAP.md
```

This agent navigates the admin with agent-browser (if server running) and
reads source code to document all existing pages, widgets, routes, and models
in the feature area.

### Step 3: Plan with Coherence

Spawn the **planner** agent to create the implementation plan:

```
Agent: planner
Task: Create plan for: $ARGUMENTS
Input: UX-MAP.md, DECISIONS.md, CLAUDE.md
Output: .tide/features/$FEATURE/PLAN.md
```

The planner MUST:

- Present OPTIONS with recommendations (not questions)
- Include a complete User Flow section
- Include a Coherence Check section
- Describe what the user sees after each task
- Include empty/error/loading states

### Step 4: Coherence Review

Spawn the **coherence-checker** agent to validate the plan:

```
Agent: coherence-checker
Task: Review plan for coherence with existing UI
Input: PLAN.md, UX-MAP.md
Output: .tide/features/$FEATURE/COHERENCE.md
```

If verdict is FAIL:

- Show the user the findings
- Revise the plan to address coherence issues
- Re-run coherence check

### Step 5: Update State

```bash
# Set task count from plan
TASK_COUNT=$(grep -c "^### Task" .tide/features/$FEATURE/PLAN.md)
jq ".task.total = $TASK_COUNT | .phase = \"plan\" | .status = \"complete\"" \
  .tide/features/$FEATURE/STATE.json > tmp && mv tmp .tide/features/$FEATURE/STATE.json
```

### Step 6: Present to User

Show:

1. The recommended approach (from the planner's options)
2. The user flow (step by step what the user will experience)
3. The coherence check results
4. The task list with confidence levels
5. Any risks or trade-offs

Then ask: **"Does this plan look right? Run /tide:go to start building."**

## What Makes This Different

- **Explores before planning** — maps existing UI to prevent duplicates
- **User flows, not just tasks** — every task describes what the user sees
- **Coherence gate** — dedicated agent checks plan against existing product
- **Solutions, not questions** — presents options with recommendations
- **Empty/error/loading states** — included in every plan, not forgotten
