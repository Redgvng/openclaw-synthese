#!/bin/bash
# ============================================================
# LexiClaw V3 — MiMo Worker
# Quand Claude Code est rate-limited, MiMo travaille sur le projet
# ============================================================

PROJECT_DIR="/root/.openclaw/workspace/lexiclaw-v3"
STATUS_FILE="/tmp/lexiclaw-claude-status"
LOG_FILE="/root/.openclaw/workspace-claude-code/lexiclaw-mimo.log"
PROGRESS_FILE="$PROJECT_DIR/PROGRESS.md"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Vérifier si Claude est rate-limited
check_claude_status() {
    if [ ! -f "$STATUS_FILE" ]; then
        return 1  # Pas de fichier = Claude probablement OK
    fi
    
    local status=$(head -1 "$STATUS_FILE")
    if [ "$status" = "RATE_LIMITED" ]; then
        return 0  # Rate limited
    fi
    return 1
}

# Vérifier si le rate limit window est passé (5 min)
check_reset_window() {
    if [ ! -f "$STATUS_FILE" ]; then
        return 0
    fi
    
    local last_timestamp=$(sed -n '2p' "$STATUS_FILE")
    local current_timestamp=$(date +%s)
    local diff=$((current_timestamp - last_timestamp))
    
    # 5 minutes = 300 secondes
    if [ $diff -ge 300 ]; then
        return 0  # Reset possible
    fi
    return 1
}

# Obtenir le sprint actuel depuis PROGRESS.md
get_current_sprint() {
    if [ ! -f "$PROGRESS_FILE" ]; then
        echo "0"
        return
    fi
    
    # Chercher le premier sprint "En attente"
    grep -n "En attente" "$PROGRESS_FILE" | head -1 | cut -d'|' -f2 | tr -d ' ' | head -c1
}

# ============================================================
# TÂCHES QUE MIMO PEUT FAIRE PENDANT LE RATE LIMIT
# ============================================================

# Créer la structure de base du projet
task_init_project() {
    log "📁 Initialisation de la structure du projet..."
    
    cd "$PROJECT_DIR"
    
    # Créer les dossiers
    mkdir -p app/api lib components/ui prisma workers skills docs
    
    # Créer .gitignore
    cat > .gitignore << 'EOF'
node_modules/
.next/
.env
.env.local
*.db
dist/
EOF
    
    log "✅ Structure du projet créée"
}

# Créer le package.json
task_package_json() {
    log "📦 Création du package.json..."
    
    cat > "$PROJECT_DIR/package.json" << 'EOF'
{
  "name": "lexiclaw-v3",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "db:generate": "prisma generate",
    "db:push": "prisma db push",
    "db:migrate": "prisma migrate dev",
    "db:seed": "prisma db seed",
    "worker": "tsx workers/ai-worker.ts"
  },
  "dependencies": {
    "next": "^15.2.3",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@prisma/client": "^6.5.0",
    "zustand": "^5.0.3",
    "@tanstack/react-query": "^5.69.0",
    "bullmq": "^5.41.0",
    "ioredis": "^5.6.0",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "class-variance-authority": "^0.7.1",
    "clsx": "^2.1.1",
    "tailwind-merge": "^3.1.0",
    "lucide-react": "^0.484.0",
    "@ai-sdk/react": "^1.2.9"
  },
  "devDependencies": {
    "typescript": "^5.8.2",
    "@types/node": "^22.14.0",
    "@types/react": "^19.0.12",
    "@types/react-dom": "^19.0.4",
    "@types/bcryptjs": "^2.4.6",
    "@types/jsonwebtoken": "^9.0.9",
    "tailwindcss": "^3.4.17",
    "postcss": "^8.5.3",
    "autoprefixer": "^10.4.20",
    "prisma": "^6.5.0",
    "tsx": "^4.19.3",
    "eslint": "^9.23.0",
    "eslint-config-next": "^15.2.3"
  }
}
EOF
    
    log "✅ package.json créé"
}

