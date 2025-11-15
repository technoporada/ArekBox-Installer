#!/usr/bin/env bash
# ArekBox - Complete installer and modular manager
# Single script that creates modular structure under ~/arekbox with safe placeholders
# and fixed optimize module. Designed for Debian/Ubuntu-like distributions.
set -uo pipefail
IFS=$'\n\t'

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Directory paths
AREKBOX_DIR="${HOME}/arekbox"
MODULES_DIR="${AREKBOX_DIR}/modules"
VENVS_DIR="${AREKBOX_DIR}/venvs"
LOGS_DIR="${AREKBOX_DIR}/logs"
BACKUPS_DIR="${AREKBOX_DIR}/backups"
CONFIGS_DIR="${AREKBOX_DIR}/configs"

# Utility functions
safe_mkdir() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        echo -e "${RED}safe_mkdir: brak argumentu${NC}" >&2
        return 1
    fi
    if ! mkdir -p "$dir" 2>/dev/null; then
        echo -e "${RED}Nie udało się utworzyć: $dir${NC}" >&2
        return 1
    fi
}

pause() {
    read -rp "Naciśnij ENTER, aby kontynuować..." _dummy
}

# ============== Module creators ==============

create_ai_tools_module() {
    cat > "${MODULES_DIR}/ai_tools.sh" <<'EOF'
#!/usr/bin/env bash
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
pause() { read -rp "Naciśnij ENTER..." _; }

ai_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== AI TOOLS MENU ===${NC}"
        echo "1) Zainstaluj Ollama"
        echo "2) Zarządzaj modelami Ollama"
        echo "3) Uruchom interfejs webowy Ollama"
        echo "4) Zainstaluj Open WebUI (docker)"
        echo "5) TTS Tools (espeak, festival)"
        echo "6) Zainstaluj Whisper (open-source)"
        echo "7) OSINT Tools"
        echo "8) Chatbot lokalny (Python)"
        echo "9) Status usług AI"
        echo "0) Powrót do menu głównego"
        read -rp "Wybierz opcję: " choice
        case "$choice" in
            1) install_ollama ;;
            2) manage_ollama_models ;;
            3) run_ollama_webui ;;
            4) install_open_webui ;;
            5) install_tts_tools ;;
            6) install_whisper ;;
            7) osint_tools_menu ;;
            8) run_local_chatbot ;;
            9) check_ai_services ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_ollama() {
    echo -e "${CYAN}Instalacja Ollama...${NC}"
    if ! command -v curl &>/dev/null; then
        echo "curl wymagany. Instalacja curl..."
        sudo apt update && sudo apt install -y curl || true
    fi
    curl -fsSL https://ollama.com/install.sh | sh || echo "Uwaga: instalacja mogła się nie powiedzieć"
    if systemctl list-unit-files 2>/dev/null | grep -qi ollama; then
        sudo systemctl enable --now ollama || true
    fi
    echo -e "${GREEN}Ollama - jeśli dostępne - zainstalowane (sprawdź logi).${NC}"
    pause
}

manage_ollama_models() {
    if ! command -v ollama &>/dev/null; then
        echo "ollama nieznaleziony. Najpierw zainstaluj Ollama."
        pause
        return
    fi
    while true; do
        clear
        echo -e "${CYAN}=== ZARZĄDZANIE MODELAMI OLLAMA ===${NC}"
        echo "1) Lista dostępnych modeli"
        echo "2) Pobierz nowy model"
        echo "3) Usuń model"
        echo "4) Uruchom model interaktywnie"
        echo "0) Powrót"
        read -rp "Wybierz opcję: " choice
        case "$choice" in
            1) ollama list || echo "Brak modeli"; pause ;;
            2) read -rp "Nazwa modelu (np. llama3.2:1b): " model; ollama pull "$model" || echo "Błąd pobierania"; pause ;;
            3) ollama list; read -rp "Nazwa modelu do usunięcia: " model; ollama rm "$model" || echo "Błąd usuwania"; pause ;;
            4) ollama list; read -rp "Nazwa modelu do uruchomienia: " model; ollama run "$model" || echo "Błąd uruchamiania" ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja${NC}"; pause ;;
        esac
    done
}

