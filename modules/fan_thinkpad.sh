#!/bin/bash
fan_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== WENTYLATOR THINKPAD ===${NC}"
        echo "1) Status wentylatora"
        echo "2) Auto (sterowanie BIOS)"
        echo "3) Level 0 (wyłączony)"
        echo "4) Level 1 (cichy)"
        echo "5) Level 2"
        echo "6) Level 3 (głośny)"
        echo "7) Level 4 (max)"
        echo "8) Monitoruj temp/fan (live)"
        echo "0) Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) fan_status ;;
            2) set_fan auto ;;
            3) set_fan 0 ;;
            4) set_fan 1 ;;
            5) set_fan 2 ;;
            6) set_fan 3 ;;
            7) set_fan 4 ;;
            8) monitor_fan ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

fan_status() {
    echo -e "${CYAN}Status wentylatora:${NC}"
    for hwmon in /sys/class/hwmon/*/; do
        [ -f "$hwmon/fan1_input" ] && echo "Fan: $(cat "$hwmon/fan1_input") RPM"
        [ -f "$hwmon/temp1_input" ] && echo "Temp: $(echo "scale=1; $(cat "$hwmon/temp1_input") / 1000" | bc)°C"
    done
    echo -e "\n${CYAN}Wszystkie temperatury (sensors):${NC}"
    sensors 2>/dev/null || echo "Zainstaluj lm-sensors"
    pause
}

set_fan() {
    if ! lsmod | grep -q thinkpad_acpi; then
        print_error "Moduł thinkpad_acpi niezaładowany"
        pause; return
    fi
    if [ "$1" = "auto" ]; then
        echo "level auto" | sudo tee /proc/acpi/ibm/fan >/dev/null
        print_success "Tryb AUTO włączony"
    else
        echo "level $1" | sudo tee /proc/acpi/ibm/fan >/dev/null
        print_success "Fan level $1"
    fi
    pause
}

monitor_fan() {
    echo -e "${CYAN}Monitorowanie (Ctrl+C aby zakończyć):${NC}"
    while true; do
        local rpm="?"
        local temp="?"
        for hwmon in /sys/class/hwmon/*/; do
            [ -f "$hwmon/fan1_input" ] && rpm=$(cat "$hwmon/fan1_input")
            [ -f "$hwmon/temp1_input" ] && temp=$(echo "scale=1; $(cat "$hwmon/temp1_input") / 1000" | bc)
        done
        echo -ne "\rTemp: ${temp}°C | Fan: ${rpm} RPM | $(date +%H:%M:%S)   "
        sleep 2
    done
}

fan_menu
