#!/bin/bash
security_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA BEZPIECZEŃSTWA ===${NC}"
        echo "1)  Konfiguruj UFW Firewall"
        echo "2)  Instaluj ClamAV"
        echo "3)  Instaluj Fail2ban"
        echo "4)  Skanowanie portów (Nmap)"
        echo "5)  Status bezpieczeństwa"
        echo "6)  Backup firewall"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) configure_ufw ;;
            2) install_clamav ;;
            3) install_fail2ban ;;
            4) nmap_scan ;;
            5) security_status ;;
            6) backup_firewall ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

configure_ufw() {
    sudo apt install -y ufw 2>/dev/null
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
    print_success "UFW skonfigurowane!"
    sudo ufw status verbose
    pause
}

install_clamav() {
    sudo apt install -y clamav clamav-daemon clamav-freshclam 2>/dev/null
    sudo freshclam 2>/dev/null
    cat > "$AREKBOX_DIR/clamav-scan.sh" << CLM
#!/bin/bash
LOGFILE=$AREKBOX_DIR/logs/clamav-\$(date +%Y%m%d).log
echo "=== Skanowanie \$(date) ===" >> "\$LOGFILE"
clamscan -r /home/"\$USER" --log="\$LOGFILE" --infected --remove 2>/dev/null
echo "=== Zakończone \$(date) ===" >> "\$LOGFILE"
CLM
    chmod +x "$AREKBOX_DIR/clamav-scan.sh"
    read -p "Dodać codzienne skanowanie do cron? (y/N): " cr
    [[ "$cr" == "y" || "$cr" == "Y" ]] && (crontab -l 2>/dev/null; echo "0 2 * * * $AREKBOX_DIR/clamav-scan.sh") | crontab -
    print_success "ClamAV zainstalowane!"
    pause
}

install_fail2ban() {
    sudo apt install -y fail2ban 2>/dev/null
    cat > /tmp/jail.local << 'F2B'
[DEFAULT]
bantime = 1800
findtime = 600
maxretry = 3
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
F2B
    sudo cp /tmp/jail.local /etc/fail2ban/jail.local
    sudo systemctl restart fail2ban
    sudo systemctl enable fail2ban
    print_success "Fail2ban skonfigurowany!"
    pause
}

nmap_scan() {
    sudo apt install -y nmap 2>/dev/null
    echo "1) Localhost  2) Konkretny host  3) Sieć lokalna"
    read -p "Wybierz: " c
    case "$c" in
        1) sudo nmap -sS -O localhost ;;
        2) read -p "Adres IP: " t; sudo nmap -sS -O "$t" ;;
        3) sudo nmap -sn 192.168.1.0/24 ;;
    esac
    pause
}

security_status() {
    echo -e "${YELLOW}UFW:${NC}"; sudo ufw status 2>/dev/null || echo "Nieaktywne"
    echo -e "\n${YELLOW}Fail2ban:${NC}"
    systemctl is-active --quiet fail2ban 2>/dev/null && echo -e "${GREEN}✓ Aktywne${NC}" || echo -e "${RED}✗ Nieaktywne${NC}"
    echo -e "\n${YELLOW}ClamAV:${NC}"
    command -v clamscan &>/dev/null && echo -e "${GREEN}✓ Zainstalowane${NC}" || echo -e "${RED}✗ Niezainstalowane${NC}"
    pause
}

backup_firewall() {
    local bdir="$AREKBOX_DIR/backups/firewall-$(date +%Y%m%d)"
    mkdir -p "$bdir"
    [ -d /etc/ufw ] && sudo cp -r /etc/ufw "$bdir/" 2>/dev/null
    sudo iptables-save > "$bdir/iptables-backup.txt" 2>/dev/null
    print_success "Backup w $bdir"
    pause
}

security_menu
