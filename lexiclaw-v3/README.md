# LexiClaw V3 — Agent Prompting Playbook
## Enterprise LegalTech SaaS — Single-Tenant AI on Shared Infrastructure

**Projet :** LexiClaw V3  
**Créé :** 31 Mars 2026  
**Auteur :** Red Adaw  
**Status :** Initialisation

---

## 🧠 PROMPT 0 : SYSTEM INSTRUCTIONS (Custom Instructions / System Prompt)

Ce prompt sert de "cerveau" de base pour l'agent. Il définit l'architecture globale.

```
ROLE & MISSION
You are an Elite Staff Engineer building "LexiClaw V3", an Enterprise LegalTech SaaS. You will build a "Single-Tenant AI on Shared Infrastructure" platform.

TECH STACK
* Frontend: Next.js 15 (App Router), Tailwind CSS v3, shadcn/ui.
* State: Zustand, React Query, Vercel AI SDK.
* Backend: Next.js API Routes, BullMQ + Redis.
* Database: PostgreSQL 16 + Prisma ORM (Strict Tenant Isolation).
* AI Workers: Isolated OpenClaw Docker containers.

CRITICAL OPENCLAW SECURITY RULES:
* Runtime: OpenClaw containers MUST use Node.js 24 for optimal WebSocket latency and memory footprint. Containers must have a minimum of 2GB RAM allocated to prevent UI crashes.
* Network Isolation: The OpenClaw Gateway must bind exclusively to 127.0.0.1 on port 18789 to prevent the CVE-2026-25253 Remote Code Execution vulnerability.
* Memory Safety: To prevent the AI from losing safety instructions during long legal document reviews, you must enable compaction.memoryFlush with a softThresholdTokens of 4000 in openclaw.json.
* No Third-Party Skills: Due to the "ClawHavoc" supply chain attack, do NOT install external skills from ClawHub. We will build custom internal skills using SKILL.md.

EXECUTION RULE: Do not execute multiple tasks in parallel. Wait for my specific Sprint Prompts. Acknowledge these rules now.
```

---

## 🚀 SPRINT 1 : INITIALIZATION & DATABASE

**Objectif :** Setup Next.js + Prisma Schema  
**Prérequis :** Prompt 0 validé

```
SPRINT 1: NEXT.JS SETUP & PRISMA SCHEMA

We are starting from an empty directory. Your tasks:
* Initialize a Next.js 15 project with TypeScript, Tailwind, and App Router.
* Initialize Prisma ORM.
* Write the complete schema.prisma for our legal SaaS.

SCHEMA REQUIREMENTS:
* Tenant (Law firm).
* User (Lawyer, linked to Tenant).
* Case (Legal matter, linked to Tenant).
* Document (Files uploaded to a Case).
* Message & AuditLog (For AI chat and tracking actions).
* AI_Job (For tracking BullMQ background tasks).

CONSTRAINT: Every table (except Tenant) MUST have a tenantId for strict data isolation. Provide the terminal commands and the full schema.prisma code. Do not write UI code yet.
```

### Checklist Sprint 1
- [ ] Next.js 15 initialisé (TypeScript, Tailwind, App Router)
- [ ] Prisma ORM initialisé
- [ ] `schema.prisma` complet avec toutes les tables
- [ ] Chaque table (sauf Tenant) a un `tenantId`
- [ ] Migration exécutée avec succès
- [ ] PostgreSQL opérationnel

---

## 🐳 SPRINT 2 : INFRASTRUCTURE & OPENCLAW TENANTS

**Objectif :** Docker Compose + AI Workers  
**Prérequis :** Sprint 1 validé et testé

```
SPRINT 2: DOCKER COMPOSE & AI WORKERS

Generate the docker-compose.yml file to run our local infrastructure.

REQUIREMENTS:
* Shared Services: Include PostgreSQL 16 and Redis 7.
* Tenant AI Workers: Define two sample OpenClaw containers (openclaw-tenant-a and openclaw-tenant-b).
* Security Constraints:
  * The OpenClaw containers must use the official Node 24 environment.
  * Apply deploy.resources.limits with 2GB of RAM minimum per OpenClaw container.
  * Set environment variables to bind to 127.0.0.1 and require an OPENCLAW_GATEWAY_TOKEN.
* Configuration: Generate a bash script or Node script to auto-generate the openclaw.json file for these tenants, ensuring compaction.memoryFlush is enabled.

Provide the docker-compose.yml and the configuration script.
```

### Checklist Sprint 2
- [ ] `docker-compose.yml` créé
- [ ] PostgreSQL 16 configuré
- [ ] Redis 7 configuré
- [ ] 2 containers OpenClaw (tenant-a, tenant-b)
- [ ] Node.js 24 dans les containers
- [ ] 2GB RAM minimum par container
- [ ] Bind 127.0.0.1:18789
- [ ] `OPENCLAW_GATEWAY_TOKEN` configuré
- [ ] Script de génération `openclaw.json`
- [ ] `compaction.memoryFlush` activé (softThresholdTokens: 4000)
- [ ] `docker compose up` fonctionne

---

