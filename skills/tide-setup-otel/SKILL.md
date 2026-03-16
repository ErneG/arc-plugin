---
name: tide:setup otel
description: >
  Enable OpenTelemetry tracing with Jaeger. Gives Claude visibility into HTTP, workflow, query, and DB performance.
  Triggers: "tide setup otel", "setup tracing", "enable jaeger".
allowed-tools: Read, Write, Edit, Bash
---

# /tide:setup otel — OpenTelemetry + Jaeger

Enables request tracing, slow query detection, and workflow execution visibility.

## Process

1. Install dependency:
   ```bash
   yarn add @opentelemetry/exporter-trace-otlp-http
   ```

2. Create `src/instrumentation.ts`:
   ```typescript
   import { registerOtel } from "@medusajs/medusa"
   import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http"

   export function register() {
     const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://localhost:4318"
     registerOtel({
       serviceName: "medusa",
       exporter: new OTLPTraceExporter({ url: `${endpoint}/v1/traces` }),
       instrument: { http: true, workflows: true, query: true, db: true },
     })
   }
   ```

3. Verify Jaeger is in docker-compose (or add it):
   ```yaml
   jaeger:
     image: jaegertracing/all-in-one:latest
     ports:
       - "16686:16686"   # UI
       - "4318:4318"     # OTLP HTTP
   ```

4. Add to `.env`: `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`

5. Commit. View traces at http://localhost:16686
