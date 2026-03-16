---
name: medusa-ui
description: >
  Medusa admin UI design reference. Load when building any admin pages, widgets,
  or components. Enforces correct component usage, visual hierarchy, and patterns.
  Triggers: building admin UI, creating pages, widgets, forms, tables.
allowed-tools: Read, Grep, Glob
---

# Medusa Admin UI Design Reference

Load this skill when building ANY admin UI. It prevents the #1 AI design problem:
using raw HTML/custom components instead of Medusa UI, and producing visually
incoherent interfaces.

## Available Components (@medusajs/ui)

### Layout: Container, Divider, Skeleton
### Typography: Heading (h1/h2/h3), Text, Code, CodeBlock
### Buttons: Button (primary/secondary/transparent/danger), IconButton, Copy
### Form: Input, Textarea, Select, Checkbox, RadioGroup, Switch, CurrencyInput, DatePicker, Label, Hint
### Data: Badge, StatusBadge, IconBadge, Avatar, Kbd, InlineTip, Alert
### Tables: DataTable (block), useDataTable, createDataTableColumnHelper, Table (low-level)
### Overlays: FocusModal, Drawer, Prompt (usePrompt), Tooltip, Popover, DropdownMenu, CommandBar
### Navigation: Tabs, ProgressTabs, ProgressAccordion
### Feedback: toast.success/error/info/warning, Toaster
### Utilities: clx (class merger), I18nProvider, TooltipProvider

## Design Tokens (Tailwind)

**Text**: text-ui-fg-base, text-ui-fg-subtle, text-ui-fg-muted, text-ui-fg-interactive, text-ui-fg-error
**Background**: bg-ui-bg-base, bg-ui-bg-subtle, bg-ui-bg-base-hover, bg-ui-bg-field
**Border**: border-ui-border-base, border-ui-border-strong, border-ui-border-interactive
**Typography**: txt-compact-small, txt-compact-small-plus, txt-compact-xsmall, txt-compact-medium-plus, txt-small, txt-small-plus, txt-medium
**Shadow**: shadow-elevation-flyout, shadow-elevation-modal

## Page Patterns (follow exactly)

### List Page
```tsx
<Container className="divide-y p-0">
  <DataTable instance={table}>
    <DataTable.Toolbar>
      <Heading level="h1">Items</Heading>
      <Text className="text-ui-fg-subtle txt-compact-small">{count} items</Text>
      <DataTable.Search />
      <Button size="small" variant="secondary" asChild>
        <Link to="create">Create</Link>
      </Button>
    </DataTable.Toolbar>
    <DataTable.Table />
    <DataTable.Pagination />
  </DataTable>
</Container>
```

### Create/Edit Form
```tsx
<Container className="divide-y p-0">
  <div className="flex items-center justify-between px-6 py-4">
    <Heading level="h1">Create Item</Heading>
    <div className="flex gap-2">
      <Button variant="secondary" onClick={cancel}>Cancel</Button>
      <Button variant="primary" onClick={save}>Save</Button>
    </div>
  </div>
  <SectionContainer title="General" description="Basic information">
    <div className="grid grid-cols-2 gap-4">
      <div><Label htmlFor="name">Name</Label><Input id="name" /></div>
      <div><Label htmlFor="code">Code</Label><Input id="code" /></div>
    </div>
  </SectionContainer>
</Container>
```

### Widget
```tsx
const MyWidget = ({ data }: DetailWidgetProps<AdminProduct>) => {
  return (
    <Container className="divide-y p-0">
      <div className="flex items-center justify-between px-6 py-4">
        <Heading level="h2">Widget Title</Heading>
      </div>
      <div className="px-6 py-4">
        {/* content */}
      </div>
    </Container>
  )
}

export const config = defineWidgetConfig({ zone: "product.details.side.after" })
```

## Visual Hierarchy Rules

1. **One H1 per page** — the page title. Sections use H2 via SectionContainer.
2. **Button prominence** — ONE primary button per view. Others are secondary/transparent.
3. **Action placement** — primary action top-right, destructive actions need confirmation (usePrompt).
4. **Empty states** — every list/table must show helpful message when empty, not blank page.
5. **Loading states** — every async page shows loading indicator.
6. **Error states** — every fetch handles errors with user-friendly message.
7. **Consistent spacing** — use Medusa's built-in spacing. No arbitrary px values.
8. **Color semantics** — green=success, red=error/danger, orange=warning, blue=info.

## What NEVER to Do

- Raw `<table>`, `<select>`, `<input type="checkbox">` — use Medusa components
- Custom modals with `position: fixed` — use FocusModal/Drawer
- `window.confirm()` or `alert()` — use usePrompt() and toast
- Arbitrary Tailwind colors — use design tokens (text-ui-fg-*, bg-ui-bg-*)
- Arbitrary font sizes — use typography classes (txt-compact-small, etc.)
- Multiple primary buttons in one view
- Missing empty/loading/error states

## Data Fetching

```tsx
// Reads
const { data, isLoading } = useQuery({ queryKey: ["items"], queryFn: () => sdk.client.fetch("/admin/items") })

// Writes
const { mutateAsync } = useMutation({ mutationFn: (body) => sdk.client.fetch("/admin/items", { method: "POST", body }) })

// Cache invalidation after write
queryClient.invalidateQueries({ queryKey: ["items"] })
```