# Créer le tsconfig.json
task_tsconfig() {
    log "⚙️ Création du tsconfig.json..."
    
    cat > "$PROJECT_DIR/tsconfig.json" << 'EOF'
{
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": { "@/*": ["./*"] }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
EOF
    
    log "✅ tsconfig.json créé"
}

# Créer la config Tailwind
task_tailwind() {
    log "🎨 Création de la configuration Tailwind..."
    
    cat > "$PROJECT_DIR/tailwind.config.ts" << 'EOF'
import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        anthracite: "#1A1A2E",
        "night-blue": "#16213E",
        gold: "#D4AF37",
        "text-primary": "#EAEAEA",
        "text-secondary": "#9CA3AF",
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["JetBrains Mono", "monospace"],
      },
    },
  },
  plugins: [],
};

export default config;
EOF
    
    cat > "$PROJECT_DIR/postcss.config.js" << 'EOF'
module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
EOF
    
    log "✅ Tailwind configuré"
}

# Créer le schema Prisma
task_prisma() {
    log "🗄️ Création du schema Prisma..."
    
    cat > "$PROJECT_DIR/prisma/schema.prisma" << 'EOF'
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================================
// MULTI-TENANT (Isolation par cabinet)
// ============================================================

model Tenant {
  id          String   @id @default(cuid())
  name        String
  slug        String   @unique
  domain      String?  @unique
  plan        String   @default("starter")
  settings    Json     @default("{}")
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  users       User[]
  cases       Case[]
  emailCreds  EmailCredentials[]
  oAuthTokens OAuthToken[]
  instances   OpenClawInstance[]
  auditLogs   AuditLog[]
}

// ============================================================
// UTILISATEURS
// ============================================================

model User {
  id           String    @id @default(cuid())
  tenantId     String
  email        String    @unique
  passwordHash String
  name         String
  role         String    @default("lawyer") // lawyer | partner | admin
  avatar       String?
  createdAt    DateTime  @default(now())
  updatedAt    DateTime  @updatedAt

  tenant       Tenant    @relation(fields: [tenantId], references: [id])
  cases        Case[]    @relation("CaseAssignee")
  messages     Message[]
  billingEntries BillingEntry[]
  auditLogs    AuditLog[]
  refreshTokens RefreshToken[]

  @@unique([tenantId, email])
}

// ============================================================
// DOSSIERS (Cases)
// ============================================================

model Case {
  id          String    @id @default(cuid())
  tenantId    String
  clientId    String?
  reference   String
  title       String
  description String?
  status      String    @default("active") // active | pending | closed | archived
  priority    String    @default("normal") // low | normal | high | critical
  category    String?   // civil | penal | labor | commercial | etc.
  assignedTo  String?
  deadline    DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  assignee    User?     @relation("CaseAssignee", fields: [assignedTo], references: [id])
  documents   Document[]
  messages    Message[]
  tasks       Task[]
  events      Event[]
  aiJobs      AIJob[]
  billingEntries BillingEntry[]
  emailCredentials EmailCredentials[]
  notes       Note[]

  @@unique([tenantId, reference])
}

// ============================================================
// DOCUMENTS
// ============================================================

model Document {
  id          String   @id @default(cuid())
  tenantId    String
  caseId      String
  name        String
  type        String   // pdf | docx | image | email
  s3Key       String
  size        Int
  metadata    Json     @default("{}")
  version     Int      @default(1)
  createdBy   String
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  tenant      Tenant   @relation(fields: [tenantId], references: [id])
  case        Case     @relation(fields: [caseId], references: [id])

  @@index([tenantId, caseId])
}

// ============================================================
// MESSAGES (Chat IA)
// ============================================================

model Message {
  id          String   @id @default(cuid())
  tenantId    String
  caseId      String
  senderId    String
  content     String
  role        String   // user | assistant | system
  metadata    Json     @default("{}")
  createdAt   DateTime @default(now())

  tenant      Tenant   @relation(fields: [tenantId], references: [id])
  case        Case     @relation(fields: [caseId], references: [id])
  sender      User     @relation(fields: [senderId], references: [id])

  @@index([tenantId, caseId, createdAt])
}

// ============================================================
// NOTES
// ============================================================

model Note {
  id          String   @id @default(cuid())
  tenantId    String
  caseId      String
  content     String
  createdBy   String
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  tenant      Tenant   @relation(fields: [tenantId], references: [id])
  case        Case     @relation(fields: [caseId], references: [id])

  @@index([tenantId, caseId])
}

// ============================================================
// TÂCHES
// ============================================================

model Task {
  id          String    @id @default(cuid())
  tenantId    String
  caseId      String
  title       String
  description String?
  status      String    @default("todo") // todo | in_progress | done
  priority    String    @default("normal")
  assignedTo  String?
  dueDate     DateTime?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  case        Case      @relation(fields: [caseId], references: [id])

  @@index([tenantId, caseId])
}

// ============================================================
// ÉVÉNEMENTS (Audiences, RDV)
// ============================================================

model Event {
  id          String    @id @default(cuid())
  tenantId    String
  caseId      String
  title       String
  type        String    // hearing | meeting | deadline | appointment
  date        DateTime
  endDate     DateTime?
  location    String?
  notes       String?
  createdAt   DateTime  @default(now())
  updatedAt   DateTime  @updatedAt

  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  case        Case      @relation(fields: [caseId], references: [id])

  @@index([tenantId, caseId, date])
}

// ============================================================
// JOBS IA (BullMQ)
// ============================================================

model AIJob {
  id          String    @id @default(cuid())
  tenantId    String
  caseId      String
  type        String    // analyze_contract | summarize | extract_clauses | etc.
  status      String    @default("pending") // pending | processing | completed | failed
  payload     Json
  result      Json?
  error       String?
  retryCount  Int       @default(0)
  maxRetries  Int       @default(3)
  startedAt   DateTime?
  completedAt DateTime?
  createdAt   DateTime  @default(now())

  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  case        Case      @relation(fields: [caseId], references: [id])

  @@index([tenantId, status])
}

// ============================================================
// FACTURATION (E-Billing)
// ============================================================

model BillingEntry {
  id          String    @id @default(cuid())
  tenantId    String
  caseId      String
  userId      String
  description String
  duration    Int       // minutes
  rate        Decimal   @db.Decimal(10, 2)
  amount      Decimal   @db.Decimal(10, 2)
  date        DateTime  @default(now())
  createdAt   DateTime  @default(now())

  tenant      Tenant    @relation(fields: [tenantId], references: [id])
  case        Case      @relation(fields: [caseId], references: [id])
  user        User      @relation(fields: [userId], references: [id])

  @@index([tenantId, caseId])
}

// ============================================================
// EMAIL CREDENTIALS (IMAP/SMTP)
// ============================================================

model EmailCredentials {
  id          String   @id @default(cuid())
  tenantId    String
  caseId      String?
  provider    String   // gmail | outlook
  email       String
  imapServer  String
  imapPort    Int      @default(993)
  smtpServer  String
  smtpPort    Int      @default(587)
  appPassword String   // Encrypted
  isActive    Boolean  @default(true)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt

  tenant      Tenant   @relation(fields: [tenantId], references: [id])
  case        Case?    @relation(fields: [caseId], references: [id])

  @@unique([tenantId, email])
}

// ============================================================
// OAUTH TOKENS
// ============================================================

model OAuthToken {
  id           String   @id @default(cuid())
  tenantId     String
  userId       String
  provider     String   // google | microsoft
  accessToken  String   // Encrypted
  refreshToken String   // Encrypted
  expiresAt    DateTime
  scope        String
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt

  tenant       Tenant   @relation(fields: [tenantId], references: [id])

  @@unique([tenantId, userId, provider])
}

// ============================================================
// OPENCLAW INSTANCES
// ============================================================

model OpenClawInstance {
  id               String   @id @default(cuid())
  tenantId         String
  name             String
  url              String
  port             Int
  status           String   @default("stopped") // stopped | starting | running | error
  config           Json     @default("{}")
  gatewayToken     String
  lastHealthCheck  DateTime?
  createdAt        DateTime @default(now())
  updatedAt        DateTime @updatedAt

  tenant           Tenant   @relation(fields: [tenantId], references: [id])

  @@unique([tenantId, name])
}

// ============================================================
// AUTH & AUDIT
// ============================================================

model RefreshToken {
  id        String   @id @default(cuid())
  userId    String
  token     String   @unique
  expiresAt DateTime
  createdAt DateTime @default(now())

  user      User     @relation(fields: [userId], references: [id])

  @@index([userId])
}

model AuditLog {
  id        String   @id @default(cuid())
  tenantId  String
  userId    String?
  action    String
  entity    String
  entityId  String
  metadata  Json     @default("{}")
  ipAddress String?
  createdAt DateTime @default(now())

  tenant    Tenant   @relation(fields: [tenantId], references: [id])
  user      User?    @relation(fields: [userId], references: [id])

  @@index([tenantId, entity, entityId])
  @@index([tenantId, createdAt])
}
EOF
    
    log "✅ Schema Prisma créé (14 tables)"
}

# Créer le docker-compose.yml
task_docker_compose() {
    log "🐳 Création du docker-compose.yml..."
    
    cat > "$PROJECT_DIR/docker-compose.yml" << 'EOF'
version: "3.8"

services:
  # ============================================================
  # SHARED SERVICES
  # ============================================================
  
  postgres:
    image: postgres:16-alpine
    container_name: lexiclaw-v3-postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: lexiclaw
      POSTGRES_PASSWORD: lexiclaw_secret_2026
      POSTGRES_DB: lexiclaw_v3
    ports:
      - "127.0.0.1:5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U lexiclaw"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: lexiclaw-v3-redis
    restart: unless-stopped
    ports:
      - "127.0.0.1:6379:6379"
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # ============================================================
  # OPENCLAW TENANT WORKERS
  # ============================================================

  openclaw-tenant-a:
    image: node:24-alpine
    container_name: lexiclaw-v3-tenant-a
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
    environment:
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN_A:-tenant-a-secret}
      OPENCLAW_BIND: "127.0.0.1"
      OPENCLAW_PORT: "18789"
      DATABASE_URL: postgresql://lexiclaw:lexiclaw_secret_2026@postgres:5432/lexiclaw_v3
      REDIS_URL: redis://redis:6379
    ports:
      - "127.0.0.1:18789:18789"
    volumes:
      - ./openclaw-config/tenant-a:/app/config
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "npx -y openclaw@latest gateway --port 18789 --bind 127.0.0.1"

  openclaw-tenant-b:
    image: node:24-alpine
    container_name: lexiclaw-v3-tenant-b
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 1G
    environment:
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN_B:-tenant-b-secret}
      OPENCLAW_BIND: "127.0.0.1"
      OPENCLAW_PORT: "18790"
      DATABASE_URL: postgresql://lexiclaw:lexiclaw_secret_2026@postgres:5432/lexiclaw_v3
      REDIS_URL: redis://redis:6379
    ports:
      - "127.0.0.1:18790:18790"
    volumes:
      - ./openclaw-config/tenant-b:/app/config
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    command: >
      sh -c "npx -y openclaw@latest gateway --port 18790 --bind 127.0.0.1"

volumes:
  postgres_data:
  redis_data:
EOF
    
    log "✅ docker-compose.yml créé"
}

# Créer next.config.ts
task_next_config() {
    log "⚙️ Création de next.config.ts..."
    
    cat > "$PROJECT_DIR/next.config.ts" << 'EOF'
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  experimental: {
    serverActions: {
      bodySizeLimit: "10mb",
    },
  },
  async rewrites() {
    return [
      {
        source: "/api/openclaw/:path*",
        destination: `${process.env.OPENCLAW_URL || "http://127.0.0.1:18789"}/:path*`,
      },
    ];
  },
};

export default nextConfig;
EOF
    
    log "✅ next.config.ts créé"
}

# Créer le .env
task_env() {
    log "🔐 Création du .env..."
    
    cat > "$PROJECT_DIR/.env" << 'EOF'
# Database
DATABASE_URL="postgresql://lexiclaw:lexiclaw_secret_2026@localhost:5432/lexiclaw_v3"

# Redis (BullMQ)
REDIS_URL="redis://localhost:6379"

# Auth
JWT_SECRET="lexiclaw-v3-jwt-secret-change-in-production"
JWT_REFRESH_SECRET="lexiclaw-v3-refresh-secret-change-in-production"

# OpenClaw
OPENCLAW_URL="http://127.0.0.1:18789"
OPENCLAW_GATEWAY_TOKEN="lexiclaw-v3-gateway-token"

# App
NEXT_PUBLIC_APP_URL="http://localhost:3000"
NEXT_PUBLIC_APP_NAME="LexiClaw V3"
EOF
    
    log "✅ .env créé"
}

# Créer le layout principal
task_layout() {
    log "🎨 Création du layout principal..."
    
    mkdir -p "$PROJECT_DIR/app/(app)"
    mkdir -p "$PROJECT_DIR/app/(auth)/login"
    mkdir -p "$PROJECT_DIR/app/api/auth/login"
    mkdir -p "$PROJECT_DIR/app/api/auth/register"
    mkdir -p "$PROJECT_DIR/app/api/cases"
    mkdir -p "$PROJECT_DIR/app/api/chat"
    mkdir -p "$PROJECT_DIR/app/api/jobs"
    mkdir -p "$PROJECT_DIR/app/dashboard"
    mkdir -p "$PROJECT_DIR/app/cases/\[caseId\]"
    mkdir -p "$PROJECT_DIR/app/chat"
    mkdir -p "$PROJECT_DIR/app/settings"
    
    # globals.css
    mkdir -p "$PROJECT_DIR/app"
    cat > "$PROJECT_DIR/app/globals.css" << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: #1A1A2E;
    --foreground: #EAEAEA;
    --card: #16213E;
    --card-foreground: #EAEAEA;
    --primary: #D4AF37;
    --primary-foreground: #1A1A2E;
    --secondary: #9CA3AF;
    --muted: #16213E;
    --muted-foreground: #9CA3AF;
    --accent: #D4AF37;
    --accent-foreground: #1A1A2E;
    --destructive: #EF4444;
    --border: #2A2A4A;
    --input: #2A2A4A;
    --ring: #D4AF37;
    --radius: 0.5rem;
  }
}

@layer base {
  * {
    @apply border-[var(--border)];
  }
  body {
    @apply bg-[var(--background)] text-[var(--foreground)];
    font-feature-settings: "rlig" 1, "calt" 1;
  }
}

/* Inter font */
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

/* JetBrains Mono for legal quotes */
.font-mono {
  font-family: 'JetBrains Mono', monospace;
}
EOF
    
    # app/layout.tsx
    cat > "$PROJECT_DIR/app/layout.tsx" << 'EOFX'
import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "LexiClaw V3 — Legal OS",
  description: "Enterprise LegalTech SaaS powered by OpenClaw",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr" className="dark">
      <body className="min-h-screen bg-anthracite font-sans antialiased">
        {children}
      </body>
    </html>
  );
}
EOFX
    
    # app/page.tsx (landing)
    cat > "$PROJECT_DIR/app/page.tsx" << 'EOFX'
