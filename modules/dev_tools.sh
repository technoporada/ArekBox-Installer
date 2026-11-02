#!/bin/bash
dev_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA DEVELOPERSKIE ===${NC}"
        echo "1)  Instaluj Node.js + npm"
        echo "2)  Zarządzaj środowiskami Python"
        echo "3)  Instaluj Docker"
        echo "4)  Instaluj Git + konfiguracja"
        echo "5)  Instaluj VS Code"
        echo "6)  Instaluj podstawowe narzędzia dev"
        echo "7)  Status środowisk"
        echo "0)  Powrót"
        read -r -p "Wybierz opcję: " choice
        case "$choice" in
            1) install_nodejs ;;
            2) manage_python_envs ;;
            3) install_docker ;;
            4) install_git ;;
            5) install_vscode ;;
            6) install_dev_basics ;;
            7) env_status ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_nodejs() {
    echo -e "${CYAN}Instalacja Node.js...${NC}"
    curl -fsSL https://deb.nodesource.com/setup_lts.x -o /tmp/nodesource-setup.sh
    sudo -E bash /tmp/nodesource-setup.sh
    rm -f /tmp/nodesource-setup.sh
    sudo apt-get install -y nodejs
    npm install -g npm@latest yarn pnpm 2>/dev/null
    print_success "Node.js $(node --version) + npm $(npm --version)"
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
        read -r -p "Wybierz opcję: " choice
        case "$choice" in
            1) read -r -p "Nazwa: " e
               # Walidacja nazwy środowiska – tylko bezpieczne znaki, bez traversal
               if [[ ! "$e" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                   print_error "Nieprawidłowa nazwa środowiska (tylko litery, cyfry, podkreślnik, myślnik)."
                   pause; continue
               fi
               python3 -m venv "$AREKBOX_DIR/venvs/$e"
               source "$AREKBOX_DIR/venvs/$e/bin/activate"
               pip install --upgrade pip setuptools wheel
               print_success "Środowisko $e utworzone! source $AREKBOX_DIR/venvs/$e/bin/activate"
               pause ;;
            2) ls "$AREKBOX_DIR/venvs/" 2>/dev/null || echo "Brak"; pause ;;
            3) read -r -p "Nazwa: " e
               if [[ ! "$e" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                   print_error "Nieprawidłowa nazwa środowiska."
                   pause; continue
               fi
               rm -rf "$AREKBOX_DIR/venvs/$e"; print_success "Usunięto $e"; pause ;;
            4) read -r -p "Środowisko: " e
               if [[ ! "$e" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                   print_error "Nieprawidłowa nazwa środowiska."
                   pause; continue
               fi
               read -r -p "Pakiety: " p
               # Walidacja pakietów pip – tylko bezpieczne znaki specyfikatorów
               if [[ ! "$p" =~ ^[a-zA-Z0-9._=<>!~,\[\]()[:space:]+$-]+$ ]]; then
                   print_error "Nieprawidłowe znaki w nazwach pakietów."
                   pause; continue
               fi
               source "$AREKBOX_DIR/venvs/$e/bin/activate" 2>/dev/null && pip install $p; pause ;;
            5) read -r -p "Środowisko: " e
               if [[ ! "$e" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                   print_error "Nieprawidłowa nazwa środowiska."
                   pause; continue
               fi
               source "$AREKBOX_DIR/venvs/$e/bin/activate" 2>/dev/null && pip freeze > "$AREKBOX_DIR/venvs/$e-requirements.txt"
               print_success "Zapisano $AREKBOX_DIR/venvs/$e-requirements.txt"; pause ;;
            0) return ;;
        esac
    done
}

install_docker() {
    echo -e "${CYAN}Instalacja Docker...${NC}"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    rm -f /tmp/get-docker.sh
    sudo usermod -aG docker "$USER"
    print_success "Docker zainstalowany! Wyloguj się i zaloguj ponownie."
    pause
}

install_git() {
    sudo apt install -y git
    read -r -p "Imię i nazwisko: " gn
    read -r -p "Email: " ge
    git config --global user.name "$gn"
    git config --global user.email "$ge"
    git config --global init.defaultBranch main
    print_success "Git skonfigurowany!"
    pause
}

install_vscode() {
    echo -e "${CYAN}Instalacja VS Code...${NC}"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc -o /tmp/microsoft.asc
    sudo gpg --dearmor -o /usr/share/keyrings/vscode.gpg /tmp/microsoft.asc 2>/dev/null
    rm -f /tmp/microsoft.asc
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

dev_tools_menu
