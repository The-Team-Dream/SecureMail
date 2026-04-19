@echo off
chcp 65001 > nul

:: ═══════════════════════════════════════════════════════════════
:: SecureMail — Full Stack Setup Script (Windows)
:: Usage: Double-click setup.bat OR run in terminal
:: ═══════════════════════════════════════════════════════════════

set REPO_URL=https://github.com/The-Team-Dream/SecureMail-Backend

echo.
echo +================================================+
echo ^|        SecureMail Full Stack Setup            ^|
echo +================================================+
echo.

:: ── 1. Check Docker ────────────────────────────────────────────
docker info > nul 2>&1
if errorlevel 1 (
    echo [ERROR] Docker is not running. Please start Docker Desktop first.
    pause
    exit /b 1
)
echo [OK] Docker is running
echo.

:: ── 2. Check all service folders exist ─────────────────────────
echo [CHECK] Checking service folders...
for %%S in (SecureMail-Backend SecureMail-Frontend SecureMail-Ai SecureMail-Malware) do (
    if not exist %%S (
        echo [ERROR] Missing folder: %%S
        echo         Make sure you cloned all repositories inside this folder.
        pause
        exit /b 1
    )
    echo        [OK] %%S
)
echo.

:: ── 3. Create .env files from examples ─────────────────────────
echo [SETUP] Setting up environment files...

if not exist .env (
    copy .env.example .env > nul
    echo        [OK] Created root .env
) else (
    echo        [INFO] Root .env already exists
)

if not exist SecureMail-Backend\.env.docker (
    copy SecureMail-Backend\.env.docker.example SecureMail-Backend\.env.docker > nul
    echo        [OK] Created SecureMail-Backend\.env.docker
) else (
    echo        [INFO] SecureMail-Backend\.env.docker already exists
)

if not exist SecureMail-Frontend\.env.docker (
    copy SecureMail-Frontend\.env.docker.example SecureMail-Frontend\.env.docker > nul
    echo        [OK] Created SecureMail-Frontend\.env.docker
) else (
    echo        [INFO] SecureMail-Frontend\.env.docker already exists
)

if not exist SecureMail-Ai\.env.docker (
    copy SecureMail-Ai\.env.docker.example SecureMail-Ai\.env.docker > nul
    echo        [OK] Created SecureMail-Ai\.env.docker
) else (
    echo        [INFO] SecureMail-Ai\.env.docker already exists
)

if not exist SecureMail-Malware\.env.docker (
    copy SecureMail-Malware\.env.docker.example SecureMail-Malware\.env.docker > nul
    echo        [OK] Created SecureMail-Malware\.env.docker
) else (
    echo        [INFO] SecureMail-Malware\.env.docker already exists
)
echo.

:: ── 4. Ask for DB Password ─────────────────────────────────────
echo --------------------------------------------------
echo   DATABASE SETUP
echo --------------------------------------------------
echo.
echo   Enter a password for PostgreSQL.
echo   Press Enter to use default: 0000
echo.
set /p db_pass="  PostgreSQL Password: "

if "%db_pass%"=="" (
    set db_pass=0000
    echo.
    echo   [WARNING] Using default password: 0000
    echo             Not recommended for production
) else (
    echo.
    echo   [OK] Password set
)
echo.

:: ── 5. Write password into all relevant files ──────────────────
:: Root .env
powershell -Command "(Get-Content .env) -replace '^POSTGRES_PASSWORD=.*', 'POSTGRES_PASSWORD=%db_pass%' | Set-Content .env"

:: Backend .env.docker - DATABASE_URL
powershell -Command "(Get-Content SecureMail-Backend\.env.docker) -replace 'postgresql://postgres:.*@postgres', 'postgresql://postgres:%db_pass%@postgres' | Set-Content SecureMail-Backend\.env.docker"

echo [OK] Password written to root .env and SecureMail-Backend\.env.docker
echo.

:: ── 6. Remind about optional secrets ───────────────────────────
echo --------------------------------------------------
echo   [WARNING] OPTIONAL SECRETS - Fill these later
echo --------------------------------------------------
echo.
echo   SecureMail-Backend\.env.docker:
echo   - Gmail SMTP     : SMTP_PASSWORD
echo   - Google OAuth   : GOOGLE_CLIENT_ID
echo                      GOOGLE_CLIENT_SECRET
echo   - Cloudinary     : CLOUDINARY_CLOUD_NAME
echo                      CLOUDINARY_API_KEY
echo                      CLOUDINARY_API_SECRET
echo   - AbuseIPDB      : ABUSEIPDB_API_KEY
echo   - JWT            : JWT_SECRET
echo   - Encryption     : ENCRYPTION_KEY
echo.
echo   SecureMail-Ai\.env.docker:
echo   - Groq LLM       : GROQ_API_KEY
echo.
echo   Full guide: %REPO_URL%#readme
echo.
echo --------------------------------------------------
echo.
pause

:: ── 7. Start Docker Compose ────────────────────────────────────
echo.
echo [START] Starting SecureMail Full Stack...
echo         This may take a few minutes on first run
echo.
docker compose down -v > nul 2>&1
docker compose up --build -d

:: ── 8. Wait for backend ────────────────────────────────────────
echo.
echo [WAIT] Waiting for backend to be ready...
set RETRIES=30

:waitloop
docker compose logs backend 2>&1 | findstr /i "migrations have been successfully applied" > nul
if not errorlevel 1 goto done

set /a RETRIES-=1
if %RETRIES%==0 (
    echo.
    echo [ERROR] Backend failed to start. Check logs with:
    echo         docker compose logs backend
    echo         docker compose logs postgres
    pause
    exit /b 1
)
echo   still waiting...
timeout /t 5 /nobreak > nul
goto waitloop

:: ── 9. Done ────────────────────────────────────────────────────
:done
echo.
echo +================================================+
echo ^|         OK  SecureMail is running!            ^|
echo +================================================+
echo ^|  Frontend: http://localhost:3001              ^|
echo ^|  API:      http://localhost:3000              ^|
echo ^|  Health:   http://localhost:3000/health       ^|
echo +================================================+
echo ^|  Logs:   docker compose logs -f backend      ^|
echo ^|  Stop:   docker compose down                 ^|
echo +================================================+
echo.
pause
