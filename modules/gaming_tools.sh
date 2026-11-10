#!/bin/bash
gaming_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA GAMING ===${NC}"
        echo "1)  Zainstaluj Steam"
        echo "2)  Zainstaluj Lutris"
        echo "3)  Zainstaluj Wine/Proton"
        echo "4)  Zainstaluj GameMode"
        echo "5)  Zainstaluj MangoHud"
        echo "6)  Zainstaluj Heroic Games Launcher"
        echo "7)  Optymalizacja dla gier"
        echo "8)  Monitor FPS (MangoHud)"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) install_steam ;;
            2) install_lutris ;;
            3) install_wine ;;
            4) install_gamemode ;;
            5) install_mangohud ;;
            6) install_heroic ;;
            7) gaming_optimize ;;
            8) setup_mangohud ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_steam() {
    sudo apt install -y steam 2>/dev/null
    print_success "Steam zainstalowany!"
    pause
}

install_lutris() {
    sudo add-apt-repository -y ppa:lutris-team/lutris 2>/dev/null
    sudo apt update && sudo apt install -y lutris 2>/dev/null
    print_success "Lutris zainstalowany!"
    pause
}

install_wine() {
    sudo dpkg --add-architecture i386
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key | sudo gpg --dearmor -o /usr/share/keyrings/wine.gpg 2>/dev/null
    echo "deb [signed-by=/usr/share/keyrings/wine.gpg] https://dl.winehq.org/wine-builds/ubuntu/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/wine.list
    sudo apt update && sudo apt install -y --install-recommends winehq-stable 2>/dev/null
    print_success "Wine zainstalowany!"
    pause
}

install_gamemode() {
    sudo apt install -y gamemode 2>/dev/null
    print_success "GameMode zainstalowany! Użyj: gamemoderun <komenda>"
    pause
}

install_mangohud() {
    sudo apt install -y mangohud 2>/dev/null
    print_success "MangoHud zainstalowany! Użyj: mangohud <komenda>"
    pause
}

install_heroic() {
    sudo snap install heroic --classic 2>/dev/null || {
        print_info "Pobieranie z GitHub..."
        curl -s https://api.github.com/repos/Heroic-Games-Launcher/HeroicGamesLauncher/releases/latest | \
            grep "browser_download_url.*.deb" | cut -d'"' -f4 | head -1 | wget -O /tmp/heroic.deb -qi -
        sudo dpkg -i /tmp/heroic.deb 2>/dev/null
        sudo apt install -f -y
    }
    print_success "Heroic Games Launcher zainstalowany!"
    pause
}

gaming_optimize() {
    echo -e "${CYAN}Optymalizacja systemu dla gier:${NC}"
    echo "1) Ustaw govornor na 'performance'"
    echo "2) Wyłącz kompozycję (dla Cinnamon)"
    echo "3) Zainstaluj wszystkie narzędzia gaming"
    read -p "Wybierz: " c
    case "$c" in
        1) echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor >/dev/null 2>&1
           print_success "Governor = performance";;
        2) gsettings set org.cinnamon.muffin compositing-manager false 2>/dev/null
           print_success "Kompozycja wyłączona";;
        3) install_steam; install_lutris; install_wine; install_gamemode; install_mangohud ;;
    esac
    pause
}

setup_mangohud() {
    mkdir -p ~/.config/MangoHud
    cat > ~/.config/MangoHud/MangoHud.conf << 'MHUD'
fps_limit=0
fps_only=0
cpu_stats=1
gpu_stats=1
ram=1
vram=1
engine_version=1
font_size=24
position=top-right
MHUD
    print_success "MangoHud skonfigurowany! Uruchom: mangohud <gra>"
    pause
}

gaming_menu
