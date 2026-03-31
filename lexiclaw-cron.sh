#!/bin/bash
# ============================================================
# LexiClaw V3 — Cron Monitor
# Vérifie Claude Code CLI toutes les 5 minutes
# - Si rate limit → MiMo travaille sur le projet
# - Si rate limit reset → relance Claude Code
# ============================================================

ACPX="/root/.openclaw/workspace/extensions/acpx/node_modules/.bin/acpx"
PROJECT_DIR="/root/.openclaw/workspace/lexiclaw-v3"
LOG_FILE="/root/.openclaw/workspace-claude-code/lexiclaw-cron.log"
STATE_FILE="/tmp/lexiclaw-cron-state.json"
SESSION_NAME="lexiclaw-v3-auto"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Vérifier si Claude Code est en rate limit
check_rate_limit() {
    local output
    output=$(cd /root/.openclaw/workspace && timeout 10 $ACPX claude prompt -s "$SESSION_NAME" "ping" 2>&1)
    
    # Détecter rate limit (429, quota, rate limit, too many requests)
    if echo "$output" | grep -qiE "(429|rate.?limit|too many requests|quota exceeded|overloaded)"; then
        echo "rate_limited"
        return 1
    fi
    
    # Détecter erreur de session
    if echo "$output" | grep -qiE "(session.*not found|no.*session|error)"; then
        echo "session_error"
        return 2
    fi
    
    echo "ok"
    return 0
}

# Créer ou récupérer la session Claude Code
ensure_session() {
    local sessions
    sessions=$(cd /root/.openclaw/workspace && $ACPX claude sessions list 2>&1)
    
    # Vérifier si la session existe et est ouverte
    if echo "$sessions" | grep -q "$SESSION_NAME" | grep -qv "\[closed\]"; then
        log "${GREEN}✅ Session $SESSION_NAME active${NC}"
        return 0
    fi
    
    # Créer une nouvelle session
    log "${YELLOW}⏳ Création session $SESSION_NAME...${NC}"
    cd /root/.openclaw/workspace && timeout 15 $ACPX claude sessions new --name "$SESSION_NAME" 2>&1 >> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log "${GREEN}✅ Session $SESSION_NAME créée${NC}"
        return 0
    else
        log "${RED}❌ Échec création session${NC}"
        return 1
    fi
}

# Envoyer un prompt à Claude Code
send_prompt() {
    local prompt="$1"
    local output
    output=$(cd /root/.openclaw/workspace && timeout 60 $ACPX claude prompt -s "$SESSION_NAME" "$prompt" 2>&1)
    echo "$output"
}

# Sauvegarder l'état
save_state() {
    local state="$1"
    local timestamp=$(date +%s)
    echo "{\"state\": \"$state\", \"timestamp\": $timestamp}" > "$STATE_FILE"
}

# Charger l'état précédent
load_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE" | grep -o '"state": "[^"]*"' | cut -d'"' -f4
    else
        echo "unknown"
    fi
}

# Vérifier si le rate limit est peut-être reset (après 5 minutes)
check_reset_window() {
    if [ ! -f "$STATE_FILE" ]; then
        return 0
    fi
    
    local last_timestamp=$(cat "$STATE_FILE" | grep -o '"timestamp": [0-9]*' | cut -d' ' -f2)
    local current_timestamp=$(date +%s)
    local diff=$((current_timestamp - last_timestamp))
    
    # 5 minutes = 300 secondes
    if [ $diff -ge 300 ]; then
        return 0
    else
        return 1
    fi
}

# ============================================================
# LOGIQUE PRINCIPALE
# ============================================================

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "🔄 Vérification cron — $(date '+%H:%M:%S')"

# Étape 1 : S'assurer que la session existe
ensure_session
if [ $? -ne 0 ]; then
    log "${RED}❌ Impossible de créer la session. Abandon.${NC}"
    exit 1
fi

# Étape 2 : Vérifier le statut
STATUS=$(check_rate_limit)
PREV_STATE=$(load_state)

log "📊 Status: $STATUS | État précédent: $PREV_STATE"

case "$STATUS" in
    "ok")
        if [ "$PREV_STATE" = "rate_limited" ]; then
            log "${GREEN}🎉 Rate limit RESET ! Claude Code est de nouveau disponible.${NC}"
            log "${GREEN}🚀 Relance de Claude Code sur le projet...${NC}"
            
            # Envoyer les instructions de reprise
            send_prompt "Continue le développement de LexiClaw V3. Le projet est dans $PROJECT_DIR. Reprends où tu t'étais arrêté."
            save_state "active"
        else
            log "${GREEN}✅ Claude Code opérationnel — pas de changement${NC}"
            save_state "active"
        fi
        ;;
        
    "rate_limited")
        log "${YELLOW}⚠️ RATE LIMIT atteint !${NC}"
        
        if [ "$PREV_STATE" != "rate_limited" ]; then
            log "${YELLOW}📝 Basculement vers MiMo pour travailler sur le projet...${NC}"
            save_state "rate_limited"
            
            # Créer un fichier de statut pour MiMo
            echo "RATE_LIMITED" > /tmp/lexiclaw-claude-status
            echo "$(date +%s)" >> /tmp/lexiclaw-claude-status
            log "${YELLOW}📄 Fichier statut créé — MiMo peut prendre le relais${NC}"
        else
            log "${YELLOW}⏳ Toujours en rate limit — attente du reset${NC}"
        fi
        ;;
        
    "session_error")
        log "${RED}❌ Erreur de session — tentative de recréation...${NC}"
        cd /root/.openclaw/workspace && $ACPX claude sessions close "$SESSION_NAME" 2>/dev/null
        sleep 2
        ensure_session
        save_state "session_error"
        ;;
        
    *)
        log "${RED}❓ Status inconnu: $STATUS${NC}"
        save_state "unknown"
        ;;
esac

log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
