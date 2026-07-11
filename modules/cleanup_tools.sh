#!/bin/bash
cleanup_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA CLEANUP ===${NC}"
        echo "1)  Wyczyść cache pakietów"
        echo "2)  Wyczyść cache użytkownika"
        echo "3)  Wyczyść logi systemowe"
        echo "4)  Wyczyść stare kernale"
        echo "5)  Wyczyść pip cache"
        echo "6)  Wyczyść snap cache"
        echo "7)  Pełne czyszczenie (wszystko)"
        echo "8)  Pokaż miejsce na dysku"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) clean_apt ;;
            2) clean_user_cache ;;
            3) clean_journal ;;
            4) clean_kernels ;;
            5) clean_pip ;;
            6) clean_snap ;;
            7) clean_all ;;
            8) show_space ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

clean_apt() {
    echo -e "${CYAN}Czyszczenie APT...${NC}"
    sudo apt autoremove --purge -y
    sudo apt autoclean
    sudo apt clean
    print_success "Cache APT wyczyszczony!"
    pause
}

clean_user_cache() {
    echo -e "${CYAN}Czyszczenie cache użytkownika...${NC}"
    rm -rf ~/.cache/thumbnails/* 2>/dev/null
    find ~/.cache -type f -atime +30 -delete 2>/dev/null
    rm -rf ~/.local/share/Trash/* 2>/dev/null
    print_success "Cache użytkownika wyczyszczony!"
    pause
}

clean_journal() {
    echo -e "${CYAN}Czyszczenie logów systemowych...${NC}"
    sudo journalctl --vacuum-time=3d
    sudo find /var/log -name "*.log" -type f -mtime +30 -delete 2>/dev/null
    sudo find /var/log -name "*.gz" -delete 2>/dev/null
    print_success "Logi wyczyszczone!"
    pause
}

clean_kernels() {
    echo -e "${CYAN}Czyszczenie starych kerneli...${NC}"
    sudo apt autoremove --purge -y
    print_success "Stare kernele usunięte!"
    pause
}

clean_pip() {
    echo -e "${CYAN}Czyszczenie cache pip...${NC}"
    rm -rf ~/.cache/pip 2>/dev/null
    pip3 cache purge 2>/dev/null
    print_success "Cache pip wyczyszczony!"
    pause
}

clean_snap() {
    echo -e "${CYAN}Czyszczenie snap...${NC}"
    sudo snap list --all | awk '/disabled/{print $1, $3}' | while read -r name rev; do
        sudo snap remove "$name" --revision="$rev" 2>/dev/null
    done
    print_success "Snapy wyczyszczone!"
    pause
}

clean_all() {
    clean_apt
    clean_user_cache
    clean_journal
    clean_pip
    clean_snap
    print_success "Pełne czyszczenie zakończone!"
    pause
}

show_space() {
    echo -e "${CYAN}Miejsce na dysku:${NC}"
    df -h / | tail -1
    echo
    echo -e "${CYAN}Największe katalogi w ~:${NC}"
    du -sh ~/* 2>/dev/null | sort -rh | head -15
    pause
}

cleanup_menu
