#!/bin/bash
multimedia_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA MULTIMEDIALNE ===${NC}"
        echo "1)  yt-dlp + skrypty"
        echo "2)  MPV + konfiguracja"
        echo "3)  Spotify (snap)"
        echo "4)  FFmpeg + skrypty"
        echo "5)  OBS Studio"
        echo "6)  VLC"
        echo "7)  GIMP"
        echo "8)  Audacity"
        echo "9)  Konwersja formatów"
        echo "10) yt-dlp Dashboard (Web)"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) install_ytdlp ;;
            2) install_mpv ;;
            3) sudo snap install spotify 2>/dev/null; print_success "Spotify zainstalowane!"; pause ;;
            4) install_ffmpeg ;;
            5) sudo apt install -y obs-studio 2>/dev/null; print_success "OBS gotowe!"; pause ;;
            6) sudo apt install -y vlc 2>/dev/null; print_success "VLC gotowe!"; pause ;;
            7) sudo apt install -y gimp 2>/dev/null; print_success "GIMP gotowe!"; pause ;;
            8) sudo apt install -y audacity 2>/dev/null; print_success "Audacity gotowe!"; pause ;;
            9) format_converter ;;
            10) yt_dlp_dashboard ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_ytdlp() {
    python3 -m venv "$AREKBOX_DIR/venvs/media" 2>/dev/null
    source "$AREKBOX_DIR/venvs/media/bin/activate"
    pip install yt-dlp 2>/dev/null
    cat > "$AREKBOX_DIR/media-scripts/download-audio.sh" << 'AEOF'
#!/bin/bash
source ~/arekbox/venvs/media/bin/activate
yt-dlp -f 'bestaudio[ext=m4a]' --extract-audio --audio-format mp3 --audio-quality 0 "$1"
AEOF
    cat > "$AREKBOX_DIR/media-scripts/download-video.sh" << 'VEOF'
#!/bin/bash
source ~/arekbox/venvs/media/bin/activate
yt-dlp -f 'best[height<=1080]' "$1"
VEOF
    chmod +x "$AREKBOX_DIR/media-scripts/"*.sh
    print_success "yt-dlp gotowy! Użyj skryptów w $AREKBOX_DIR/media-scripts/"
    pause
}

install_mpv() {
    sudo apt install -y mpv 2>/dev/null
    mkdir -p ~/.config/mpv
    cat > ~/.config/mpv/mpv.conf << 'MPVCFG'
vo=gpu
hwdec=auto
keep-open=yes
save-position-on-quit=yes
volume-max=150
osd-level=1
MPVCFG
    print_success "MPV zainstalowane z konfiguracją!"
    pause
}

install_ffmpeg() {
    sudo apt install -y ffmpeg mediainfo exiftool 2>/dev/null
    cat > "$AREKBOX_DIR/ffmpeg-scripts/convert-to-mp4.sh" << 'FF1'
#!/bin/bash
[ -z "$1" ] && { echo "Użycie: $0 <plik>"; exit 1; }
ffmpeg -i "$1" -c:v libx264 -c:a aac -preset medium -crf 23 "${1%.*}.mp4"
FF1
    cat > "$AREKBOX_DIR/ffmpeg-scripts/extract-audio.sh" << 'FF2'
#!/bin/bash
[ -z "$1" ] && { echo "Użycie: $0 <plik>"; exit 1; }
ffmpeg -i "$1" -vn -acodec mp3 -ab 192k "${1%.*}.mp3"
FF2
    chmod +x "$AREKBOX_DIR/ffmpeg-scripts/"*.sh
    print_success "FFmpeg i skrypty gotowe!"
    pause
}

format_converter() {
    echo "1) Video → MP4"
    echo "2) Wyodrębnij audio → MP3"
    read -p "Wybierz: " c
    read -p "Ścieżka do pliku: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    case "$c" in
        1) "$AREKBOX_DIR/ffmpeg-scripts/convert-to-mp4.sh" "$f" ;;
        2) "$AREKBOX_DIR/ffmpeg-scripts/extract-audio.sh" "$f" ;;
    esac
    pause
}

yt_dlp_dashboard() {
    if [ ! -x "$AREKBOX_DIR/venvs/media/bin/python" ]; then
        print_error "Środowisko nie skonfigurowane — uruchom: bash arekbox.sh --setup"
        pause
        return
    fi
    if [ ! -f "$AREKBOX_DIR/yt-dlp-dashboard.sh" ]; then
        print_error "Brak yt-dlp-dashboard.sh w $AREKBOX_DIR"
        pause
        return
    fi
    print_info "Uruchamiam dashboard yt-dlp → http://localhost:5000 ..."
    ( cd "$AREKBOX_DIR" && nohup bash yt-dlp-dashboard.sh >/dev/null 2>&1 & )
    sleep 2
    print_success "Dashboard działa: http://localhost:5000"
    pause
}

multimedia_menu
