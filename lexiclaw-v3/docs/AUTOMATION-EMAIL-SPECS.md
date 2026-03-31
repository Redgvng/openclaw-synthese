# 📄 Spécifications Techniques : Automatisation Proactive & Messagerie

**Document de référence pour LexiClaw V3**  
**Intégration : Architecture multi-tenant + Heartbeat + Email**

---

## 1. Le Moteur d'Automatisation : Le "Heartbeat"

Pour qu'OpenClaw agisse comme un véritable assistant autonome (et non comme un simple chatbot réactif), le système s'appuie sur un mécanisme de planification natif appelé **"Heartbeat"** (Battement de cœur).

### Fonctionnement Core

- Le Heartbeat **déclenche périodiquement** un cycle de réflexion de l'agent en arrière-plan
- Fréquence par défaut : **30 minutes** (configurable via `openclaw.json`, ex: `every: "30m"`)
- L'agent s'appuie sur une **checklist** dans le fichier `HEARTBEAT.md`

### Le fichier HEARTBEAT.md

C'est ici que l'on définit les tâches récurrentes du cabinet :

```markdown
# Heartbeat — LexiClaw V3

## Checklist
- [ ] Vérifier les nouveaux emails
- [ ] Extraire les dates d'audience
- [ ] Mettre à jour le CRM
- [ ] Vérifier les deadlines critiques
- [ ] Générer les rappels automatiques
```

### Optimisation des coûts

Pour éviter de consommer des tokens API inutilement :

| Paramètre | Valeur | Effet |
|-----------|--------|-------|
| `lightContext: true` | Recommandé | Vérifications déterministes d'abord, IA complète seulement si nouvelles infos |
| `lightContext: false` | Défaut | Appel IA à chaque heartbeat (coûteux) |

**Flux optimisé :**
```
Heartbeat (30min)
  → Vérification déterministe (IMAP check, DB query)
    → Si nouvelles données ?
      → OUI → Appel modèle IA complet
      → NON → Skip (économie de tokens)
```

---

## 2. Connectivité des Boîtes Mail (Gmail & Outlook)

L'intégration des emails permet à l'agent de trier, résumer et préparer des brouillons de réponse. LexiClaw V3 supporte deux modèles d'intégration selon le niveau de maturité souhaité.

### A. Intégration IMAP/SMTP (MVP & Petits cabinets)

Méthode la plus rapide à déployer — nécessite uniquement un mot de passe d'application.

#### Configuration Gmail

1. L'utilisateur active la **validation en deux étapes** sur son compte Google
2. Génère un **"Mot de passe d'application"** (16 caractères)
3. Configure dans LexiClaw → Paramètres → Email

#### Paramètres serveur

| Service | Serveur | Port | Sécurité |
|---------|---------|------|----------|
| **Lecture (IMAP)** | `imap.gmail.com` | 993 | SSL/TLS |
| **Envoi (SMTP)** | `smtp.gmail.com` | 465 ou 587 | SSL/TLS |
| **Lecture (Outlook)** | `outlook.office365.com` | 993 | SSL/TLS |
| **Envoi (Outlook)** | `smtp.office365.com` | 587 | STARTTLS |

#### Stockage des credentials

```prisma
model EmailCredentials {
  id          String   @id @default(cuid())
  tenantId    String
  userId      String
  provider    String   // "gmail" | "outlook"
  email       String
  imapServer  String
  imapPort    Int      @default(993)
  smtpServer  String
  smtpPort    Int      @default(587)
  appPassword String   // Chiffré au repos
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  
  tenant      Tenant   @relation(fields: [tenantId], references: [id])
  user        User     @relation(fields: [userId], references: [id])
  
  @@unique([tenantId, email])
}
```

---

### B. Intégration OAuth2 (Standard "Entreprise")

Méthode la plus sécurisée et fluide pour l'utilisateur final (bouton "Se connecter avec Google").

#### Configuration GCP

1. Créer un projet **Google Cloud Platform**
2. Activer l'**API Gmail**
3. Configurer un **écran de consentement OAuth**
4. Créer un **Client ID OAuth 2.0** (type "Desktop app")
5. Récupérer :
   - `GOOGLE_CLIENT_ID`
   - `GOOGLE_CLIENT_SECRET`
   - `GOOGLE_REDIRECT_URI`