import Link from "next/link";

export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-8">
      <div className="text-center">
        <h1 className="text-5xl font-bold text-gold mb-4">LexiClaw V3</h1>
        <p className="text-xl text-text-secondary mb-8">
          Enterprise LegalTech OS — Powered by OpenClaw
        </p>
        <Link
          href="/login"
          className="px-8 py-3 bg-gold text-anthracite font-semibold rounded-lg hover:bg-gold/90 transition"
        >
          Se connecter
        </Link>
      </div>
    </main>
  );
}
EOFX
    
    log "✅ Layout et page d'accueil créés"
}

# Créer les composants UI de base
task_ui_components() {
    log "🧩 Création des composants UI..."
    
    mkdir -p "$PROJECT_DIR/components/ui"
    mkdir -p "$PROJECT_DIR/components/layout"
    mkdir -p "$PROJECT_DIR/components/chat"
    mkdir -p "$PROJECT_DIR/lib"
    
    # lib/utils.ts
    cat > "$PROJECT_DIR/lib/utils.ts" << 'EOFX'
import { type ClassValue, clsx } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOFX
    
    # lib/prisma.ts
    cat > "$PROJECT_DIR/lib/prisma.ts" << 'EOFX'
import { PrismaClient } from "@prisma/client";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;
EOFX
    
    # lib/auth.ts
    cat > "$PROJECT_DIR/lib/auth.ts" << 'EOFX'
import jwt from "jsonwebtoken";
import bcrypt from "bcryptjs";

const JWT_SECRET = process.env.JWT_SECRET || "dev-secret";
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || "dev-refresh-secret";

export interface TokenPayload {
  userId: string;
  tenantId: string;
  email: string;
  role: string;
}

export function hashPassword(password: string): Promise<string> {
  return bcrypt.hash(password, 12);
}

export function verifyPassword(password: string, hash: string): Promise<boolean> {
  return bcrypt.compare(password, hash);
}

export function generateToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: "1h" });
}