## 🖥️ SPRINT 3 : UI SHELL & AUTHENTICATION

**Objectif :** Layout + Auth + Thème  
**Prérequis :** Sprint 2 validé (Docker fonctionne)

```
SPRINT 3: AUTHENTICATION & DASHBOARD SHELL

We need to build the core UI layout.

TASKS:
* Setup shadcn/ui components (Sidebar, Topbar, Button, Input, Table).
* Apply our dark mode theme (Anthracite #1A1A2E background, Gold #D4AF37 accents).
* Create a dummy authentication flow (NextAuth or custom JWT) that injects the tenantId into the user session.
* Build the app/(app)/layout.tsx featuring a persistent left sidebar with navigation to: Dashboard, Cases, Chat, Settings.

Provide the configuration files for Tailwind/shadcn and the Layout component code.
```

### Design System
| Élément | Couleur | Hex |
|---------|---------|-----|
| Background | Anthracite | `#1A1A2E` |
| Accent | Gold | `#D4AF37` |
| Cards | Dark Blue | `#16213E` |
| Text Primary | White | `#FFFFFF` |
| Text Secondary | Gray | `#9CA3AF` |
| Success | Green | `#10B981` |
| Error | Red | `#EF4444` |
| Warning | Amber | `#F59E0B` |

### Checklist Sprint 3
- [ ] shadcn/ui installé et configuré
- [ ] Thème dark mode appliqué
- [ ] Auth flow (JWT ou NextAuth)
- [ ] `tenantId` injecté dans la session
- [ ] Layout avec sidebar persistante
- [ ] Navigation : Dashboard, Cases, Chat, Settings
- [ ] Composants : Sidebar, Topbar, Button, Input, Table

---

## 💬 SPRINT 4 : CONTEXTUAL AI CHAT (VERCEL AI SDK)

**Objectif :** Chat temps réel avec l'IA par dossier  
**Prérequis :** Sprint 3 validé (UI fonctionnelle)

```
SPRINT 4: VERCEL AI SDK INTEGRATION

Build the Case Workspace Chat interface.

TASKS:
* Install @ai-sdk/react.
* Build the <WorkspaceChat /> component using the useChat hook to handle streaming, auto-scroll, and markdown rendering.
* Build the Next.js API Route (app/api/chat/route.ts).

BACKEND LOGIC:
* The API route must extract the tenantId from the user session.
* Look up the correct OpenClaw container URL for this tenant (e.g., http://openclaw-tenant-a:18789).
* Proxy the chat request to the OpenClaw Gateway using the Gateway WebSocket API or its OpenAI-compatible HTTP endpoints.
* Ensure the prompt asks OpenClaw to analyze the context of the specific caseId.
```

### Checklist Sprint 4
- [ ] `@ai-sdk/react` installé
- [ ] Composant `<WorkspaceChat />` créé
- [ ] Hook `useChat` (streaming, auto-scroll, markdown)
- [ ] API Route `/api/chat/route.ts`
- [ ] Extraction `tenantId` depuis la session
- [ ] Résolution URL OpenClaw par tenant
- [ ] Proxy vers OpenClaw Gateway
- [ ] Contexte `caseId` injecté dans le prompt
- [ ] Streaming fonctionnel
- [ ] Rendu Markdown opérationnel

---

## ⚡ SPRINT 5 : BACKGROUND WORKFLOWS & CUSTOM SKILLS

**Objectif :** Jobs async + Skills OpenClaw custom  
**Prérequis :** Sprint 4 validé (Chat fonctionne)

```
SPRINT 5: BULLMQ & OPENCLAW SKILLS

We need to execute long-running tasks asynchronously.

TASKS:
* Setup a BullMQ worker in the Next.js backend to listen for jobs like ANALYZE_CONTRACT.
* Create a custom OpenClaw Skill. Generate the folder structure and the SKILL.md file for a "Legal Document Analyzer" skill.
* The SKILL.md must include YAML frontmatter for metadata and markdown instructions detailing how the agent should extract obligations and clauses.
* When the BullMQ job finishes, it should update the AI_Job table in PostgreSQL.

Provide the BullMQ worker setup code and the exact SKILL.md content.
```

### Checklist Sprint 5
- [ ] BullMQ worker configuré
- [ ] Queue `ANALYZE_CONTRACT` fonctionnelle
- [ ] Skill "Legal Document Analyzer" créée
- [ ] `SKILL.md` avec frontmatter YAML
- [ ] Instructions d'extraction (obligations, clauses)
- [ ] Mise à jour table `AI_Job` après completion
- [ ] Retry stratégies configurées
- [ ] Logs des jobs visibles

---

## 📊 SUIVI D'AVANCEMENT

### État des Sprints

| Sprint | Status | Date début | Date fin | Notes |
|--------|--------|------------|----------|-------|
| Prompt 0 (System) | ⏳ En attente | — | — | À valider |
| Sprint 1 (DB) | ⏳ En attente | — | — | Après Prompt 0 |
| Sprint 2 (Infra) | ⏳ En attente | — | — | Après Sprint 1 |
| Sprint 3 (UI) | ⏳ En attente | — | — | Après Sprint 2 |
| Sprint 4 (Chat) | ⏳ En attente | — | — | Après Sprint 3 |
| Sprint 5 (Jobs) | ⏳ En attente | — | — | Après Sprint 4 |

