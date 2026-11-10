#!/bin/bash
backup_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA BACKUP ===${NC}"
        echo "1) Backup listy pakietów"
        echo "2) Backup konfiguracji systemu"
        echo "3) Backup katalogu domowego (rsync)"
        echo "4) Backup do archiwum tar.gz"
        echo "5) Przywróć listę pakietów"
        echo "6) Lista backupów"
        echo "0) Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) backup_packages ;;
            2) backup_config ;;
            3) backup_home ;;
            4) backup_tar ;;
            5) restore_packages ;;
            6) list_backups ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

backup_packages() {
    local f="$AREKBOX_DIR/backups/packages-$(date +%Y%m%d).list"
    dpkg --get-selections > "$f"
    print_success "Lista pakietów zapisana: $f"
    pause
}

backup_config() {
    local d="$AREKBOX_DIR/backups/config-$(date +%Y%m%d)"
    mkdir -p "$d"
    cp /etc/apt/sources.list "$d/" 2>/dev/null
    cp -r /etc/apt/sources.list.d "$d/" 2>/dev/null
    cp /etc/fstab "$d/" 2>/dev/null
    cp -r /etc/cron* "$d/" 2>/dev/null
    print_success "Konfiguracja skopiowana: $d"
    pause
}

backup_home() {
    local d="$AREKBOX_DIR/backups/home-$(date +%Y%m%d)"
    mkdir -p "$d"
    rsync -av --exclude='.cache' --exclude='.local/share/Trash' \
        --exclude='snap' --exclude='.mozilla/firefox/*.default*/cache' \
        "$HOME/" "$d/" 2>&1 | tail -5
    print_success "Backup home w: $d"
    pause
}

backup_tar() {
    read -p "Katalog do backupu: " src
    [ ! -d "$src" ] && { print_error "Katalog nie istnieje!"; pause; return; }
    local out="$AREKBOX_DIR/backups/backup-$(basename "$src")-$(date +%Y%m%d-%H%M).tar.gz"
    tar -czf "$out" -C "$(dirname "$src")" "$(basename "$src")" 2>/dev/null
    print_success "Archiwum: $out"
    pause
}

restore_packages() {
    echo "Dostępne listy pakietów:"
    ls "$AREKBOX_DIR/backups/"*.list 2>/dev/null || { echo "Brak"; pause; return; }
    read -p "Ścieżka do pliku .list: " f
    [ ! -f "$f" ] && { print_error "Plik nie istnieje!"; pause; return; }
    sudo dpkg --clear-selections
    sudo dpkg --set-selections < "$f"
    sudo apt-get dselect-upgrade -y
    print_success "Pakiety przywrócone!"
    pause
}

list_backups() {
    echo -e "${CYAN}Backupy w $AREKBOX_DIR/backups/:${NC}"
    ls -lh "$AREKBOX_DIR/backups/" 2>/dev/null || echo "Pusty"
    local size=$(du -sh "$AREKBOX_DIR/backups/" 2>/dev/null | cut -f1)
    echo "Całkowity rozmiar: $size"
    pause
}

backup_menu