export function generateRefreshToken(payload: TokenPayload): string {
  return jwt.sign(payload, JWT_REFRESH_SECRET, { expiresIn: "7d" });
}

export function verifyToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, JWT_SECRET) as TokenPayload;
  } catch {
    return null;
  }
}

export function verifyRefreshToken(token: string): TokenPayload | null {
  try {
    return jwt.verify(token, JWT_REFRESH_SECRET) as TokenPayload;
  } catch {
    return null;
  }
}
EOFX
    
    # lib/bullmq.ts
    cat > "$PROJECT_DIR/lib/bullmq.ts" << 'EOFX'
import { Queue, Worker, Job } from "bullmq";
import Redis from "ioredis";

const connection = new Redis(process.env.REDIS_URL || "redis://localhost:6379", {
  maxRetriesPerRequest: null,
});

// Queue for AI jobs
export const aiJobQueue = new Queue("ai-jobs", {
  connection,
  defaultJobOptions: {
    attempts: 3,
    backoff: {
      type: "exponential",
      delay: 1000,
    },
    removeOnComplete: { count: 100 },
    removeOnFail: { count: 50 },
  },
});

// Job types
export type AIJobType = 
  | "ANALYZE_CONTRACT"
  | "SUMMARIZE_DOCUMENT"
  | "EXTRACT_CLAUSES"
  | "COMPARE_VERSIONS"
  | "GENERATE_TIMELINE"
  | "CHECK_CONFLICTS";

