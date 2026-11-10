#!/bin/bash
system_info_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== INFORMACJE O SYSTEMIE ===${NC}"
        echo "1)  Pełne info o systemie"
        echo "2)  CPU i pamięć"
        echo "3)  Dysk i partycje"
        echo "4)  Procesy (top 10 CPU)"
        echo "5)  Temperatury i wentylatory"
        echo "6)  Bateria (laptop)"
        echo "7)  Karta sieciowa i IP"
        echo "8)  Zainstalowane pakiety (ile)"
        echo "9)  Uptime i obciążenie"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) full_info ;;
            2) cpu_mem ;;
            3) disk_info ;;
            4) top_processes ;;
            5) temps_fans ;;
            6) battery_info ;;
            7) network_info ;;
            8) package_count ;;
            9) uptime_load ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

full_info() {
    echo -e "${CYAN}SYSTEM:${NC} $(uname -a)"
    echo -e "${CYAN}Dystrybucja:${NC} $(lsb_release -d 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1)"
    echo -e "${CYAN}Hostname:${NC} $(hostname)"
    echo -e "${CYAN}Użytkownik:${NC} $(whoami)"
    echo -e "${CYAN}Data:${NC} $(date)"
    echo
    cpu_mem
    echo
    disk_info
    pause
}

cpu_mem() {
    echo -e "${YELLOW}CPU:${NC}"
    lscpu | grep -E "Model name|CPU\(s\)|Thread|Core" | head -4
    echo
    echo -e "${YELLOW}Pamięć:${NC}"
    free -h
}

disk_info() {
    echo -e "${YELLOW}Dyski:${NC}"
    df -h | grep -v tmpfs | grep -v loop
    echo
    lsblk 2>/dev/null | head -15
}

top_processes() {
    ps aux --sort=-%cpu | head -12
    pause
}

temps_fans() {
    if command -v sensors &>/dev/null; then sensors; else sudo apt install -y lm-sensors 2>/dev/null && sensors; fi
    if [ -d /sys/devices/platform/thinkpad_hwmon/ ]; then
        for hwmon in /sys/class/hwmon/*/; do
            [ -f "$hwmon/fan1_input" ] && echo "Fan: $(cat "$hwmon/fan1_input") RPM"
        done
    fi
    pause
}

battery_info() {
    for bat in /sys/class/power_supply/BAT*; do
        [ -d "$bat" ] && {
            echo "Bateria: $(basename "$bat")"
            echo "  Status: $(cat "$bat/status" 2>/dev/null || echo N/A)"
            echo "  Poziom: $(cat "$bat/capacity" 2>/dev/null || echo N/A)%"
            [ -f "$bat/energy_full" ] && [ -f "$bat/energy_full_design" ] && {
                local wear=$(echo "100 - 100 * $(cat "$bat/energy_full") / $(cat "$bat/energy_full_design")" | bc 2>/dev/null)
                echo "  Zużycie: ${wear}%"
            }
        }
    done
    pause
}

network_info() {
    echo -e "${YELLOW}Interfejsy:${NC}"
    ip -br addr 2>/dev/null
    echo
    echo -e "${YELLOW}Routing:${NC}"
    ip route 2>/dev/null | head -5
    pause
}

package_count() {
    echo "Pakiety (dpkg): $(dpkg -l | grep '^ii' | wc -l)"
    echo "Pakiety (snap): $(snap list 2>/dev/null | wc -l)"
    echo "Pakiety (pip): $(pip3 list 2>/dev/null | wc -l)"
    pause
}

uptime_load() {
    echo "Uptime: $(uptime -p)"
    echo "Load: $(uptime | awk -F'load average:' '{print $2}')"
    echo "Użytkownicy: $(who | wc -l)"
    pause
}

system_info_menu
