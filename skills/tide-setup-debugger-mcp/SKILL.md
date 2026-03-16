---
name: tide:setup debugger-mcp
description: >
  Add Node.js debugger MCP for breakpoints and variable inspection.
  Triggers: "tide setup debugger", "add debugger", "setup node debugging".
allowed-tools: Read, Write, Edit, Bash
---

# /tide:setup debugger-mcp — Node.js Debugging Tools

Adds @hyperdrive-eng/mcp-nodejs-debugger for runtime debugging.

## Process

1. Add to `.mcp.json`:
   ```json
   {
     "mcpServers": {
       "nodejs-debugger": {
         "command": "npx",
         "args": ["@hyperdrive-eng/mcp-nodejs-debugger"]
       }
     }
   }
   ```

2. To use, start Medusa with inspect flag:
   ```bash
   node --inspect ./node_modules/.bin/medusa develop
   ```

## What it enables

- Set breakpoints in running code
- Inspect variable values at breakpoints
- Step through execution (step in/over/out)
- Evaluate expressions in paused context
- Conditional breakpoints
