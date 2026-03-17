---
name: tide:go
description: >
  Approve plan and start the implement → verify → review loop. Each task gets a
  fresh agent session. Low-confidence tasks pause for human review.
  Triggers: "tide go", "approve plan", "start implementing".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Agent
---

# /tide:go — Execute Plan

Approve the plan and run the implementation loop.

## Pre-checks

1. Read `.tide/active-feature` and load STATE.json
2. Verify `phase == "plan"` and `status == "complete"`
3. Verify PLAN.md and COHERENCE.md exist
4. If COHERENCE.md verdict is FAIL, block and show findings

## Execution Loop

For each task in PLAN.md:

### 1. Confidence Gate

Read the task's **Confidence** field:

- **high/medium**: auto-proceed
- **low**: pause and show the task to the user. Wait for `/tide:go` to continue.

### 2. TDD: Write Failing Tests (if applicable)

Spawn **test-writer** agent (cannot read src/):

- Reads acceptance criteria from PLAN.md
- Writes failing tests
- Commits them

Skip for UI-only tasks or config changes.

### 3. Implement

Spawn **executor** agent (fresh context):

- Reads PROGRESS.md, PLAN.md, DECISIONS.md
- Makes failing tests pass (or implements from plan if no tests)
- Runs tsc + tests
- Commits

### 4. Update Progress

Run `write-progress.sh` to update PROGRESS.md for the next fresh session.

### 5. Repeat for next task

## After All Tasks: Verify

Spawn **verifier** agent:

- Type-check
- Tests (with --onlyFailures retry)
- UX verification with agent-browser (follows plan's User Flow)

If verification fails: spawn executor to fix, then re-verify (max 3 iterations).

## After Verify: Review

Spawn **reviewer** agent:

- Logic, security, conventions, UX coherence
- If CHANGES_NEEDED: spawn executor to fix, re-verify, re-review (max 2 cycles)

## When Complete

```
[tide] All tasks implemented, verified, and reviewed!
  Next: /tide:ship to push and create PR
```
