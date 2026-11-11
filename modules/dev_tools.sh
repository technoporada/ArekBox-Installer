#!/bin/bash
dev_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA DEVELOPERSKIE ===${NC}"
        echo "1)  Instaluj Node.js + npm"
        echo "2)  Instaluj Java (OpenJDK)"
        echo "3)  Zarządzaj środowiskami Python"
        echo "4)  Instaluj Docker"
        echo "5)  Instaluj Git + konfiguracja"
        echo "6)  Instaluj VS Code"
        echo "7)  Instaluj podstawowe narzędzia dev"
        echo "8)  Status środowisk"
        echo "0)  Powrót"
        read -rp "Wybierz opcję: " choice
        case "$choice" in
            1) install_nodejs ;;
            2) install_java ;;
            3) manage_python_envs ;;
            4) install_docker ;;
            5) install_git ;;
            6) install_vscode ;;
            7) install_dev_basics ;;
            8) env_status ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_nodejs() {
    if command -v node &>/dev/null; then
        echo -e "${GREEN}Node.js: zainstalowany ($(node --version), npm $(npm --version))${NC}"
        read -rp "Odinstalować Node.js? (y/N): " u
        if [[ "$u" == "y" || "$u" == "Y" ]]; then
            sudo apt remove -y nodejs 2>/dev/null
            sudo rm -f /etc/apt/sources.list.d/nodesource.list
            print_success "Node.js odinstalowany."
        fi
        pause; return
    fi
    echo -e "${CYAN}Instalacja Node.js...${NC}"
    # NIE robimy: curl ... | sudo bash  (nieaudytowany kod z internetu od razu na roota = luka bezpieczeństwa)
    # Zamiast tego: pobierz skrypt, pokaż hash SHA256 i link do źródła, zapytaj o potwierdzenie.
    NODE_SETUP="/tmp/nodesource_setup_lts.sh"
    if curl -fsSL "https://deb.nodesource.com/setup_lts.x" -o "$NODE_SETUP" 2>/dev/null; then
        echo -e "${YELLOW}Pobrano skrypt nodesource do: $NODE_SETUP${NC}"
        echo -e "${CYAN}SHA256:${NC} $(sha256sum "$NODE_SETUP" | awk '{print $1}')"
        echo -e "${CYAN}Źródło:${NC} https://github.com/nodesource/distributions"
        read -rp "Czy chcesz kontynuować instalację Node.js z tego skryptu? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            sudo -E bash "$NODE_SETUP"
            sudo apt-get install -y nodejs
            npm install -g npm@latest yarn pnpm 2>/dev/null
            print_success "Node.js $(node --version) + npm $(npm --version)"
        else
            print_warning "Pominięto instalację Node.js."
        fi
        rm -f "$NODE_SETUP"
    else
        print_error "Nie udało się pobrać skryptu nodesource — sprawdź połączenie i certyfikaty."
    fi
    pause
}

manage_python_envs() {
    while true; do
        clear
        echo -e "${CYAN}=== ŚRODOWISKA PYTHON ===${NC}"
        echo "1) Utwórz środowisko"
        echo "2) Lista środowisk"
        echo "3) Usuń środowisko"
        echo "4) Instaluj pakiety"
        echo "5) Eksportuj requirements.txt"
        echo "0) Powrót"
        read -rp "Wybierz opcję: " choice
        case "$choice" in
            1) read -rp "Nazwa: " e
               python3 -m venv "$AREKBOX_DIR/venvs/$e"
               # shellcheck disable=SC1090
               source "$AREKBOX_DIR/venvs/$e/bin/activate"
               pip install --upgrade pip setuptools wheel
               print_success "Środowisko $e utworzone! source $AREKBOX_DIR/venvs/$e/bin/activate"
               pause ;;
            2) ls "$AREKBOX_DIR/venvs/" 2>/dev/null || echo "Brak"; pause ;;
            3) read -rp "Nazwa: " e; rm -rf "$AREKBOX_DIR/venvs/$e"; print_success "Usunięto $e"; pause ;;
            4) read -rp "Środowisko: " e; read -rp "Pakiety: " p
               # shellcheck disable=SC1090
               source "$AREKBOX_DIR/venvs/$e/bin/activate" 2>/dev/null && pip install "$p"; pause ;;
            5) read -rp "Środowisko: " e
               # shellcheck disable=SC1090
               source "$AREKBOX_DIR/venvs/$e/bin/activate" 2>/dev/null && pip freeze > "$AREKBOX_DIR/venvs/$e-requirements.txt"
               print_success "Zapisano $AREKBOX_DIR/venvs/$e-requirements.txt"; pause ;;
            0) return ;;
        esac
    done
}

