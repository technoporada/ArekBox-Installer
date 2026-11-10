#!/bin/bash
optimize_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== OPTYMALIZACJA SYSTEMU ===${NC}"
        echo "1)  Podstawowe czyszczenie"
        echo "2)  Głębokie czyszczenie"
        echo "3)  Czyszczenie cache RAM"
        echo "4)  Czyszczenie logów"
        echo "5)  Optymalizacja dysku"
        echo "6)  Zarządzanie procesami"
        echo "7)  Tweak systemowy"
        echo "8)  Backup przed optymalizacją"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) basic_cleanup ;;
            2) deep_cleanup ;;
            3) drop_caches ;;
            4) clean_logs ;;
            5) disk_optimize ;;
            6) process_manager ;;
            7) system_tweaks ;;
            8) backup_before ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

basic_cleanup() {
    echo -e "${CYAN}Podstawowe czyszczenie...${NC}"
    sudo apt autoremove -y
    sudo apt autoclean
    sudo apt clean
    print_success "Gotowe!"
    pause
}

deep_cleanup() {
    echo -e "${CYAN}Głębokie czyszczenie...${NC}"
    sudo apt autoremove --purge -y
    sudo apt autoclean
    sudo apt clean
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    sudo rm -rf /tmp/* 2>/dev/null
    sudo rm -rf /var/tmp/* 2>/dev/null
    print_success "Gotowe!"
    pause
}

drop_caches() {
    echo -e "${CYAN}Czyszczenie cache RAM...${NC}"
    sudo sync
    echo 3 | sudo tee /proc/sys/vm/drop_caches >/dev/null
    print_success "Cache RAM wyczyszczone!"
    pause
}

clean_logs() {
    echo -e "${CYAN}Czyszczenie logów...${NC}"
    sudo journalctl --vacuum-time=7d
    sudo find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null
    print_success "Logi wyczyszczone!"
    pause
}

disk_optimize() {
    echo -e "${CYAN}Optymalizacja dysku...${NC}"
    echo "Użycie dysku:"
    df -h /
    echo
    read -p "Uruchomić fstrim (dla SSD)? (y/N): " tr
    [[ "$tr" == "y" || "$tr" == "Y" ]] && sudo fstrim -v /
    pause
}

process_manager() {
    echo -e "${CYAN}Top 20 procesów wg CPU:${NC}"
    ps aux --sort=-%cpu | head -20
    echo
    read -p "Zabić proces PID? (puste = pomiń): " pid
    [[ -n "$pid" ]] && kill "$pid" 2>/dev/null && print_success "Zabito PID $pid" || print_error "Nie udało się"
    pause
}

system_tweaks() {
    echo -e "${CYAN}Tweaki systemowe:${NC}"
    echo "1) Ustaw swappiness=10 (lepszy czas życia SSD)"
    echo "2) Wyłącz błyskawiczny dźwięk terminala"
    echo "3) Zwiększ limit watch (dla watcherów plików)"
    read -p "Wybierz (1-3): " c
    case "$c" in
        1) echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf >/dev/null; sudo sysctl -w vm.swappiness=10; print_success "swappiness=10";;
        2) echo "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf >/dev/null; print_success "Dźwięk wyłączony";;
        3) echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf >/dev/null; sudo sysctl -w fs.inotify.max_user_watches=524288; print_success "Limit watch zwiększony";;
    esac
    pause
}

backup_before() {
    local bdir="$AREKBOX_DIR/backups/system-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$bdir"
    dpkg --get-selections > "$bdir/packages.list"
    cp /etc/apt/sources.list "$bdir/" 2>/dev/null
    sudo cp -r /etc/apt/sources.list.d "$bdir/" 2>/dev/null
    print_success "Backup konfiguracji w $bdir"
    pause
}

optimize_menu