run_ollama_webui() {
    echo -e "${CYAN}Uruchamianie interfejsu webowego Ollama (jeśli zainstalowane)...${NC}"
    echo "Sprawdź http://localhost:11434"
    pause
}

install_open_webui() {
    echo -e "${CYAN}Instalacja Open WebUI przez Docker...${NC}"
    if ! command -v docker &>/dev/null; then
        echo "Docker nie jest zainstalowany. Instalacja..."
        curl -fsSL https://get.docker.com | sh || echo "Docker install failed"
        sudo usermod -aG docker "$USER" || true
        echo "Po instalacji Docker wyloguj się i zaloguj ponownie."
        pause
        return
    fi
    docker run -d -p 3000:8080 --add-host=host.docker.internal:host-gateway \\
        -v open-webui:/app/backend/data --name open-webui --restart always \\
        ghcr.io/open-webui/open-webui:main || echo "Uruchomienie Dockera mogło się nie powiedzieć"
    pause
}

install_tts_tools() {
    echo -e "${CYAN}Instalacja narzędzi TTS...${NC}"
    sudo apt update && sudo apt install -y espeak festival || true
    python3 -m venv "${HOME}/.arekbox-venv-tts" 2>/dev/null || true
    source "${HOME}/.arekbox-venv-tts/bin/activate" 2>/dev/null || true
    pip install --upgrade pip setuptools wheel &>/dev/null || true
    pip install pyttsx3 gTTS &>/dev/null || true
    deactivate 2>/dev/null || true
    echo -e "${GREEN}TTS zainstalowane (lokalne venv).${NC}"
    pause
}

install_whisper() {
    echo -e "${CYAN}Instalacja whisper (faster-whisper jeśli możliwe)...${NC}"
    python3 -m pip install --user faster-whisper &>/dev/null || python3 -m pip install --user openai-whisper &>/dev/null
    echo -e "${GREEN}Whisper zainstalowany w user site-packages.${NC}"
    pause
}

run_local_chatbot() {
    if [[ ! -f "${HOME}/arekbox/chatbot.py" ]]; then
        cat > "${HOME}/arekbox/chatbot.py" <<'PY'
#!/usr/bin/env python3
import requests, sys
def chat_with_ollama(prompt, model="llama3.2:3b"):
    url = "http://localhost:11434/api/generate"
    data = {"model": model, "prompt": prompt, "stream": False}
    try:
        r = requests.post(url, json=data, timeout=10)
        r.raise_for_status()
        return r.json().get('response') or str(r.json())
    except Exception as e:
        return f"Błąd połączenia: {e}"
if __name__=='__main__':
    print('=== ArekBox AI Chatbot ===')
    while True:
        q = input('Ty: ')
        if not q or q.lower() in ['q','quit','exit']:
            break
        print('AI:', chat_with_ollama(q))
PY
        chmod +x "${HOME}/arekbox/chatbot.py"
    fi
    python3 "${HOME}/arekbox/chatbot.py"
}

check_ai_services() {
    echo -e "${CYAN}Sprawdzam usługi AI...${NC}"
    if systemctl list-unit-files 2>/dev/null | grep -qi ollama; then
        systemctl is-active --quiet ollama && echo -e "${GREEN}Ollama active${NC}" || echo -e "${YELLOW}Ollama installed but not active${NC}"
    fi
    if command -v docker &>/dev/null && docker ps --format '{{.Names}}' 2>/dev/null | grep -q open-webui; then
        echo -e "${GREEN}Open WebUI (docker) uruchomione${NC}"
    fi
    pause
}

ai_tools_menu
EOF
    chmod +x "${MODULES_DIR}/ai_tools.sh"
}
create_other_modules() {
    # Dev tools module
    cat > "${MODULES_DIR}/dev_tools.sh" <<'EOF'
#!/usr/bin/env bash
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
pause() { read -rp "Naciśnij ENTER..." _; }

dev_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZI DEVELOPERSKIE ===${NC}"
        echo "1) Instaluj Node.js + npm"
        echo "2) Zarządzaj środowiskami Python"
        echo "3) Instaluj Docker"
        echo "4) Instaluj Git + konfiguracja"
        echo "0) Powrót"
        read -rp "Wybierz opcję: " choice
        case "$choice" in
            1) install_nodejs ;;
            2) manage_python_envs ;;
            3) install_docker ;;
            4) install_git ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_nodejs() {
    echo -e "${CYAN}Instalacja Node.js (LTS)...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - || echo "node setup failed"
    sudo apt-get install -y nodejs || echo "apt install nodejs failed"
    node --version 2>/dev/null || echo "Node installation may have failed"
    pause
}

