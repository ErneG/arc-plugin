---
name: tide:setup a11y
description: >
  Add accessibility testing with axe-core + Playwright. Catches WCAG violations automatically.
  Triggers: "tide setup a11y", "setup accessibility", "add a11y tests".
allowed-tools: Read, Write, Bash
---

# /tide:setup a11y — Accessibility Testing

Adds @axe-core/playwright for automated WCAG 2.1 AA compliance checking.

## Process

1. Install:
   ```bash
   yarn add -D @axe-core/playwright
   ```

2. Create `e2e/helpers/check-a11y.ts`:
   ```typescript
   import AxeBuilder from "@axe-core/playwright"
   import { Page, expect } from "@playwright/test"

   export async function checkA11y(page: Page, path: string) {
     await page.goto(path)
     await page.waitForLoadState("networkidle")
     const results = await new AxeBuilder({ page })
       .withTags(["wcag2a", "wcag2aa"])
       .analyze()
     expect(results.violations).toEqual([])
   }
   ```

3. Create example test `e2e/a11y/admin-pages.spec.ts`:
   ```typescript
   import { test } from "@playwright/test"
   import { checkA11y } from "../helpers/check-a11y"

   const pages = ["/app", "/app/products", "/app/orders"]
   for (const path of pages) {
     test(`${path} has no a11y violations`, async ({ page }) => {
       await checkA11y(page, path)
     })
   }
   ```

4. Commit

Note: agent-browser can also run axe-core via `eval` for quick checks
without needing a full test suite. See `scripts/browser-verify.sh`.