export interface AIJobPayload {
  tenantId: string;
  caseId: string;
  jobId: string;
  type: AIJobType;
  documentId?: string;
  content?: string;
  metadata?: Record<string, unknown>;
}

// Add a job to the queue
export async function addAIJob(payload: AIJobPayload) {
  return aiJobQueue.add(payload.type, payload, {
    jobId: payload.jobId,
  });
}

// Worker setup (to be started in workers/ai-worker.ts)
export function createWorker(processor: (job: Job<AIJobPayload>) => Promise<void>) {
  return new Worker<AIJobPayload>("ai-jobs", processor, {
    connection,
    concurrency: 5,
  });
}
EOFX
    
    # components/ui/button.tsx
    cat > "$PROJECT_DIR/components/ui/button.tsx" << 'EOFX'
import * as React from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "@/lib/utils";

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-gold disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "bg-gold text-anthracite shadow hover:bg-gold/90",
        destructive: "bg-red-500 text-white shadow-sm hover:bg-red-500/90",
        outline: "border border-border bg-transparent shadow-sm hover:bg-night-blue hover:text-text-primary",
        secondary: "bg-night-blue text-text-primary shadow-sm hover:bg-night-blue/80",
        ghost: "hover:bg-night-blue hover:text-text-primary",
        link: "text-gold underline-offset-4 hover:underline",
      },
      size: {
        default: "h-9 px-4 py-2",
        sm: "h-8 rounded-md px-3 text-xs",
        lg: "h-10 rounded-md px-8",
        icon: "h-9 w-9",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, ...props }, ref) => {
    return (
      <button
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    );
  }
);
Button.displayName = "Button";