#### Flux OAuth2

```
Utilisateur clique "Se connecter avec Google"
  → Redirection vers Google OAuth
  → Autorisation par l'utilisateur
  → Callback avec authorization_code
  → Échange code → access_token + refresh_token
  → Stockage sécurisé des tokens
  → Rafraîchissement automatique (avant expiration)
```

#### Stockage des tokens OAuth

```prisma
model OAuthToken {
  id           String   @id @default(cuid())
  tenantId     String
  userId       String
  provider     String   // "google" | "microsoft"
  accessToken  String   // Chiffré
  refreshToken String   // Chiffré
  expiresAt    DateTime
  scope        String
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  tenant       Tenant   @relation(fields: [tenantId], references: [id])
  user         User     @relation(fields: [userId], references: [id])
  
  @@unique([tenantId, userId, provider])
}
```

#### Avantages OAuth2 vs IMAP

| Critère | IMAP/SMTP | OAuth2 |
|---------|-----------|--------|
| Sécurité | Mot de passe app | Token temporaire |
| UX | Configuration manuelle | 1 clic |
| Maintenance | Renouvellement manuel | Auto-refresh |
| Scopes | Tous ou rien | Granulaire |
| Audit | Limité | Traçable |

---

## 3. Déploiement et Provisionning par Client (Multi-Tenant)

Le processus de création d'un agent pour un nouveau cabinet d'avocats doit être **100% automatisé et isolé** pour garantir le secret professionnel.

### Isolation des Conteneurs

Chaque client obtient son propre conteneur Docker OpenClaw :

```
┌─────────────────────────────────────────────────┐
│              Backend API (Next.js)               │
└──────┬──────────────────────┬───────────────────┘
       │                      │
┌──────▼──────┐        ┌──────▼──────┐
│ OpenClaw    │        │ OpenClaw    │
│ Tenant A    │        │ Tenant B    │
│ (Cabinet X) │        │ (Cabinet Y) │
│             │        │             │
│ 127.0.0.1   │        │ 127.0.0.1   │
│ :18789      │        │ :18790      │
└─────────────┘        └─────────────┘
```

### Règles de sécurité

| Règle | Implémentation | Référence |
|-------|----------------|-----------|
| **Network Isolation** | Gateway écoute sur 127.0.0.1 uniquement (jamais exposé publiquement) | [1] |
| **Secrets Management** | Credentials injectés via variables d'environnement `.env` à la création du conteneur | [2] |
| **Pas de secrets en clair** | Jamais dans les prompts ou la logique des workflows | [2] |
| **Chiffrement au repos** | Tokens OAuth et mots de passe chiffrés en DB | [2] |

### Script de provisioning

```bash
#!/bin/bash
# provision-tenant.sh

TENANT_ID=$1
TENANT_NAME=$2
OPENCLAW_PORT=$3

# 1. Créer le namespace DB
psql -c "CREATE SCHEMA tenant_${TENANT_ID};"

# 2. Générer openclaw.json
cat > ./tenants/${TENANT_ID}/openclaw.json << EOF
{
  "gateway": {
    "bind": "127.0.0.1",
    "port": ${OPENCLAW_PORT},
    "token": "${OPENCLAW_GATEWAY_TOKEN}"
  },
  "compaction": {
    "memoryFlush": true,
    "softThresholdTokens": 4000
  }
}
EOF

# 3. Lancer le conteneur
docker run -d \
  --name "openclaw-${TENANT_ID}" \
  --memory=2g \
  -p "127.0.0.1:${OPENCLAW_PORT}:${OPENCLAW_PORT}" \
  -e "OPENCLAW_GATEWAY_TOKEN=${OPENCLAW_GATEWAY_TOKEN}" \
  -e "DATABASE_URL=postgresql://..." \
  -v "./tenants/${TENANT_ID}:/app/config" \
  openclaw:node24

# 4. Enregistrer dans la DB
psql -c "INSERT INTO openclaw_instances (tenant_id, name, url, status) VALUES ('${TENANT_ID}', '${TENANT_NAME}', 'http://127.0.0.1:${OPENCLAW_PORT}', 'running');"
```

### Sécurité des secrets

