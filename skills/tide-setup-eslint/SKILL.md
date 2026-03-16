---
name: tide:setup eslint
description: >
  One-time ESLint setup for Medusa admin. Bans raw HTML elements, adds accessibility rules.
  Triggers: "tide setup eslint", "setup linting", "configure eslint".
allowed-tools: Read, Write, Edit, Bash
---

# /tide:setup eslint — Component & Accessibility Linting

One-time setup. Installs ESLint with rules that ban raw HTML where Medusa UI components exist.

## Process

1. Install dependencies:
   ```bash
   yarn add -D eslint eslint-plugin-react eslint-plugin-jsx-a11y
   ```

2. Create or update `eslint.config.mjs` with:
   - `react/forbid-elements`: ban `<button>`, `<table>`, `<select>`, `<input>`, `<textarea>`
   - `jsx-a11y/alt-text`: require alt on images
   - `jsx-a11y/anchor-is-valid`: valid anchor usage
   - `jsx-a11y/click-events-have-key-events`: keyboard accessibility

3. Add script to package.json: `"lint:admin": "eslint src/admin/"`

4. Run lint to show current violations:
   ```bash
   npx eslint src/admin/ --max-warnings 0 2>&1 | head -40
   ```

5. Commit config