export { Button, buttonVariants };
EOFX
    
    # components/ui/input.tsx
    cat > "$PROJECT_DIR/components/ui/input.tsx" << 'EOFX'
import * as React from "react";
import { cn } from "@/lib/utils";

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, type, ...props }, ref) => {
    return (
      <input
        type={type}
        className={cn(
          "flex h-9 w-full rounded-md border border-border bg-transparent px-3 py-1 text-sm text-text-primary shadow-sm transition-colors file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-text-secondary focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-gold disabled:cursor-not-allowed disabled:opacity-50",
          className
        )}
        ref={ref}
        {...props}
      />
    );
  }
);
Input.displayName = "Input";

export { Input };
EOFX
    
    # components/ui/card.tsx
    cat > "$PROJECT_DIR/components/ui/card.tsx" << 'EOFX'
import * as React from "react";
import { cn } from "@/lib/utils";

const Card = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div
      ref={ref}
      className={cn("rounded-xl border border-border bg-night-blue text-text-primary shadow", className)}
      {...props}
    />
  )
);
Card.displayName = "Card";

const CardHeader = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("flex flex-col space-y-1.5 p-6", className)} {...props} />
  )
);
CardHeader.displayName = "CardHeader";

const CardTitle = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLHeadingElement>>(
  ({ className, ...props }, ref) => (
    <h3 ref={ref} className={cn("font-semibold leading-none tracking-tight", className)} {...props} />
  )
);
CardTitle.displayName = "CardTitle";

const CardDescription = React.forwardRef<HTMLParagraphElement, React.HTMLAttributes<HTMLParagraphElement>>(
  ({ className, ...props }, ref) => (
    <p ref={ref} className={cn("text-sm text-text-secondary", className)} {...props} />
  )
);
CardDescription.displayName = "CardDescription";

const CardContent = React.forwardRef<HTMLDivElement, React.HTMLAttributes<HTMLDivElement>>(
  ({ className, ...props }, ref) => (
    <div ref={ref} className={cn("p-6 pt-0", className)} {...props} />
  )
);
CardContent.displayName = "CardContent";

export { Card, CardHeader, CardTitle, CardDescription, CardContent };
EOFX
    
    log "✅ Composants UI créés (Button, Input, Card)"
}

