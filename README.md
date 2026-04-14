# SecureMail Monorepo

Welcome to the **SecureMail** project, an encrypted mail experience featuring automated security analysis, unified microservices, and multi-platform clients.

## 🏗️ Architecture Overview

The system consists of five main components coordinated as a unified monorepo:

- **SecureMail-Backend**: NestJS REST API (Auth, Mailboxes, Pipeline).
- **SecureMail-Ai**: Python gRPC service for AI-powered email analysis (Groq + LangChain).
- **SecureMail-Malware**: Go gRPC service for file scanning.
- **SecureMail-Frontend**: Next.js (React) management dashboard.
- **SecureMail-Flutter**: Mobile client for iOS, Android, and Web.

---

## 🚀 Getting Started (Run Everything Together)

There are two primary ways to run the full stack:

### Method A: Turborepo (Recommended for Development)
High-performance parallel orchestration of all services in a single terminal.

1. **Start Infrastructure**:
   ```bash
   docker compose up -d postgres redis
   ```
2. **Launch All Services**:
   ```bash
   npm run dev  # Or pnpm dev
   ```
   *Available Filters:*
   - `npm run dev:api`: Runs only Backend + AI + Malware.
   - `npm run dev:ui`: Runs only the Frontend.

### Method B: Docker Compose (Production-Like)
Ideal for testing the entire environment with container isolation.

```bash
docker compose up --build
```
> [!IMPORTANT]
> Ensure you have configured your `.env` from `.env.docker.example` at the root.

---

## 🛠️ Individual Service Execution

If you wish to run a specific service manually for debugging:

| Service | Manual Command | Default Port |
|---------|----------------|--------------|
| **Backend** | `npm run start:dev` (in Backend folder) | `3000` |
| **Frontend** | `npm run dev` (in Frontend folder) | `3001` |
| **AI Agent** | `python app/main.py` (in AI folder) | `50051` |
| **Malware** | `go run main.go` (in Malware folder) | `50052` |
| **Flutter** | `flutter run` (in Flutter folder) | - |

---

## 🔗 Internal Wiring & URLs

| What | URL |
|------|-----|
| **REST API + Swagger** | http://localhost:3000/api/docs |
| **Web Dashboard** | http://localhost:3001 |
| **Flutter Web** | http://localhost:8080 (via Docker) |
| **Postgres** | `localhost:5432` |
| **Redis** | `localhost:6379` |

---

## 📄 Sub-Project Documentation

For deep dives into configuration and requirements, see individual READMEs:
- [Backend Documentation](./SecureMail-Backend/README.md)
- [AI Service Documentation](./SecureMail-Ai/README.md)
- [Malware Service Documentation](./SecureMail-Malware/README.md)
- [Frontend Documentation](./SecureMail-Frontend/README.md)
- [Flutter Documentation](./SecureMail-Flutter/README.md)
- [Contracts Documentation](./contracts/README.md)