manage_python_envs() {
    echo -e "${CYAN}Zarządzanie venvs w ${HOME}/arekbox/venvs${NC}"
    echo "Dostępne polecenia: create <name>, list, activate <name>, remove <name>"
    read -rp "> " input
    local cmd=$(echo "$input" | awk '{print $1}')
    local args=$(echo "$input" | cut -d' ' -f2-)
    case "$cmd" in
        create)
            python3 -m venv "${HOME}/arekbox/venvs/$args" && echo "Utworzono venv $args" || echo "Błąd"
            ;;
        list)
            ls -1 "${HOME}/arekbox/venvs" 2>/dev/null || echo "Brak"
            ;;
        activate)
            echo "source ${HOME}/arekbox/venvs/$args/bin/activate"
            ;;
        remove)
            rm -rf "${HOME}/arekbox/venvs/$args" && echo "Usunięto $args" || echo "Błąd"
            ;;
        *) echo "Nieznane polecenie" ;;
    esac
    pause
}

install_docker() {
    echo -e "${CYAN}Instalacja Docker...${NC}"
    curl -fsSL https://get.docker.com | sh || echo "Docker install failed"
    sudo usermod -aG docker "$USER" || true
    echo "Wyloguj się i zaloguj ponownie, aby zmiana grupy była aktywna."
    pause
}

install_git() {
    echo -e "${CYAN}Instalacja Git...${NC}"
    sudo apt update && sudo apt install -y git || echo "apt install failed"
    read -rp "Twoje imię i nazwisko (git): " git_name
    read -rp "Twój email (git): " git_email
    git config --global user.name "$git_name" || true
    git config --global user.email "$git_email" || true
    git config --global init.defaultBranch main || true
    echo -e "${GREEN}Git skonfigurowany${NC}"
    pause
}

dev_tools_menu
EOF
    chmod +x "${MODULES_DIR}/dev_tools.sh"

    # Multimedia tools
    cat > "${MODULES_DIR}/multimedia_tools.sh" <<'EOF'
#!/usr/bin/env bash
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
pause() { read -rp "Naciśnij ENTER..." _; }

multimedia_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== MULTIMEDIA ===${NC}"
        echo "1) yt-dlp + mpv setup"
        echo "2) FFmpeg scripts"
        echo "0) Powrót"
        read -rp "Wybierz: " c
        case "$c" in
            1) install_ytdlp ;;
            2) install_ffmpeg_tools ;;
            0) return ;;
            *) echo "Niepoprawne"; pause ;;
        esac
    done
}

install_ytdlp(){
    python3 -m venv "${HOME}/arekbox/venvs/media" 2>/dev/null || true
    source "${HOME}/arekbox/venvs/media/bin/activate" 2>/dev/null || true
    pip install --upgrade pip &>/dev/null || true
    pip install yt-dlp &>/dev/null || true
    deactivate 2>/dev/null || true
    cat > "${HOME}/arekbox/ytdlp.sh" <<'YTD'
#!/bin/bash
source "${HOME}/arekbox/venvs/media/bin/activate"
"${HOME}/arekbox/venvs/media/bin/yt-dlp" "$@"
YTD
    chmod +x "${HOME}/arekbox/ytdlp.sh"
    sudo ln -sf "${HOME}/arekbox/ytdlp.sh" /usr/local/bin/ytdlp || true
    echo -e "${GREEN}yt-dlp zainstalowane${NC}"
    pause
}

