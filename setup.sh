#!/bin/bash

# ═══════════════════════════════════════════════════════════════
# SecureMail — Full Stack Setup Script (Mac/Linux)
# Usage: chmod +x setup.sh && ./setup.sh
# ═══════════════════════════════════════════════════════════════

REPO_URL="https://github.com/The-Team-Dream/SecureMail-Backend"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║         SecureMail Full Stack Setup          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# ── 1. Check Docker ─────────────────────────────────────────────
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi
echo "✅ Docker is running"
echo ""

# ── 2. Check all service folders exist ──────────────────────────
echo "🔍 Checking service folders..."
SERVICES=("SecureMail-Backend" "SecureMail-Frontend" "SecureMail-Ai" "SecureMail-Malware")
for SERVICE in "${SERVICES[@]}"; do
    if [ ! -d "$SERVICE" ]; then
        echo "❌ Missing folder: $SERVICE"
        echo "   Make sure you cloned all repositories inside this folder."
        exit 1
    fi
    echo "   ✅ $SERVICE"
done
echo ""

# ── 3. Create .env files from examples ──────────────────────────
echo "📄 Setting up environment files..."

[ ! -f .env ] && cp .env.example .env && echo "   ✅ Created root .env" || echo "   ℹ️  Root .env already exists"
[ ! -f SecureMail-Backend/.env.docker ]  && cp SecureMail-Backend/.env.docker.example  SecureMail-Backend/.env.docker  && echo "   ✅ Created SecureMail-Backend/.env.docker"  || echo "   ℹ️  SecureMail-Backend/.env.docker already exists"
[ ! -f SecureMail-Frontend/.env.docker ] && cp SecureMail-Frontend/.env.docker.example SecureMail-Frontend/.env.docker && echo "   ✅ Created SecureMail-Frontend/.env.docker" || echo "   ℹ️  SecureMail-Frontend/.env.docker already exists"
[ ! -f SecureMail-Ai/.env.docker ]       && cp SecureMail-Ai/.env.docker.example       SecureMail-Ai/.env.docker       && echo "   ✅ Created SecureMail-Ai/.env.docker"       || echo "   ℹ️  SecureMail-Ai/.env.docker already exists"
[ ! -f SecureMail-Malware/.env.docker ]  && cp SecureMail-Malware/.env.docker.example  SecureMail-Malware/.env.docker  && echo "   ✅ Created SecureMail-Malware/.env.docker"  || echo "   ℹ️  SecureMail-Malware/.env.docker already exists"

echo ""

# ── 4. Ask for DB Password ──────────────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  DATABASE SETUP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Enter a password for PostgreSQL."
echo "  Press Enter to use default: 0000"
echo ""
read -s -p "  PostgreSQL Password: " db_pass
echo ""

if [ -z "$db_pass" ]; then
    db_pass="0000"
    echo "  ⚠️  Using default password: 0000"
    echo "      (Not recommended for production)"
else
    echo "  ✅ Password set"
fi
echo ""

# ── 5. Write password into all relevant files ───────────────────
# Root .env → docker-compose.yml reads POSTGRES_PASSWORD from here
sed -i "s/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=${db_pass}/" .env

# Backend .env.docker → DATABASE_URL
sed -i "s|postgresql://postgres:.*@postgres|postgresql://postgres:${db_pass}@postgres|" SecureMail-Backend/.env.docker

echo "✅ Password written to root .env and SecureMail-Backend/.env.docker"
echo ""

# ── 6. Remind about optional secrets ────────────────────────────
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ⚠️  OPTIONAL SECRETS — Fill these later"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  SecureMail-Backend/.env.docker:"
echo "  📧 Gmail SMTP    → SMTP_PASSWORD"
echo "  🔐 Google OAuth  → GOOGLE_CLIENT_ID"
echo "                     GOOGLE_CLIENT_SECRET"
echo "  ☁️  Cloudinary    → CLOUDINARY_CLOUD_NAME"
echo "                     CLOUDINARY_API_KEY"
echo "                     CLOUDINARY_API_SECRET"
echo "  🛡️  AbuseIPDB     → ABUSEIPDB_API_KEY"
echo "  🔑 JWT           → JWT_SECRET"
echo "  🔒 Encryption    → ENCRYPTION_KEY"
echo ""
echo "  SecureMail-Ai/.env.docker:"
echo "  🤖 Groq LLM      → GROQ_API_KEY"
echo ""
echo "  📖 Full guide: $REPO_URL#readme"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
read -p "  Press Enter to start Docker..." _

# ── 7. Start Docker Compose ─────────────────────────────────────
echo ""
echo "🚀 Starting SecureMail Full Stack..."
echo "   (This may take a few minutes on first run)"
echo ""
docker compose down -v > /dev/null 2>&1
docker compose up --build -d

# ── 8. Wait for backend ─────────────────────────────────────────
echo ""
echo "⏳ Waiting for backend to be ready..."
RETRIES=30
until docker compose logs backend 2>&1 | grep -q "All migrations have been successfully applied"; do
    RETRIES=$((RETRIES - 1))
    if [ $RETRIES -eq 0 ]; then
        echo ""
        echo "❌ Backend failed to start. Check logs with:"
        echo "   docker compose logs backend"
        echo "   docker compose logs postgres"
        exit 1
    fi
    sleep 5
    echo "   still waiting..."
done

# ── 9. Done ─────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║          ✅ SecureMail is running!           ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Frontend: http://localhost:3001             ║"
echo "║  API:      http://localhost:3000             ║"
echo "║  Health:   http://localhost:3000/health      ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Logs:   docker compose logs -f backend      ║"
echo "║  Stop:   docker compose down                 ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
