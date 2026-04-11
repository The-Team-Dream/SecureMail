# SecureMail

Monorepo for **SecureMail**: encrypted mail UX with security analysis, multi-client apps, and a NestJS API.

## Architecture overview

```
┌─────────────┐     HTTPS/REST    ┌──────────────────┐
│  Frontend   │ ────────────────► │  Backend (Nest)  │
│  (Next.js)  │                   │  Port 3000       │
└─────────────┘                   └────────┬─────────┘
                                           │
       ┌───────────────────────────────────┼───────────────────────┐
       │ gRPC                              │ SQL      Redis        │
       ▼                                   ▼          ▼              │
┌─────────────┐                    ┌──────────┐  ┌────────┐          │
│ SecureMail  │                    │ Postgres │  │ Redis  │          │
│ AI (Python) │                    │ :5432    │  :6379  │          │
│ :50051      │                    └──────────┘  └────────┘          │
└─────────────┘                                                      │
                                                                     │
┌─────────────┐     HTTPS/REST (same API as web)                     │
│  Flutter    │ ─────────────────────────────────────────────────────┘
│  (iOS/Android/Web) │
└────────────────────┘
```

| Component | Role |
|-----------|------|
| **SecureMail-Backend** | REST API, auth, mailboxes, security pipeline, Swagger/OpenAPI |
| **SecureMail-Ai** | gRPC AI analysis (`GenerateReport`); Groq + LangChain |
| **SecureMail-Frontend** | Next.js web app |
| **SecureMail-Flutter** | Mobile/desktop/web client (Dio, Riverpod, etc.) |
| **contracts/ai-agent.proto** | Shared gRPC contract (source of truth for AI) |

## One-command run (Docker Compose)

From the **repository root** (where `docker-compose.yml` lives):

```bash
cp .env.docker.example .env
# Edit .env: set JWT_SECRET (required for auth); GROQ_API_KEY (required for AI reports to work)

docker compose up --build
```

### Services, ports, and wiring

| Service | Port(s) | Purpose |
|---------|---------|---------|
| **postgres** | `5432` | Database (`securemail` / `securemail`) |
| **redis** | `6379` | Queues / cache (BullMQ, etc.) |
| **ai** | `50051` (internal; not published by default) | gRPC AI agent |
| **backend** | `3000` | HTTP API + Swagger |
| **frontend** | `3001` → container `3000` | Next.js production server |

**Networking**

- **backend → postgres:** `DATABASE_URL` uses hostname `postgres`.
- **backend → redis:** `REDIS_HOST=redis`.
- **backend → ai:** `AI_AGENT_GRPC_URL=ai:50051` (Docker DNS service name `ai`).
- **frontend → backend:** Browser calls `NEXT_PUBLIC_API_URL` (default `http://localhost:3000`). CORS uses `FRONTEND_URL` (default `http://localhost:3001`).

### Optional: Flutter Web (static build + nginx)

```bash
docker compose --profile flutter up --build
```

Serves the Flutter **web** build on **http://localhost:8080** (see `SecureMail-Flutter/README.md`).

## URLs (default local Compose)

| What | URL |
|------|-----|
| REST API base | http://localhost:3000 |
| **Swagger UI** | http://localhost:3000/api/docs |
| **OpenAPI JSON** | http://localhost:3000/api/docs-json |
| Web app | http://localhost:3001 |
| Flutter web (optional profile) | http://localhost:8080 |
| Postgres | `localhost:5432` |
| Redis | `localhost:6379` |

## API documentation for client developers

- **Interactive docs:** open **Swagger UI** at `/api/docs` (try requests, copy `curl`).
- **Machine-readable spec:** `GET /api/docs-json` — use for:
  - **TypeScript / Next:** [openapi-typescript](https://github.com/drwpow/openapi-typescript) or [orval](https://orval.dev/).
  - **Flutter/Dart:** [openapi_generator](https://pub.dev/packages/openapi_generator) or import the JSON into your generator of choice.
- **Auth in Swagger:** click **Authorize**, paste `Bearer <access_token>` from `POST /auth/login` or `POST /auth/verify-2fa`.
- **Response contract:** success payloads are wrapped as `{ success, message, data }`; errors as `{ success: false, statusCode, message, errors, path, timestamp }` (see Swagger description block).

## Production notes

- Replace default `JWT_SECRET` and database credentials; use TLS in front of backend and frontend.
- Set `GROQ_API_KEY` on the **ai** service or AI analysis will fail at runtime.
- Point `NEXT_PUBLIC_API_URL` and `FRONTEND_URL` at your public URLs when deploying.
- **Malware gRPC** is optional (`MALWARE_ENGINE_GRPC_URL`); pipeline degrades gracefully if the engine is unreachable.

## Per-package docs

- [SecureMail-Backend](./SecureMail-Backend/README.md)
- [SecureMail-Ai](./SecureMail-Ai/README.md)
- [SecureMail-Frontend](./SecureMail-Frontend/README.md)
- [SecureMail-Flutter](./SecureMail-Flutter/README.md)

## Can everything run together?

**Yes.** `docker compose up --build` starts **postgres**, **redis**, **ai**, **backend**, and **frontend** with compatible defaults. Blockers are only **configuration**: you must set a real **`JWT_SECRET`** for production-like auth, and **`GROQ_API_KEY`** if you need AI-generated reports (without it the AI container may start but analysis calls fail).
