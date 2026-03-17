---
name: tide:setup eslint
description: >
  One-time ESLint setup with accessibility rules.
  Triggers: "tide setup eslint", "setup linting", "configure eslint".
allowed-tools: Read, Write, Edit, Bash
---

# /tide:setup eslint — Linting & Accessibility

One-time setup. Installs ESLint with accessibility rules.

## Process

1. Detect package manager and install dependencies:
   ```bash
   # Detect package manager
   if [[ -f pnpm-lock.yaml ]]; then
     pnpm add -D eslint eslint-plugin-react eslint-plugin-jsx-a11y
   elif [[ -f yarn.lock ]]; then
     yarn add -D eslint eslint-plugin-react eslint-plugin-jsx-a11y
   else
     npm install -D eslint eslint-plugin-react eslint-plugin-jsx-a11y
   fi
   ```

2. Create or update `eslint.config.mjs` with:
   - `jsx-a11y/alt-text`: require alt on images
   - `jsx-a11y/anchor-is-valid`: valid anchor usage
   - `jsx-a11y/click-events-have-key-events`: keyboard accessibility

3. Add script to package.json: `"lint": "eslint src/"`

4. Run lint to show current violations:
   ```bash
   npx eslint src/ --max-warnings 0 2>&1 | head -40
   ```

5. Commit config