# Créer le sidebar
task_sidebar() {
    log "📁 Création du sidebar..."
    
    cat > "$PROJECT_DIR/components/layout/sidebar.tsx" << 'EOFX'
"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: "📊" },
  { href: "/cases", label: "Dossiers", icon: "📁" },
  { href: "/chat", label: "Chat IA", icon: "💬" },
  { href: "/settings", label: "Paramètres", icon: "⚙️" },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="fixed left-0 top-0 z-40 h-screen w-64 border-r border-border bg-anthracite">
      <div className="flex h-16 items-center border-b border-border px-6">
        <Link href="/dashboard" className="flex items-center gap-2">
          <span className="text-2xl">⚖️</span>
          <span className="text-xl font-bold text-gold">LexiClaw</span>
        </Link>
      </div>
      <nav className="space-y-1 p-4">
        {navItems.map((item) => (
          <Link
            key={item.href}
            href={item.href}
            className={cn(
              "flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors",
              pathname === item.href
                ? "bg-gold/10 text-gold"
                : "text-text-secondary hover:bg-night-blue hover:text-text-primary"
            )}
          >
            <span>{item.icon}</span>
            <span>{item.label}</span>
          </Link>
        ))}
      </nav>
    </aside>
  );
}
EOFX
    
    log "✅ Sidebar créé"
}

# Créer les pages de base
task_pages() {
    log "📄 Création des pages de base..."
    
    # Login page
    mkdir -p "$PROJECT_DIR/app/login"
    cat > "$PROJECT_DIR/app/login/page.tsx" << 'EOFX'
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from "@/components/ui/card";

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      const res = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || "Erreur de connexion");
        return;
      }

      localStorage.setItem("token", data.token);
      localStorage.setItem("refreshToken", data.refreshToken);
      router.push("/dashboard");
    } catch {
      setError("Erreur réseau");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl text-gold">⚖️ LexiClaw V3</CardTitle>
          <CardDescription>Connectez-vous à votre Legal OS</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="text-sm text-text-secondary mb-1 block">Email</label>
              <Input
                type="email"
                placeholder="avocat@cabinet.fr"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
            </div>
            <div>
              <label className="text-sm text-text-secondary mb-1 block">Mot de passe</label>
              <Input
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>
            {error && <p className="text-sm text-red-500">{error}</p>}
            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "Connexion..." : "Se connecter"}
            </Button>
          </form>
        </CardContent>
      </Card>
    </main>
  );
}
EOFX
    
    # Dashboard page
    cat > "$PROJECT_DIR/app/dashboard/page.tsx" << 'EOFX'
import { Sidebar } from "@/components/layout/sidebar";

export default function DashboardPage() {
  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8">
        <h1 className="text-3xl font-bold text-text-primary mb-6">Dashboard</h1>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="rounded-xl border border-border bg-night-blue p-6">
            <p className="text-sm text-text-secondary">Dossiers actifs</p>
            <p className="text-3xl font-bold text-gold mt-2">0</p>
          </div>
          <div className="rounded-xl border border-border bg-night-blue p-6">
            <p className="text-sm text-text-secondary">Tâches en cours</p>
            <p className="text-3xl font-bold text-gold mt-2">0</p>
          </div>
          <div className="rounded-xl border border-border bg-night-blue p-6">
            <p className="text-sm text-text-secondary">Facturation ce mois</p>
            <p className="text-3xl font-bold text-gold mt-2">0€</p>
          </div>
          <div className="rounded-xl border border-border bg-night-blue p-6">
            <p className="text-sm text-text-secondary">Jobs IA en cours</p>
            <p className="text-3xl font-bold text-gold mt-2">0</p>
          </div>
        </div>
      </main>
    </div>
  );
}
EOFX
    
    # Cases page
    cat > "$PROJECT_DIR/app/cases/page.tsx" << 'EOFX'
import { Sidebar } from "@/components/layout/sidebar";

export default function CasesPage() {
  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8">
        <h1 className="text-3xl font-bold text-text-primary mb-6">Dossiers</h1>
        <p className="text-text-secondary">Aucun dossier pour le moment.</p>
      </main>
    </div>
  );
}
EOFX
    
    # Chat page
    cat > "$PROJECT_DIR/app/chat/page.tsx" << 'EOFX'
import { Sidebar } from "@/components/layout/sidebar";

export default function ChatPage() {
  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8">
        <h1 className="text-3xl font-bold text-text-primary mb-6">Chat IA</h1>
        <p className="text-text-secondary">Commencez une conversation avec votre assistant IA.</p>
      </main>
    </div>
  );
}
EOFX
    
    # Settings page
    cat > "$PROJECT_DIR/app/settings/page.tsx" << 'EOFX'
import { Sidebar } from "@/components/layout/sidebar";

export default function SettingsPage() {
  return (
    <div className="flex">
      <Sidebar />
      <main className="ml-64 flex-1 p-8">
        <h1 className="text-3xl font-bold text-text-primary mb-6">Paramètres</h1>
        <p className="text-text-secondary">Configuration du cabinet et de l&apos;IA.</p>
      </main>
    </div>
  );
}
EOFX
    
    # API auth login
    cat > "$PROJECT_DIR/app/api/auth/login/route.ts" << 'EOFX'
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyPassword, generateToken, generateRefreshToken } from "@/lib/auth";