### Règles d'exécution
1. **Séquentiel uniquement** — Pas de sprints en parallèle
2. **Validation obligatoire** — Tester chaque sprint avant de passer au suivant
3. **Prompt en anglais** — Standard pour maximiser la compréhension des LLMs
4. **Règles de sécurité OpenClaw** — Respecter les contraintes à chaque étape

---

## 🔒 RÈGLES DE SÉCURITÉ (Rappel)

| Règle | Détail | Référence |
|-------|--------|-----------|
| Node.js 24 | Runtime obligatoire dans les containers OpenClaw | [2] |
| 2GB RAM | Minimum par container OpenClaw | [3] |
| Bind 127.0.0.1 | Gateway sur port 18789 uniquement | [1] |
| memoryFlush | softThresholdTokens: 4000 | [4] |
| Pas de ClawHub | Skills custom uniquement (SKILL.md) | [5, 6] |
| Gateway Token | OPENCLAW_GATEWAY_TOKEN obligatoire | [7] |

---

## 🗂️ ARCHITECTURE CIBLE

```
┌─────────────────────────────────────────────────┐
│                  Frontend                        │
│         Next.js 15 + shadcn/ui + Tailwind       │
│            Zustand + React Query                 │
└──────────────────┬──────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────┐
│                Backend API                       │
│        Next.js API Routes + BullMQ + Redis       │
└──────┬────────────────────────────────┬─────────┘
       │                                │
┌──────▼──────┐  ┌──────────────┐  ┌───▼──────────┐
│ PostgreSQL  │  │    Redis     │  │  OpenClaw    │
│   16 +      │  │     7        │  │  Containers  │
│  Prisma     │  │  (BullMQ)    │  │  (per tenant)│
└─────────────┘  └──────────────┘  └──────────────┘
```

### Flux de données
1. **Utilisateur** → Frontend (Next.js)
2. **Frontend** → Backend API (chat, upload, actions)
3. **Backend** → OpenClaw Gateway (127.0.0.1:18789)
4. **OpenClaw** → Traitement IA → Résultat JSON
5. **Backend** → PostgreSQL (persistance)
6. **Backend** → Frontend (streaming via SSE/WebSocket)

---

## 📁 STRUCTURE DU PROJET

```
lexiclaw-v3/
├── app/
│   ├── (app)/
│   │   ├── layout.tsx          # Layout principal (sidebar + topbar)
│   │   ├── dashboard/
│   │   ├── cases/
│   │   │   └── [caseId]/
│   │   │       ├── page.tsx    # Vue dossier
│   │   │       └── chat/       # Chat contextuel
│   │   ├── chat/               # Chat global
│   │   └── settings/
│   ├── api/
│   │   ├── chat/route.ts       # Proxy OpenClaw
│   │   ├── jobs/route.ts       # BullMQ jobs
│   │   └── auth/               # Auth endpoints
│   └── (auth)/
│       ├── login/
│       └── register/
├── components/
│   ├── ui/                     # shadcn/ui components
│   ├── chat/
│   │   └── WorkspaceChat.tsx   # Composant chat principal
│   └── layout/
│       ├── Sidebar.tsx
│       └── Topbar.tsx
├── lib/
│   ├── prisma.ts               # Client Prisma
│   ├── auth.ts                 # Auth config
│   ├── openclaw.ts             # Client OpenClaw
│   └── bullmq.ts               # Queue setup
├── workers/
│   └── ai-worker.ts            # BullMQ worker
├── skills/
│   └── legal-analyzer/
│       └── SKILL.md            # Custom skill
├── prisma/
│   └── schema.prisma           # Schéma DB
├── docker-compose.yml          # Infrastructure
├── openclaw-config/
│   └── generate-config.sh      # Génération openclaw.json
├── package.json
├── tailwind.config.ts
├── tsconfig.json
└── .env
```

---

## 📝 NOTES

### Leçons apprises (V1 & V2)
- **SQLite → PostgreSQL** : Toujours utiliser PostgreSQL dès le départ
- **Monolithe → Séparation** : Backend API séparé du frontend
- **Polling → BullMQ** : Queue robuste pour les tâches async
- **Skills externes → Custom** : Pas de ClawHub (sécurité)
- **Node.js version** : Utiliser Node 24 (performance WebSocket)

### Références
- [1] CVE-2026-25253 — Vulnérabilité RCE OpenClaw Gateway
- [2] Node.js 24 — WebSocket latency et memory footprint
- [3] 2GB RAM — Minimum pour éviter les crashes UI
- [4] compaction.memoryFlush — Sécurité pour long reviews
- [5] ClawHavoc — Attaque supply chain sur ClawHub
- [6] SKILL.md — Format custom skills OpenClaw
- [7] OPENCLAW_GATEWAY_TOKEN — Authentification gateway
- [8] Gateway WebSocket API / OpenAI-compatible HTTP

---

*Document créé le 31 Mars 2026 — LexiClaw V3*
