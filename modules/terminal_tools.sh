#!/bin/bash
terminal_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA TERMINALA ===${NC}"
        echo "1)  Tmux — manager okien terminala"
        echo "2)  Zainstaluj fzf (fuzzy finder)"
        echo "3)  Zainstaluj bat (lepszy cat)"
        echo "4)  Zainstaluj ripgrep (szybsze grep)"
        echo "5)  Zainstaluj htop/btop"
        echo "6)  Wszystkie narzędzia terminala"
        echo "7)  Konfiguruj Tmux"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) install_tmux ;;
            2) install_fzf ;;
            3) install_bat ;;
            4) install_ripgrep ;;
            5) install_htop_btop ;;
            6) install_all_terminal ;;
            7) configure_tmux ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_fzf() {
    if command -v fzf &>/dev/null; then
        echo -e "${GREEN}fzf: zainstalowany${NC}"; read -p "Odinstalować? (y/N): " u
        [[ "$u" == "y" || "$u" == "Y" ]] && sudo apt remove -y fzf 2>/dev/null && print_success "fzf odinstalowany."
        pause; return
    fi
    sudo apt install -y fzf 2>/dev/null; print_success "fzf gotowe!"; pause
}
install_bat() {
    if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
        echo -e "${GREEN}bat: zainstalowany${NC}"; read -p "Odinstalować? (y/N): " u
        [[ "$u" == "y" || "$u" == "Y" ]] && sudo apt remove -y bat 2>/dev/null && print_success "bat odinstalowany."
        pause; return
    fi
    sudo apt install -y bat 2>/dev/null; print_success "bat gotowe!"; pause
}
install_ripgrep() {
    if command -v rg &>/dev/null; then
        echo -e "${GREEN}ripgrep: zainstalowany${NC}"; read -p "Odinstalować? (y/N): " u
        [[ "$u" == "y" || "$u" == "Y" ]] && sudo apt remove -y ripgrep 2>/dev/null && print_success "ripgrep odinstalowany."
        pause; return
    fi
    sudo apt install -y ripgrep 2>/dev/null; print_success "ripgrep gotowe!"; pause
}
install_htop_btop() {
    if command -v htop &>/dev/null && command -v btop &>/dev/null; then
        echo -e "${GREEN}htop/btop: zainstalowane${NC}"; read -p "Odinstalować? (y/N): " u
        [[ "$u" == "y" || "$u" == "Y" ]] && sudo apt remove -y htop btop 2>/dev/null && print_success "htop/btop odinstalowane."
        pause; return
    fi
    sudo apt install -y htop btop 2>/dev/null; print_success "htop/btop gotowe!"; pause
}
install_tmux() {
    if command -v tmux &>/dev/null; then
        echo -e "${GREEN}Tmux: zainstalowany ($(tmux -V))${NC}"
        read -p "Odinstalować Tmux? (y/N): " u
        [[ "$u" == "y" || "$u" == "Y" ]] && sudo apt remove -y tmux 2>/dev/null && print_success "Tmux odinstalowany."
        pause; return
    fi
    sudo apt install -y tmux 2>/dev/null
    print_success "Tmux zainstalowany! Użyj: tmux new -s nazwa"
    pause
}

install_all_terminal() {
    sudo apt install -y tmux fzf bat ripgrep htop btop 2>/dev/null
    print_success "Wszystkie narzędzia terminala zainstalowane!"
    pause
}

configure_tmux() {
    cat > ~/.tmux.conf << 'TMX'
set -g mouse on
set -g default-terminal "screen-256color"
set -g history-limit 10000
bind | split-window -h
bind - split-window -v
bind r source-file ~/.tmux.conf \; display "Tmux przeładowany!"
TMX
    print_success "Tmux skonfigurowany! Uruchom: tmux"
    pause
}

terminal_menu
