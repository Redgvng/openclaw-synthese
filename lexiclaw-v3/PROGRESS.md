# LexiClaw V3 — Suivi d'avancement

## Status des sprints

| # | Sprint | Status | Date début | Date fin | Validé par |
|---|--------|--------|------------|----------|------------|
| 0 | System Prompt | ⚠️ Skip | 2026-03-31 | 2026-03-31 | Claude a refusé (CVE futures) |
| 1 | Database (Prisma) | ✅ Validé | 2026-03-31 | 2026-03-31 | Red Adaw |
| 2 | Infrastructure (Docker) | ✅ Validé | 2026-03-31 | 2026-03-31 | Red Adaw |
| 3 | UI & Auth (shadcn) | ✅ Validé | 2026-03-31 | 2026-03-31 | Red Adaw |
| 4 | AI Chat (Vercel AI SDK) | ✅ Validé | 2026-03-31 | 2026-03-31 | Red Adaw |
| 5 | Workflows & Skills (BullMQ) | ✅ Validé | 2026-03-31 | 2026-03-31 | Red Adaw |

## Règles
- ✅ Séquentiel uniquement
- ✅ Validation avant sprint suivant
- ✅ Prompts en anglais (originaux du repo)
- ✅ Sécurité OpenClaw respectée
- ⚠️ Prompt 0 skip (Claude a détecté des CVE futures comme injection)

## Notes de progression

### Prompt 0 — Skip (2026-03-31)
Claude Code a refusé le system prompt — considère les références CVE-2026-25253 et "ClawHavoc" comme des prompt injections. Les règles de sécurité sont appliquées manuellement dans docker-compose.yml.

### Sprint 1 — Validé (2026-03-31)
- Next.js 16.2.1 initialisé (TypeScript, Tailwind v4, App Router)
- Prisma 7.6.0 initialisé
- Schema.prisma complet : 7 modèles (Tenant, User, Case, Document, Message, AuditLog, AI_Job)
- Chaque table (sauf Tenant) a un tenantId
- Migration `init` exécutée avec succès sur PostgreSQL 16

### Sprint 2 — Validé (2026-03-31)
- docker-compose.yml créé : PostgreSQL 16 + Redis 7 + 2 containers OpenClaw
- Node.js 24 dans les containers OpenClaw
- 2GB RAM minimum par container
- Bind 127.0.0.1:18789
- OPENCLAW_GATEWAY_TOKEN configuré
- Script de génération openclaw.json avec compaction.memoryFlush
- `docker compose up` fonctionne (postgres + redis healthy)

### Sprint 3 — Validé (2026-03-31)
- shadcn/ui installé (12 composants)
- Thème dark mode appliqué (Anthracite #1A1A2E, Gold #D4AF37)
- Auth flow JWT (jose library)
- tenantId injecté dans la session
- Layout avec sidebar persistante
- Navigation : Dashboard, Cases, Chat, Settings
- Build Next.js réussi (11 pages)
- Composants : Sidebar, Topbar, Button, Input, Table, Card, Avatar, Badge, Dialog, DropdownMenu, ScrollArea, Tabs, Toast

### Sprint 4 — Validé (2026-03-31)
- @ai-sdk/react + ai installés
- Composant <WorkspaceChat /> créé (useChat, streaming, auto-scroll, markdown)
- API Route /api/chat avec proxy OpenClaw par tenant
- Chat intégré dans app/(app)/chat/page.tsx et cases/[caseId]/page.tsx
- Case-anchored system prompt avec contexte dossier

### Sprint 5 — Validé (2026-03-31)
- BullMQ worker (analyze-contract) créé dans workers/
- Queue setup dans lib/queue.ts
- instrumentation.ts pour démarrer le worker au boot
- SKILL.md Legal Document Analyzer créé (skills/legal-analyzer/)
- Extraction: obligations, parties, dates, clauses, risk flags
- Mise à jour table AI_Job après completion
