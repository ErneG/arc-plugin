---
name: tide:setup otel
description: >
  Enable OpenTelemetry tracing with Jaeger. Gives visibility into HTTP, query, and performance.
  Triggers: "tide setup otel", "setup tracing", "enable jaeger".
allowed-tools: Read, Write, Edit, Bash
---

# /tide:setup otel — OpenTelemetry + Jaeger

Enables request tracing, slow query detection, and execution visibility.

## Process

1. Install dependencies:
   ```bash
   npm install @opentelemetry/api @opentelemetry/sdk-node @opentelemetry/exporter-trace-otlp-http @opentelemetry/auto-instrumentations-node
   ```

2. Create `src/instrumentation.ts`:
   ```typescript
   import { NodeSDK } from "@opentelemetry/sdk-node"
   import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http"
   import { getNodeAutoInstrumentations } from "@opentelemetry/auto-instrumentations-node"

   const endpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || "http://localhost:4318"

   const sdk = new NodeSDK({
     serviceName: process.env.OTEL_SERVICE_NAME || "app",
     traceExporter: new OTLPTraceExporter({ url: `${endpoint}/v1/traces` }),
     instrumentations: [getNodeAutoInstrumentations()],
   })

   sdk.start()
   ```

3. Add Jaeger to docker-compose (or verify it exists):
   ```yaml
   jaeger:
     image: jaegertracing/all-in-one:latest
     ports:
       - "16686:16686"   # UI
       - "4318:4318"     # OTLP HTTP
   ```

4. Add to `.env`: `OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318`

5. Commit. View traces at http://localhost:16686
