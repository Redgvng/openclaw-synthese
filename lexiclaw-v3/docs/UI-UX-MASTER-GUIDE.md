# 🎨 LexiClaw V3 — UI/UX Master Guide & Dashboard Architecture

**Document de référence pour le Sprint 3 (UI Shell & Dashboard)**  
**À fournir à l'agent lors du Sprint 3**

---

## Philosophie de Design

> "L'élégance de l'efficacité"

L'interface ne doit pas être un simple espace de stockage de données, mais un outil de communication clair. L'objectif est de réduire la charge cognitive des avocats tout en instaurant une confiance absolue dans les actions de l'IA.

---

## 1. Design Tokens & Thème Sombre (Dark Mode)

Le mode sombre par défaut n'est pas qu'un choix esthétique, c'est une nécessité pour réduire la fatigue oculaire lors des longues sessions de lecture ou de rédaction.

### Palette de couleurs

| Token | Hex | Usage |
|-------|-----|-------|
| **Fond Principal (Anthracite)** | `#1A1A2E` | Background global. Éviter le noir pur (contraste trop agressif) |
| **Surfaces & Cartes (Bleu Nuit)** | `#16213E` | Widgets, cards, panels — détache du fond principal |
| **Accent (Or)** | `#D4AF37` | Actions primaires (boutons, CTA). Utilisé avec parcimonie |
| **Texte Principal** | `#EAEAEA` | Blanc cassé — jamais de blanc pur (#FFFFFF) pour éviter la fatigue |
| **Texte Secondaire** | `#9CA3AF` | Labels, descriptions, hints |
| **Success** | `#10B981` | Confirmations, validations |
| **Error** | `#EF4444` | Erreurs, alertes critiques |
| **Warning** | `#F59E0B` | Avertissements, attention |
| **Info** | `#3B82F6` | Informations, liens |

### Typographie

| Font | Usage | Raison |
|------|-------|--------|
| **Inter** | Interface générale | Lisibilité optimale, poids variés |
| **JetBrains Mono** | Citations juridiques, extraits de code | Monospace clair, lisible |

### Règles visuelles
- ❌ Jamais de blanc pur `#FFFFFF` pour le texte
- ✅ Toujours `#EAEAEA` (blanc cassé) pour le texte principal
- ✅ Couleurs désaturées pour réduire la "vibration visuelle" sur fond sombre
- ✅ Accent Or utilisé avec parcimonie (actions primaires uniquement)

---

## 2. Les 4 Règles d'Or de l'UX pour l'IA Juridique

La conception d'une interface pilotée par l'IA (A2UI) exige de repenser les interactions standards pour garantir la confiance.

### Règle 1 : Trust UI (Transparence)

L'interface doit clairement expliquer comment l'IA prend ses décisions.

- ✅ Ajouter des **liens vers les sources exactes** (citations) dans les textes générés par l'IA
- ✅ Afficher le **degré de confiance** quand c'est pertinent
- ✅ Montrer les **étapes de raisonnement** de l'IA (quand applicable)
- ❌ Ne jamais présenter un résultat IA comme un fait absolu sans source

### Règle 2 : Garder le contrôle (Human-in-the-Loop)

L'utilisateur doit toujours avoir le dernier mot.

- ✅ Bouton **"Annuler"** systématique pour les tâches longues
- ✅ Permettre l'**édition du résultat IA** avant validation finale
- ✅ Confirmation avant toute action irréversible
- ❌ L'IA ne doit jamais exécuter d'action sans validation utilisateur

### Règle 3 : Divulgation Progressive (Progressive Disclosure)

Ne pas montrer toutes les options d'un coup.

- ✅ **Découper les tâches en étapes claires**
- ✅ **Une information principale par écran** ou par section
- ✅ Masquer les options avancées par défaut (accordion, "Plus d'options")
- ❌ Pas de formulaires interminables avec 20 champs visibles

### Règle 4 : Interface d'assistance contextuelle

Ne pas se limiter à un widget de chat dans le coin.

- ✅ **Inline overlay prompts** — menus flottants à la sélection de texte
  - Ex: Sélectionner un paragraphe → menu "Résumer", "Expliquer cette clause", "Vérifier la conformité"
- ✅ **Tooltips intelligents** sur les éléments complexes
- ✅ **Actions contextuelles** adaptées au contenu affiché
- ❌ Pas de chat isolé sans contexte du dossier

---

## 3. Architecture du Dashboard (Basée sur les Rôles)

Un tableau de bord "taille unique" est une erreur en SaaS B2B. L'interface doit s'adapter au rôle de l'utilisateur.

---

### A. Vue "Avocat Associé / Managing Partner" (Macro)

**Objectif :** Stratégie et supervision du cabinet

#### KPIs en en-tête
| KPI | Description | Visualisation |
|-----|-------------|---------------|
| Revenu total | Facturation mensuelle/annuelle | Chiffre + évolution % |
| Revenu par avocat | Productivité individuelle | Bar chart horizontal |
| Taux de réalisation | Dossiers clôturés vs ouverts | Donut chart |
| Facturation en attente | Montants non encore facturés | Chiffre + alerte si > 30 jours |

#### Widgets
| Widget | Type | Description |
|--------|------|-------------|
| **Évolution rentabilité** | Graphique courbes | Revenus vs coûts sur 12 mois |
| **Alertes IA dossiers** | Liste alertes | Dossiers bloqués, dépassement budget, deadlines critiques |
| **Pipeline d'affaires** | Kanban/Flow | Nouveaux prospects → En cours → Clos |
| **Répartition par type** | Pie chart | Contentieux, conseil, transactionnel, etc. |

---

### B. Vue "Avocat Collaborateur" (Micro / Opérationnel)

**Objectif :** Exécution rapide et gestion quotidienne

#### En-tête
- **Barre de recherche Spotlight** (Cmd+K) bien visible
  - Recherche globale : dossiers, documents, clients, contacts
  - Raccourcis clavier affichés
  - Résultats instantanés (debounce 150ms)

#### Widgets principaux

| Widget | Type | Description |
|--------|------|-------------|
| **Mes Dossiers Actifs** | Liste | Accès direct aux espaces de travail avec état d'avancement |
| | | - Nom du dossier |
| | | - Client |
| | | - Statut (En cours / En attente / Urgent) |
| | | - Progression (barre) |
| | | - Dernière activité |
| **Timeline & Deadlines** | Calendrier liste | Rappels générés par l'IA |
| | | - Dates d'audience |
| | | - Conclusions à rendre |
| | | - Rendez-vous clients |
| | | - Deadlines contractuelles |
| **Flux d'actions IA** | Timeline live | État des requêtes asynchrones |
| | | - "Synthèse du dossier X en cours..." |
| | | - "Analyse du contrat Y terminée ✅" |
| | | - "Génération de la conclusion Z..." |
| **Documents récents** | Grille/liste | Derniers fichiers consultés/modifiés |
| **Messages non lus** | Badge liste | Communications en attente |

---

## 4. Composants UI spécifiques

### Spotlight Search (Cmd+K)
```
┌─────────────────────────────────────────┐
│ 🔍 Rechercher dossiers, docs, contacts  │
├─────────────────────────────────────────┤
│ 📁 Dossiers                             │
│   → Affaire Dupont c/ Martin (En cours) │
│   → Contrat SARL Techmine (Urgent)      │
│ 📄 Documents                            │
│   → Conclusions Dupont v2.pdf           │
│   → Note juridique TVA mars.docx        │
│ 👥 Contacts                             │
│   → Maître Lefebvre (Cabinet rival)     │
├─────────────────────────────────────────┤
│ Raccourcis: ↵ Ouvir · ⌘E Éditer        │
└─────────────────────────────────────────┘
```

### AI Action Toast (Notification temps réel)
```
┌──────────────────────────────────────────────────┐
│ ⚡ IA en cours                                    │
│ Analyse du contrat SARL Techmine... ████████░░ 80%│
│                                          [Annuler] │
└──────────────────────────────────────────────────┘
```

### Inline Overlay Prompt (Action contextuelle)
```
Sélection de texte : "Le preneur s'engage à..."
┌─────────────┐
│ 📝 Résumer  │
│ 🔍 Expliquer│
│ ⚖️ Vérifier │
│ 📋 Copier   │
└─────────────┘
```

### Case Workspace (Vue dossier)
```
┌─────────────────────────────────────────────────────┐
│ ← Retour    Affaire Dupont c/ Martin    [⚙️] [🔔]  │
├──────────────┬──────────────────────────────────────┤
│ 📊 Aperçu    │                                      │
│ 📄 Documents │    Zone de contenu principale        │
│ 💬 Chat IA   │    (adaptée à l'onglet sélectionné)  │
│ ⏱️ Chrono    │                                      │
│ 📅 Timeline  │                                      │
│ ⚙️ Paramètres│                                      │
├──────────────┴──────────────────────────────────────┤
│ 💬 Chat contextuel du dossier                       │
│ ┌─────────────────────────────────────────────────┐ │
│ │ [Messages avec citations cliquables]            │ │
│ └─────────────────────────────────────────────────┘ │
│ [Tapez votre message...                    ] [Envoyer]│
└─────────────────────────────────────────────────────┘
```

---

## 5. Règles d'accessibilité & Performance

### Accessibilité
- Contraste minimum **4.5:1** pour le texte (WCAG AA)
- Navigation clavier complète (Tab, Enter, Escape, Cmd+K)
- Labels ARIA sur tous les éléments interactifs
- Focus visible sur les éléments actifs

### Performance
- **LCP < 2.5s** (Largest Contentful Paint)
- **FID < 100ms** (First Input Delay)
- **CLS < 0.1** (Cumulative Layout Shift)
- Skeleton loading pour les données async
- Lazy loading des widgets non visibles
- Debounce sur la recherche (150ms)

### Responsive
- Desktop-first (avocats travaillent principalement sur PC)
- Sidebar collapsible sur tablette
- Navigation bottom bar sur mobile (consultation uniquement)

---

## 6. Patterns d'interaction IA

### Streaming de réponse
- Afficher un indicateur de frappe pendant la génération
- Rendu Markdown incrémental (phrase par phrase)
- Auto-scroll désactivable (bouton "Suivre" / "Arrêter de suivre")
- Citation cliquable → ouvre la source dans un panneau latéral

### Feedback utilisateur
- 👍 / 👎 sur chaque réponse IA (amélioration continue)
- Bouton "Régénérer" pour relancer une réponse
- Bouton "Copier" pour copier la réponse
- Historique des modifications (versioning des réponses)

### États de chargement
| État | Indicateur | Message |
|------|------------|---------|
| En cours | Spinner + barre | "L'IA analyse votre demande..." |
| Long | Barre de progression | "Analyse en cours — ~30s restantes" |
| Succès | ✅ Checkmark | "Analyse terminée" |
| Erreur | ❌ + message | "Une erreur est survenue — [Réessayer]" |
| Annulé | ⚠️ Warning | "Analyse annulée par l'utilisateur" |

---

## 7. Checklist Sprint 3 (UI/UX)

- [ ] Thème dark mode avec tokens exacts (#1A1A2E, #16213E, #D4AF37, #EAEAEA)
- [ ] Typographie Inter + JetBrains Mono
- [ ] Sidebar responsive avec navigation (Dashboard, Cases, Chat, Settings)
- [ ] Topbar avec Spotlight Search (Cmd+K)
- [ ] Dashboard Partner (KPIs + widgets macro)
- [ ] Dashboard Collaborateur (dossiers + timeline + flux IA)
- [ ] Composants inline overlay prompts
- [ ] AI Action Toast (notifications temps réel)
- [ ] Contraste WCAG AA (4.5:1 minimum)
- [ ] Navigation clavier complète
- [ ] Skeleton loading states
- [ ] Responsive (desktop → tablette → mobile)

---

*Document de référence pour le Sprint 3 — LexiClaw V3*
