#!/bin/bash

AREKBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export CYAN='\033[0;36m'
export WHITE='\033[1;37m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export NC='\033[0m'

print_success() { echo -e "${GREEN}[OK]${NC} $1"; }
print_error() { echo -e "${RED}[BŁĄD]${NC} $1"; }
print_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[UWAGA]${NC} $1"; }
pause() { read -p "Naciśnij Enter aby kontynuować..."; }

for mod in "$AREKBOX_DIR"/modules/*.sh; do
    source <(head -n -1 "$mod")
done

MEDIA_VENV="$AREKBOX_DIR/venvs/media"

APT_PKGS="curl wget git python3-pip python3-venv ffmpeg mediainfo exiftool imagemagick whois nmap poppler-utils ghostscript pdftk-java espeak espeak-ng festival festival-dev fzf bat ripgrep htop btop tmux lm-sensors ufw fail2ban clamav clamav-daemon clamav-freshclam mpv"

PIP_PKGS="yt-dlp PyPDF2 pdf2image pyttsx3 gTTS openai-whisper faster-whisper requests beautifulsoup4 lxml dnspython"

bootstrap() {
    print_info "Sprawdzam środowisko ArekBox..."
    if ! sudo -n true 2>/dev/null; then
        print_warning "ArekBox potrzebuje sudo do instalacji pakietów systemowych."
        sudo -v || { print_error "Brak uprawnień sudo — przerwano konfigurację."; return 1; }
    fi

    print_info "Aktualizuję listę pakietów (apt)..."
    sudo apt update -y

    print_info "Instaluję pakiety systemowe: $APT_PKGS"
    # shellcheck disable=SC2086
    sudo apt install -y $APT_PKGS

    if [ ! -d "$MEDIA_VENV" ]; then
        print_info "Tworzę środowisko wirtualne: $MEDIA_VENV"
        python3 -m venv "$MEDIA_VENV"
    fi

    print_info "Instaluję pakiety Python do venvu media..."
    "$MEDIA_VENV/bin/pip" install --upgrade pip setuptools wheel
    # shellcheck disable=SC2086
    "$MEDIA_VENV/bin/pip" install $PIP_PKGS

    print_success "Środowisko ArekBox skonfigurowane!"
    print_info "Binaria (yt-dlp, pdf i inne) są w: $MEDIA_VENV/bin"
}

env_ready() {
    [ -x "$MEDIA_VENV/bin/python" ] && "$MEDIA_VENV/bin/python" -c "import yt_dlp" 2>/dev/null
}

show_help() {
    echo "ArekBox - System Admin Toolkit for Linux"
    echo ""
    echo "Użycie: bash arekbox.sh [OPCJA]"
    echo ""
    echo "Opcje:"
    echo "  --help, -h    Pokaż pomoc"
    echo "  --setup       Zainstaluj środowisko (pakiety apt + venv Python)"
    echo ""
    echo "Uruchom bez opcji, aby otworzyć główne menu."
    echo "Przy pierwszym uruchomieniu ArekBox zaproponuje samodzielną"
    echo "konfigurację środowiska, jeśli ta nie została jeszcze wykonana."
}

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
fi

if [[ "$1" == "--setup" ]]; then
    bootstrap
    exit 0
fi

if ! env_ready; then
    print_warning "Środowisko ArekBox nie jest skonfigurowane."
    read -p "Czy chcesz je zainstalować teraz? (y/N): " setup_choice
    if [[ "$setup_choice" == "y" || "$setup_choice" == "Y" ]]; then
        bootstrap || true
    else
        print_info "Pomięto konfigurację. Niektóre funkcje mogą nie działać."
    fi
fi

export PATH="$MEDIA_VENV/bin:$PATH"

while true; do
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}            🖥️  AREKBOX v1.0                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}     System Admin Toolkit for Linux          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
    echo ""
    echo "1)  AI Tools"
    echo "2)  Dev Tools"
    echo "3)  System Info"
    echo "4)  ThinkPad Fan"
    echo "5)  Backup Tools"
    echo "6)  Gaming Tools"
    echo "7)  Terminal Tools"
    echo "8)  System Optimization"
    echo "9)  PDF Tools"
    echo "10) Security Tools"
    echo "11) Multimedia Tools"
    echo "12) Cleanup Tools"
    echo "0)  Wyjście"
    echo ""
    read -p "Wybierz opcję: " choice
    case "$choice" in
        1) ai_tools_menu ;;
        2) dev_tools_menu ;;
        3) system_info_menu ;;
        4) fan_menu ;;
        5) backup_menu ;;
        6) gaming_menu ;;
        7) terminal_menu ;;
        8) optimize_menu ;;
        9) pdf_menu ;;
        10) security_menu ;;
        11) multimedia_menu ;;
        12) cleanup_menu ;;
        0) echo -e "${GREEN}Do widzenia!${NC}"; exit 0 ;;
        *) echo -e "${RED}Niepoprawna opcja!${NC}"; sleep 1 ;;
    esac
done