install_docker() {
    if command -v docker &>/dev/null; then
        echo -e "${GREEN}Docker: zainstalowany ($(docker --version))${NC}"
        read -rp "Odinstalować Docker? (y/N): " u
        if [[ "$u" == "y" || "$u" == "Y" ]]; then
            sudo apt remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin 2>/dev/null
            sudo rm -rf /var/lib/docker /etc/docker
            print_success "Docker odinstalowany."
        fi
        pause; return
    fi
    echo -e "${CYAN}Instalacja Docker...${NC}"
    # NIE robimy: curl ... | sh  (nieaudytowany kod z internetu od razu na roota = luka bezpieczeństwa)
    # Zamiast tego: pobierz skrypt, pokaż hash SHA256 i link do źródła, zapytaj o potwierdzenie.
    DOCKER_SETUP="/tmp/get_docker.sh"
    if curl -fsSL "https://get.docker.com" -o "$DOCKER_SETUP" 2>/dev/null; then
        echo -e "${YELLOW}Pobrano skrypt Docker do: $DOCKER_SETUP${NC}"
        echo -e "${CYAN}SHA256:${NC} $(sha256sum "$DOCKER_SETUP" | awk '{print $1}')"
        echo -e "${CYAN}Źródło:${NC} https://docs.docker.com/engine/install/"
        read -rp "Czy chcesz kontynuować instalację Dockera z tego skryptu? (y/N): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            sh "$DOCKER_SETUP"
            sudo usermod -aG docker "$USER"
            print_success "Docker zainstalowany! Wyloguj się i zaloguj ponownie."
        else
            print_warning "Pominięto instalację Dockera."
        fi
        rm -f "$DOCKER_SETUP"
    else
        print_error "Nie udało się pobrać skryptu Docker — sprawdź połączenie i certyfikaty."
    fi
    pause
    pause
}

install_git() {
    if command -v git &>/dev/null; then
        echo -e "${GREEN}Git: zainstalowany ($(git --version))${NC}"
        read -rp "Przekonfigurować Git? (y/N): " u
        if [[ "$u" == "y" || "$u" == "Y" ]]; then
            read -rp "Imię i nazwisko: " gn
            read -rp "Email: " ge
            git config --global user.name "$gn"
            git config --global user.email "$ge"
            git config --global init.defaultBranch main
            print_success "Git skonfigurowany!"
        fi
        pause; return
    fi
    sudo apt install -y git
    read -rp "Imię i nazwisko: " gn
    read -rp "Email: " ge
    git config --global user.name "$gn"
    git config --global user.email "$ge"
    git config --global init.defaultBranch main
    print_success "Git skonfigurowany!"
    pause
}

install_vscode() {
    if command -v code &>/dev/null; then
        echo -e "${GREEN}VS Code: zainstalowany ($(code --version | head -1))${NC}"
        read -rp "Odinstalować VS Code? (y/N): " u
        if [[ "$u" == "y" || "$u" == "Y" ]]; then
            sudo apt remove -y code 2>/dev/null
            sudo rm -f /etc/apt/sources.list.d/vscode.list /usr/share/keyrings/vscode.gpg
            print_success "VS Code odinstalowane."
        fi
        pause; return
    fi
    echo -e "${CYAN}Instalacja VS Code...${NC}"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/vscode.gpg 2>/dev/null
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/vscode.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
    sudo apt update && sudo apt install -y code
    print_success "VS Code zainstalowane!"
    pause
}

install_dev_basics() {
    sudo apt install -y build-essential gcc g++ make cmake gdb valgrind htop btop 2>/dev/null
    print_success "Podstawowe narzędzia dev zainstalowane!"
    pause
}

env_status() {
    echo "Python: $(python3 --version)"
    echo "Pip:    $(pip3 --version)"
    echo -e "\nŚrodowiska wirtualne:"
    ls "$AREKBOX_DIR/venvs/" 2>/dev/null || echo "Brak"
    pause
}

install_java() {
    if command -v java &>/dev/null; then
        echo -e "${GREEN}Java: zainstalowana ($(java -version 2>&1 | head -1))${NC}"
        read -rp "Odinstalować Java? (y/N): " u
        if [[ "$u" == "y" || "$u" == "Y" ]]; then
            sudo apt remove -y openjdk-* 2>/dev/null || true
            print_success "Java odinstalowana."
        fi
        pause; return
    fi
    echo -e "${CYAN}Instalacja Java (OpenJDK)...${NC}"
    sudo apt install -y openjdk-17-jdk 2>/dev/null || sudo apt install -y default-jdk 2>/dev/null || print_error "Nie udało się zainstalować Java — sprawdź certyfikaty i połączenie."
    if command -v java &>/dev/null; then
        print_success "Java zainstalowana: $(java -version 2>&1 | head -1)"
    fi
    pause
}

dev_tools_menu
