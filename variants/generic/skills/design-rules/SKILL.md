---
name: design-rules
description: >
  UI/UX design rules for admin dashboards. Prevents "AI slop" — generic interfaces with
  flat hierarchy, missing states, and inconsistent spacing. Load alongside medusa-ui skill
  when building any admin interface.
  Triggers: building UI, designing pages, creating components, fixing design issues.
allowed-tools: Read, Grep, Glob
---

# Admin Dashboard Design Rules

These rules prevent the #1 AI design failure: generating technically correct but
visually incoherent interfaces. Follow these when building ANY admin UI.

## Philosophy

- You build a SPECIFIC admin interface that must feel cohesive with the existing app
- Every UI decision serves the USER'S TASK, not your technical capability
- When uncertain, choose simpler. Less is more.
- Treat every generation as a first draft. State what you built and why.

## Anti-Slop Rules (mandatory)

- NEVER use purple-to-blue gradients unless the design system specifies them
- NEVER create card-heavy layouts when a simple list or table would suffice
- NEVER add decorative elements without functional purpose
- NEVER use generic placeholder text ("Lorem ipsum", "Description here")
- NEVER build without empty, loading, and error states
- NEVER create custom components that duplicate existing UI library exports
- NEVER use arbitrary colors/fonts — always use design tokens

## Visual Hierarchy

- Page title is the largest text element (one per page)
- Section titles clearly smaller than page title
- ONE primary action per view. Secondary actions use muted variants.
- Status uses semantic colors: green=success, red=danger, orange=warning, grey=inactive, blue=info
- Admin dashboards should be DENSE, not spacious. Avoid excessive whitespace.
- Most important information appears FIRST (top-left in LTR layouts)

## 8 Mandatory States

Every interactive component MUST handle:

1. **LOADING** — skeleton matching content shape, never blank space
2. **EMPTY** — centered message with icon + action to create first item
3. **ERROR** — alert with meaningful message and retry action
4. **SUCCESS** — brief toast confirmation
5. **DESTRUCTIVE** — confirmation dialog before delete/archive
6. **DISABLED** — greyed out with tooltip explaining why
7. **HOVER** — visual feedback on all clickable elements
8. **FOCUS** — keyboard navigation must work

## Data Presentation

- Tables: always show row count in header ("24 items")
- Tables: rows clickable for navigation to detail view
- Tables: search when >10 items, pagination when >20
- Tables: empty search state ("No results for 'query'")
- Forms: label above input, help text below
- Forms: validate on blur, not on change
- Forms: inline error messages, not just toast
- Detail pages: primary info at top, secondary in sections below
- Numbers: right-align in tables, locale-aware formatting
- Dates: relative display ("2h ago") with absolute in tooltip
- Long text: truncate with ellipsis, full in tooltip

## Accessibility

- All icon-only buttons need tooltip labels
- Color NEVER the only indicator — pair with text/icon
- Minimum contrast: 4.5:1 normal text, 3:1 large text
- Focus order follows visual order
- Form errors announced to screen readers
- Animations respect prefers-reduced-motion

## Design Process

1. BEFORE coding: state user persona, their goal, and the happy path
2. List which UI components you'll use and why
3. Identify edge cases (empty, error, loading, permissions)
4. Build happy path first
5. Add all 8 states
6. Screenshot and self-review if browser available
7. Ask user to review before moving on

## The Three Principles

1. **Constrain, don't prescribe** — design principles + component constraints > pixel specifications
2. **Close the visual loop** — screenshot your own output, compare to existing pages, iterate
3. **Persist decisions** — design choices must survive across sessions via design system files