install_ffmpeg_tools(){
    sudo apt update && sudo apt install -y ffmpeg mediainfo || true
    mkdir -p "${HOME}/arekbox/ffmpeg-scripts"
    cat > "${HOME}/arekbox/ffmpeg-scripts/convert-to-mp4.sh" <<'F'
#!/bin/bash
if [ -z "$1" ]; then echo "Użycie: $0 <plik>"; exit 1; fi
IN="$1"; OUT="${IN%.*}.mp4"
ffmpeg -i "$IN" -c:v libx264 -c:a aac -preset medium -crf 23 "$OUT"
F
    chmod +x "${HOME}/arekbox/ffmpeg-scripts"/*.sh 2>/dev/null || true
    echo -e "${GREEN}FFmpeg scripts created${NC}"
    pause
}

multimedia_menu
EOF
    chmod +x "${MODULES_DIR}/multimedia_tools.sh"

    # Security tools
    cat > "${MODULES_DIR}/security_tools.sh" <<'EOF'
#!/usr/bin/env bash
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
pause() { read -rp "Naciśnij ENTER..." _; }

security_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== SECURITY ===${NC}"
        echo "1) Configure UFW"
        echo "2) Install ClamAV"
        echo "3) Install Fail2ban"
        echo "0) Powrót"
        read -rp "Wybierz: " c
        case "$c" in
            1) configure_ufw ;;
            2) install_clamav ;;
            3) install_fail2ban ;;
            0) return ;;
            *) echo "Niepoprawne"; pause ;;
        esac
    done
}

configure_ufw(){
    sudo apt update && sudo apt install -y ufw || true
    sudo ufw --force reset || true
    sudo ufw default deny incoming || true
    sudo ufw default allow outgoing || true
    sudo ufw allow ssh || true
    sudo ufw allow 80/tcp || true
    sudo ufw allow 443/tcp || true
    sudo ufw --force enable || true
    sudo ufw status verbose || true
    pause
}

install_clamav(){
    sudo apt update && sudo apt install -y clamav clamav-daemon || true
    sudo freshclam || true
    cat > "${HOME}/arekbox/clamav-scan.sh" <<'C'
#!/bin/bash
LOG="${HOME}/arekbox/logs/clamav-$(date +%Y%m%d).log"
echo "Scan: $(date)" >> "$LOG"
clamscan -r /home/"$USER" --log="$LOG" --infected
C
    chmod +x "${HOME}/arekbox/clamav-scan.sh" || true
    echo -e "${GREEN}ClamAV ready${NC}"
    pause
}

install_fail2ban(){
    sudo apt update && sudo apt install -y fail2ban || true
    sudo systemctl enable --now fail2ban || true
    echo -e "${GREEN}Fail2ban installed${NC}"
    pause
}

security_menu
EOF
    chmod +x "${MODULES_DIR}/security_tools.sh"
}
create_optimize_tools() {
    cat > "${MODULES_DIR}/optimize_tools.sh" <<'EOF'
#!/usr/bin/env bash
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
pause() { read -rp "Naciśnij ENTER..." _; }

optimize_menu(){
    while true; do
        clear
        echo -e "${CYAN}=== OPTYMALIZACJA SYSTEMU ===${NC}"
        echo "1) Czyszczenie systemu"
        echo "2) Zarządzanie pakietami"
        echo "3) Optymalizacja dysku"
        echo "4) Monitorowanie zasobów"
        echo "0) Powrót"
        read -rp "Wybierz: " c
        case "$c" in
            1) system_cleanup ;;
            2) package_management ;;
            3) disk_optimization ;;
            4) resource_monitoring ;;
            0) return ;;
            *) echo "Niepoprawne"; pause ;;
        esac
    done
}

system_cleanup(){
    echo -e "${CYAN}Czyszczenie systemu - uwaga na polecenia z uprawnieniami root${NC}"
    echo "1) Podstawowe (apt autoremove/clean)"
    echo "2) Głębokie (cache + temp)"
    echo "3) Czyszczenie logów starszych niż 30 dni"
    read -rp "Wybierz: " choice
    case "$choice" in
        1)
            sudo apt autoremove -y || true
            sudo apt autoclean || true
            sudo apt clean || true
            ;;
        2)
            sudo apt autoremove -y || true
            sudo apt autoclean || true
            sudo apt clean || true
            rm -rf "${HOME}/.cache/thumbnails"/* 2>/dev/null || true
            rm -rf "${HOME}/.cache/mozilla"/* 2>/dev/null || true
            sudo rm -rf /tmp/* 2>/dev/null || true
            sudo rm -rf /var/tmp/* 2>/dev/null || true
            ;;
        3)
            sudo journalctl --vacuum-time=7d || true
            sudo find /var/log -type f -name "*.log" -mtime +30 -exec sudo rm -f {} \; 2>/dev/null || true
            ;;
        *) echo "Anulowano" ;;
    esac
    echo -e "${GREEN}Czyszczenie zakończone (sprawdź logi).${NC}"
    pause
}

package_management(){
    echo -e "${CYAN}Aktualizacja systemu i pakietów...${NC}"
    sudo apt update && sudo apt upgrade -y || echo "Aktualizacja nie powiodła się"
    pause
}

disk_optimization(){
    echo -e "${CYAN}Sprawdzanie miejsca na dysku...${NC}"
    df -h
    echo -e "${CYAN}Top 10 największych katalogów w $HOME:${NC}"
    du -hs "${HOME}"/* 2>/dev/null | sort -hr | head -n 10
    pause
}

resource_monitoring(){
    echo -e "${CYAN}Monitorowanie zasobów (htop jeśli zainstalowany)...${NC}"
    if command -v htop &>/dev/null; then
        htop
    else
        top
    fi
}

optimize_menu
EOF
    chmod +x "${MODULES_DIR}/optimize_tools.sh"
}

create_root_launcher() {
    cat > "${AREKBOX_DIR}/arekbox.sh" <<'EOF'
#!/usr/bin/env bash
MODULES_DIR="${HOME}/arekbox/modules"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
pause() { read -rp "Naciśnij ENTER..." _; }

main_menu(){
    while true; do
        clear
        echo -e "${CYAN}=== AREKBOX - MENU GŁÓWNE ===${NC}"
        echo "1) AI Tools"
        echo "2) Dev Tools"
        echo "3) Multimedia"
        echo "4) Security"
        echo "5) Optimization"
        echo "99) Utwórz strukturę katalogów i plików"
        echo "0) Wyjście"
        read -rp "Wybierz: " ch
        case "$ch" in
            1) [ -f "${MODULES_DIR}/ai_tools.sh" ] && bash "${MODULES_DIR}/ai_tools.sh" || echo "Brak modułu AI"; pause ;;
            2) [ -f "${MODULES_DIR}/dev_tools.sh" ] && bash "${MODULES_DIR}/dev_tools.sh" || echo "Brak modułu Dev"; pause ;;
            3) [ -f "${MODULES_DIR}/multimedia_tools.sh" ] && bash "${MODULES_DIR}/multimedia_tools.sh" || echo "Brak modułu Multimedia"; pause ;;
            4) [ -f "${MODULES_DIR}/security_tools.sh" ] && bash "${MODULES_DIR}/security_tools.sh" || echo "Brak modułu Security"; pause ;;
            5) [ -f "${MODULES_DIR}/optimize_tools.sh" ] && bash "${MODULES_DIR}/optimize_tools.sh" || echo "Brak modułu Optimization"; pause ;;
            99) bash "${HOME}/arekbox/setup_structure.sh" || echo "Setup script not found"; pause ;;
            0) echo -e "${GREEN}Do widzenia!${NC}"; exit 0 ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

main_menu
EOF
    chmod +x "${AREKBOX_DIR}/arekbox.sh"
}

setup_structure() {
    echo -e "${CYAN}Inicjalizacja ArekBox - tworzenie struktury...${NC}"
    safe_mkdir "${AREKBOX_DIR}"
    safe_mkdir "${MODULES_DIR}"
    safe_mkdir "${VENVS_DIR}"
    safe_mkdir "${LOGS_DIR}"
    safe_mkdir "${BACKUPS_DIR}"
    safe_mkdir "${CONFIGS_DIR}"
    
    create_ai_tools_module
    create_other_modules
    create_optimize_tools
    create_root_launcher
    
    # Fix permissions
    chmod -R u+rwX "${AREKBOX_DIR}" 2>/dev/null || true
    
    echo -e "${GREEN}Gotowe. ArekBox utworzony w: ${AREKBOX_DIR}${NC}"
    echo "Uruchom: bash ${AREKBOX_DIR}/arekbox.sh"
}

# Main execution
main() {
    setup_structure
}

main "$@"
