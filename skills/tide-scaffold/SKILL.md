---
name: tide:scaffold
description: >
  Generate Medusa v2 boilerplate with correct patterns. Prevents forgotten registration,
  missing middleware, and inconsistent patterns.
  Sub-commands: module, route, widget, link, page.
  Triggers: "tide scaffold", "scaffold module", "generate module", "create module boilerplate".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# /tide:scaffold — Code Generation

Generates boilerplate following the exact patterns from the codebase.
All generated code includes MODULE_NAMES registration, medusa-config entry,
middleware wiring, and proper Medusa UI components.

## Sub-commands

### `/tide:scaffold module <name>`

Generates a complete module with all registrations.

**Files created:**
- `src/modules/<name>/models/<name>.ts` — model with `model.define()`
- `src/modules/<name>/service.ts` — service extending `MedusaService`
- `src/modules/<name>/index.ts` — module export with `Module()`

**Files modified:**
- `src/shared/MODULE_NAMES.ts` — add `export const <NAME>_MODULE = "<name>"`
- `medusa-config.ts` — add `{ resolve: "./src/modules/<name>" }` to modules array

**Then run:**
```bash
npx medusa db:generate <name>
npx medusa db:migrate
```

**Naming conventions:**
- Directory: `src/modules/<name>/` (kebab-case)
- Model table: `<name>` in `model.define()` (snake_case)
- Service class: `<Name>ModuleService` (PascalCase)
- MODULE_NAMES constant: `<NAME>_MODULE` (UPPER_SNAKE)
- Module string value: `"<name>"` (snake_case)

### `/tide:scaffold route <module> <admin|store>`

Generates CRUD routes with zod validation.

**Files created:**
- `src/api/<scope>/<plural>/route.ts` — GET (list) + POST (create)
- `src/api/<scope>/<plural>/[id]/route.ts` — GET (detail) + POST (update) + DELETE

**Files modified:**
- `src/api/middlewares.ts` — add zod schemas + validation middleware entries

**Pattern:** Uses `query.graph()` for reads, service methods for writes.
GET list supports `?q=` search, pagination via `limit`/`offset`.

### `/tide:scaffold widget <module> <zone>`

Generates a widget with Medusa UI patterns.

**File created:**
- `src/admin/widgets/<module>-widget.tsx`

**Pattern:** Container + divide-y p-0, useQuery, loading state, proper zone config.

**Valid zones:** `product.details.side.after`, `product.details.after`,
`order.details.side.after`, `customer.details.side.after`,
`product_variant.details.after`, `product_category.details.after`,
`inventory_item.details.after`

### `/tide:scaffold link <moduleA> <moduleB>`

Generates a module link with defineLink.

**File created:**
- `src/links/<moduleA>-<moduleB>.ts`

**Pattern:** Uses `.linkable.<entity>` from both modules. Warns to update
workflow hook handlers if they exist.

### `/tide:scaffold page <module>`

Generates admin list + create pages with DataTable pattern.

**Files created:**
- `src/admin/routes/<plural>/page.tsx` — list with DataTable, search, pagination
- `src/admin/routes/<plural>/create/page.tsx` — create form with SectionContainer

**Pattern:** useQuery + sdk.client.fetch, DataTable with columnHelper,
onRowClick navigation, proper loading/empty states, route config with icon.

## Process (for any sub-command)

1. Validate arguments
2. Read CLAUDE.md for conventions
3. Read the closest existing example for pattern reference:
   - Module: read `src/modules/manufacturer/`
   - Route: read `src/api/admin/manufacturers/`
   - Widget: read `src/admin/widgets/manufacturer-widget.tsx`
   - Page: read `src/admin/routes/manufacturers/page.tsx`
4. Generate files using the patterns from the reference
5. Modify registration files (MODULE_NAMES, medusa-config, middlewares)
6. Run `npx tsc --noEmit` to verify
7. Commit all generated files

## Rules

- ALWAYS read the existing reference implementation before generating
- ALWAYS register new modules in both MODULE_NAMES.ts AND medusa-config.ts
- ALWAYS add zod validation for POST/PUT routes
- Money fields use `model.bigNumber()`, never `model.number()`
- Use `@medusajs/ui` components in all admin pages — never raw HTML
- Every list page needs empty state, every form needs loading state
- Query MCP for Medusa patterns if unsure about anything