export async function POST(request: NextRequest) {
  try {
    const { email, password } = await request.json();

    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      return NextResponse.json({ error: "Identifiants invalides" }, { status: 401 });
    }

    const valid = await verifyPassword(password, user.passwordHash);
    if (!valid) {
      return NextResponse.json({ error: "Identifiants invalides" }, { status: 401 });
    }

    const payload = {
      userId: user.id,
      tenantId: user.tenantId,
      email: user.email,
      role: user.role,
    };

    const token = generateToken(payload);
    const refreshToken = generateRefreshToken(payload);

    await prisma.refreshToken.create({
      data: {
        userId: user.id,
        token: refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    });

    return NextResponse.json({ token, refreshToken, user: { id: user.id, name: user.name, email: user.email, role: user.role } });
  } catch (error) {
    return NextResponse.json({ error: "Erreur serveur" }, { status: 500 });
  }
}
EOFX
    
    # API cases
    cat > "$PROJECT_DIR/app/api/cases/route.ts" << 'EOFX'
import { NextRequest, NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import { verifyToken } from "@/lib/auth";

export async function GET(request: NextRequest) {
  const authHeader = request.headers.get("authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return NextResponse.json({ error: "Non autorisé" }, { status: 401 });
  }

  const payload = verifyToken(authHeader.slice(7));
  if (!payload) {
    return NextResponse.json({ error: "Token invalide" }, { status: 401 });
  }

  const cases = await prisma.case.findMany({
    where: { tenantId: payload.tenantId },
    orderBy: { updatedAt: "desc" },
  });

  return NextResponse.json(cases);
}
EOFX
    
    log "✅ Pages de base créées (Login, Dashboard, Cases, Chat, Settings)"
}

# Créer le HEARTBEAT.md
task_heartbeat() {
    log "💓 Création du HEARTBEAT.md..."
    
    cat > "$PROJECT_DIR/HEARTBEAT.md" << 'EOF'
# Heartbeat — LexiClaw V3

## Checklist
- [ ] Vérifier les nouveaux emails (si configuré)
- [ ] Extraire les dates d'audience des emails
- [ ] Mettre à jour les dossiers avec nouvelles infos
- [ ] Vérifier les deadlines critiques (< 48h)
- [ ] Générer les rappels automatiques

## Configuration
- Fréquence : toutes les 30 minutes
- Mode : lightContext (vérifications déterministes d'abord)
- Heure briefing : 7h00
EOF
    
    cat > "$PROJECT_DIR/HEARTBEAT.md" > "$PROJECT_DIR/HEARTBEAT.md"
    
    log "✅ HEARTBEAT.md créé"
}

# ============================================================
# MAIN — Exécuter les tâches disponibles
# ============================================================

log "🚀 Démarrage du worker MiMo..."
log "📁 Projet: $PROJECT_DIR"

# Vérifier si Claude est rate-limited
if check_claude_status; then
    log "⚠️ Claude Code est rate-limited — MiMo prend le relais"
    
    # Déterminer quelles tâches faire
    if [ ! -f "$PROJECT_DIR/package.json" ]; then
        log "📦 Projet pas encore initialisé — création de la base"
        task_init_project
        task_package_json
        task_tsconfig
        task_tailwind
        task_prisma
        task_docker_compose
        task_next_config
        task_env
        task_layout
        task_ui_components
        task_sidebar
        task_pages
        task_heartbeat
        log "🎉 Sprint 1 (base) créé par MiMo !"
    else
        log "✅ Base déjà existante — vérification des améliorations possibles"
        
        # Vérifier les fichiers manquants
        [ ! -f "$PROJECT_DIR/components/layout/sidebar.tsx" ] && task_sidebar
        [ ! -f "$PROJECT_DIR/app/dashboard/page.tsx" ] && task_pages
        [ ! -f "$PROJECT_DIR/HEARTBEAT.md" ] && task_heartbeat
        
        log "✅ Projet à jour — en attente de Claude Code"
    fi
    
    # Vérifier si le rate limit window est passé
    if check_reset_window; then
        log "🔄 Fenêtre de reset possible — vérification au prochain cycle"
        rm -f "$STATUS_FILE"
    fi
else
    log "✅ Claude Code est opérationnel — MiMo en veille"
fi

log "🏁 Worker MiMo terminé"