| Secret | Stockage | Injection |
|--------|----------|-----------|
| `OPENCLAW_GATEWAY_TOKEN` | Vault / env sécurisé | `.env` au runtime |
| `DATABASE_URL` | Vault / env sécurisé | `.env` au runtime |
| IMAP password | Chiffré en DB | Variable env container |
| OAuth tokens | Chiffré en DB | Variable env container |
| API keys LLM | Vault | Variable env container |

---

## 4. Approbation Humaine (Garde-fous)

Pour des actions critiques, l'agent doit **demander une approbation explicite** avant exécution.

### Actions nécessitant approbation

| Action | Niveau | Comportement |
|--------|--------|--------------|
| Envoyer un email à un client | 🔴 Critique | Génère brouillon → demande validation |
| Modifier un dossier | 🟡 Important | Demande confirmation |
| Supprimer un document | 🔴 Critique | Demande confirmation + raison |
| Générer une facture | 🟡 Important | Affiche aperçu → demande validation |
| Planifier une audience | 🟡 Important | Vérifie disponibilité → demande confirmation |
| Résumer un document | 🟢 Aucune | Exécute directement |
| Rechercher en base | 🟢 Aucune | Exécute directement |

### Pattern d'approbation

```
IA détecte action critique
  → Génère le brouillon/résultat
  → Affiche dans le chat avec [✅ Approuver] [❌ Refuser] [✏️ Modifier]
  → Attend validation utilisateur
  → Si approuvé → Exécute
  → Si refusé → Annule + log
  → Si modifié → Applique les modifications → Re-demande validation
```

### Configuration dans SKILL.md

```yaml
---
name: email-sender
requiresApproval: true
approvalLevel: critical
approvalMessage: "L'IA souhaite envoyer un email. Veuillez valider."
---
```

---

## 5. Flux complet : Email → Cas → Action

```
┌─────────────┐
│ Nouvel email│
│ reçu (IMAP) │
└──────┬──────┘
       │
┌──────▼──────────────┐
│ Heartbeat détecte   │
│ le nouvel email     │
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│ Classification IA   │
│ (juridique? spam?   │
│  urgent?)           │
└──────┬──────────────┘
       │
┌──────▼──────────────┐     ┌──────────────┐
│ Juridique + Urgent  │────→│ Notification │
└──────┬──────────────┘     │ push/SMS     │
       │                    └──────────────┘
┌──────▼──────────────┐
│ Extraction :        │
│ - Dates d'audience  │
│ - Parties impliquées│
│ - Références dossier│
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│ Matching dossier    │
│ existant ou         │
│ création auto       │
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│ Résumé généré       │
│ + Brouillon réponse │
│ (si nécessaire)     │
└──────┬──────────────┘
       │
┌──────▼──────────────┐
│ Approbation humaine │
│ [✅] [❌] [✏️]       │
└─────────────────────┘
```

---

## 6. Checklist d'implémentation

### Heartbeat
- [ ] Configuration `every: "30m"` dans openclaw.json
- [ ] Fichier `HEARTBEAT.md` avec checklist par tenant
- [ ] `lightContext: true` pour optimisation coûts
- [ ] Vérifications déterministes avant appel IA

### Email IMAP (MVP)
- [ ] Support Gmail (imap.gmail.com:993)
- [ ] Support Outlook (outlook.office365.com:993)
- [ ] Stockage credentials chiffré en DB
- [ ] Configuration via UI (sans ligne de commande)

### Email OAuth2 (Enterprise)
- [ ] Projet GCP configuré
- [ ] API Gmail activée
- [ ] OAuth2 flow complet (authorization → token → refresh)
- [ ] Token refresh automatique
- [ ] Scopes granulaires

### Multi-Tenant
- [ ] Script provisioning automatisé
- [ ] 1 conteneur OpenClaw par client
- [ ] Gateway bind 127.0.0.1 uniquement
- [ ] Secrets via variables d'environnement
- [ ] Pas de credentials dans les prompts

### Approbation humaine
- [ ] Liste des actions critiques définie
- [ ] Pattern brouillon → validation → exécution
- [ ] UI d'approbation dans le chat
- [ ] Logs des validations/refus

---

## Références

- [1] CVE-2026-25253 — Vulnérabilité RCE OpenClaw Gateway
- [2] OpenClaw Security Best Practices — Secrets management

---

*Document de référence technique — LexiClaw V3*
