---
name: tdd
description: >
  Test-driven development cycle: RED (write failing test) → GREEN (minimal implementation) → REFACTOR.
  Use for module services, API routes, and workflows. Prevents "vibe testing" where AI writes tests
  that pass trivially. Triggers: "tdd", "test first", "write test then implement", "red green refactor".
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---

# /tdd — Test-Driven Development

Enforces RED-GREEN-REFACTOR cycle. The test is written FIRST, verified to FAIL, then implementation
makes it pass. This prevents the #1 AI testing anti-pattern: writing tests that mirror implementation
assumptions rather than verifying behavior.

## Arguments

- `<description>` — what to test (e.g., "manufacturer CRUD operations", "discount validation")

## Process

### Phase 1: RED — Write a Failing Test

1. **Read the plan/requirements** for what needs to be tested
2. **Read existing test patterns** in the codebase:
   - Module tests: `integration-tests/modules/` using `moduleIntegrationTestRunner`
   - HTTP tests: `integration-tests/http/` using `medusaIntegrationTestRunner`
3. **Write ONE test file** following existing patterns
4. **Run the test** — it MUST fail:

   ```bash
   # For module tests
   yarn test:integration:modules -- --testPathPattern="<test-file>"

   # For HTTP tests
   yarn test:integration:http -- --testPathPattern="<test-file>"
   ```

5. **Verify failure is for the RIGHT reason** — missing function, not syntax error
6. **Commit the failing test**:
   ```bash
   git add <test-file>
   git commit -m "test(<scope>): add failing test for <description>"
   ```

### Phase 2: GREEN — Minimal Implementation

1. **Write the minimum code** to make the test pass — nothing more
2. **Do NOT add features** the test doesn't verify
3. **Run the test** — it MUST pass now:
   ```bash
   yarn test:integration:modules -- --testPathPattern="<test-file>"
   ```
4. **Commit the implementation**:
   ```bash
   git add <source-files>
   git commit -m "feat(<scope>): implement <description>"
   ```

### Phase 3: REFACTOR (Optional)

1. Only if the GREEN code is messy or duplicated
2. **Run tests after refactoring** — they must still pass
3. **Commit the refactor**:
   ```bash
   git add <files>
   git commit -m "refactor(<scope>): clean up <description>"
   ```

### Repeat

Go back to Phase 1 for the next test case. One test at a time.

## Test Quality Rules

- **Assert behavior, not implementation** — test what the function DOES, not HOW it does it
- **No assertion-free tests** — every test must have at least one `expect()` call
- **No testing private internals** — test through the public API/service interface
- **Test edge cases** — empty inputs, nulls, duplicates, boundary values
- **Independent tests** — each test must work in isolation, no shared mutable state

## Anti-Patterns to Avoid

- Writing a test that ALREADY passes (defeats the purpose — the test might be trivially true)
- Writing all tests at once then implementing (loses the RED-GREEN feedback loop)
- Copying implementation logic into test assertions (tautological testing)
- Mocking the database (project rule: use real test runners with real Postgres)
- Lowering coverage thresholds to pass CI

## When to Use TDD vs Test-After

| Scenario                      | Approach                                   |
| ----------------------------- | ------------------------------------------ |
| New module service            | TDD (this skill)                           |
| New API route                 | TDD (this skill)                           |
| New workflow                  | TDD (this skill)                           |
| Admin UI component            | Test-after with agent-browser              |
| Bug fix                       | TDD — write test that reproduces bug first |
| Refactoring                   | Ensure existing tests pass, then refactor  |
| Config/infrastructure changes | No tests needed                            |

## Medusa-Specific Patterns

### Module test template

```typescript
import { moduleIntegrationTestRunner } from "@medusajs/test-utils";
import { MODULE_NAME } from "../../src/shared/MODULE_NAMES";

moduleIntegrationTestRunner({
  moduleName: MODULE_NAME,
  testSuite: ({ service }) => {
    describe("<ModuleName>", () => {
      it("should create a <entity>", async () => {
        const result = await service.create<Entity>({ name: "test" });
        expect(result).toBeDefined();
        expect(result.name).toBe("test");
      });
    });
  },
});
```

### HTTP test template

```typescript
import { medusaIntegrationTestRunner } from "@medusajs/test-utils";

medusaIntegrationTestRunner({
  testSuite: ({ api, getContainer }) => {
    describe("GET /admin/<route>", () => {
      it("should return 200", async () => {
        const response = await api.get("/admin/<route>", adminHeaders);
        expect(response.status).toBe(200);
      });
    });
  },
});
```
