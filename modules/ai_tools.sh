#!/bin/bash
ai_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${WHITE}            🤖 AI TOOLS                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
        echo "1)  Zainstaluj Ollama"
        echo "2)  Zarządzaj modelami Ollama"
        echo "3)  Szybki chat z modelem"
        echo "4)  Benchmark modeli"
        echo "5)  Zainstaluj Open WebUI (Docker)"
        echo "6)  TTS Tools (espeak, festival, Python)"
        echo "7)  Zainstaluj Whisper (STT)"
        echo "8)  OSINT Tools"
        echo "9)  Chatbot lokalny (Python)"
        echo "10) Status usług AI"
        echo "0)  Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) install_ollama ;;
            2) manage_ollama_models ;;
            3) ollama_quick_chat ;;
            4) ollama_benchmark ;;
            5) install_open_webui ;;
            6) install_tts_tools ;;
            7) install_whisper ;;
            8) osint_tools_menu ;;
            9) run_local_chatbot ;;
            10) check_ai_services ;;
            0) return ;;
            *) echo -e "${RED}Niepoprawna opcja!${NC}"; pause ;;
        esac
    done
}

install_ollama() {
    echo -e "${CYAN}Instalacja Ollama...${NC}"
    if command -v ollama &>/dev/null; then
        print_warning "Ollama już zainstalowana: $(ollama --version)"
        return
    fi
    curl -fsSL https://ollama.com/install.sh | sh
    sudo systemctl enable ollama 2>/dev/null
    sudo systemctl start ollama 2>/dev/null
    sleep 3
    if systemctl is-active --quiet ollama 2>/dev/null; then
        print_success "Ollama uruchomiona!"
    else
        print_warning "Uruchamianie w trybie użytkownika..."
        nohup ollama serve > "$AREKBOX_DIR/logs/ollama.log" 2>&1 &
        sleep 5
    fi
    print_info "Pobieranie podstawowych modeli..."
    ollama pull llama3.2:3b 2>/dev/null
    ollama pull phi3:mini 2>/dev/null
    print_success "Instalacja zakończona!"
    pause
}

manage_ollama_models() {
    while true; do
        clear
        echo -e "${CYAN}=== ZARZĄDZANIE MODELAMI OLLAMA ===${NC}"
        echo "1) Lista modeli"
        echo "2) Pobierz model"
        echo "3) Usuń model"
        echo "4) Uruchom model interaktywnie"
        echo "5) Modele podstawowe (małe)"
        echo "6) Modele średnie"
        echo "7) Modele specjalistyczne"
        echo "0) Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1) ollama list 2>/dev/null || echo "Brak modeli lub Ollama niedostępna"; pause ;;
            2) read -p "Nazwa modelu (np. llama3.2:1b): " m; [ -n "$m" ] && ollama pull "$m"; pause ;;
            3) ollama list; read -p "Nazwa modelu do usunięcia: " m; [ -n "$m" ] && ollama rm "$m"; pause ;;
            4) ollama list; read -p "Nazwa modelu: " m; [ -n "$m" ] && ollama run "$m" ;;
            5) for m in llama3.2:1b phi3:mini qwen2.5:0.5b; do ollama pull "$m"; done; pause ;;
            6) for m in llama3.2:3b mistral:7b gemma:2b; do ollama pull "$m"; done; pause ;;
            7) echo "1) nomic-embed-text  2) llava:7b  3) deepseek-coder:6.7b  4) wizard-math:7b"
               read -p "Wybierz (1-4): " s
               case "$s" in 1) ollama pull nomic-embed-text;; 2) ollama pull llava:7b;; 3) ollama pull deepseek-coder:6.7b;; 4) ollama pull wizard-math:7b;; esac
               pause ;;
            0) return ;;
        esac
    done
}

ollama_quick_chat() {
    local model="${1:-llama3.2:3b}"
    if ! curl -s --connect-timeout 2 http://localhost:11434/api/tags >/dev/null; then
        print_error "Ollama nie odpowiada. Uruchom: ollama serve"
        pause; return
    fi
    echo -e "${GREEN}Szybki chat z $model (wpisz 'quit' aby zakończyć)${NC}"
    while true; do
        read -p "Ty: " input
        [[ "$input" == "quit" ]] && break
        curl -s -X POST http://localhost:11434/api/generate \
            -d "{\"model\":\"$model\",\"prompt\":\"$input\",\"stream\":false}" 2>/dev/null | \
            python3 -c "import sys,json; print(json.load(sys.stdin).get('response','Błąd'))" 2>/dev/null || \
            echo "Błąd połączenia z API"
    done
}

ollama_benchmark() {
    if ! curl -s --connect-timeout 2 http://localhost:11434/api/tags >/dev/null; then
        print_error "Ollama nie odpowiada"; pause; return
    fi
    echo "=== BENCHMARK MODELI OLLAMA ==="
    ollama list 2>/dev/null | tail -n +2 | awk '{print $1}' | while read -r model; do
        local start=$(date +%s.%N)
        local resp=$(curl -s -X POST http://localhost:11434/api/generate \
            -d "{\"model\":\"$model\",\"prompt\":\"Hello in 10 words\",\"stream\":false}")
        local end=$(date +%s.%N)
        local dur=$(echo "$end - $start" | bc -l 2>/dev/null || echo "0")
        local tokens=$(echo "$resp" | python3 -c "import sys,json; print(len(json.load(sys.stdin).get('response','').split()))" 2>/dev/null || echo "0")
        printf "%-20s %5.2fs %5d tokens\n" "$model" "$dur" "$tokens"
    done
    pause
}

install_open_webui() {
    echo -e "${CYAN}Instalacja Open WebUI...${NC}"
    if ! command -v docker &>/dev/null; then
        print_info "Instalacja Docker..."
        curl -fsSL https://get.docker.com | sh
        sudo usermod -aG docker "$USER"
        print_warning "Wyloguj się i zaloguj ponownie dla Dockera bez sudo"
    fi
    if docker ps -a --format "{{.Names}}" | grep -q "^open-webui$"; then
        docker stop open-webui 2>/dev/null; docker rm open-webui 2>/dev/null
    fi
    docker run -d --name open-webui --restart always -p 3000:8080 \
        -e OLLAMA_BASE_URL=http://host.docker.internal:11434 \
        -v open-webui:/app/backend/data \
        --add-host=host.docker.internal:host-gateway \
        ghcr.io/open-webui/open-webui:main
    sleep 5
    if docker ps | grep -q open-webui; then
        print_success "Open WebUI na http://localhost:3000"
    else
        print_error "Błąd uruchomienia. Sprawdź: docker logs open-webui"
    fi
    pause
}

install_tts_tools() {
    echo -e "${CYAN}Instalacja narzędzi TTS...${NC}"
    sudo apt install -y espeak espeak-ng festival festival-dev 2>/dev/null
    pip3 install --user pyttsx3 gTTS 2>/dev/null
    cat > "$AREKBOX_DIR/tts_test.py" << 'PYEOF'
#!/usr/bin/env python3
import pyttsx3, sys
def speak(text):
    engine = pyttsx3.init()
    engine.setProperty('rate', 150)
    engine.say(text)
    engine.runAndWait()
if __name__ == "__main__":
    speak(" ".join(sys.argv[1:]) if len(sys.argv) > 1 else "Witaj w ArekBox TTS")
PYEOF
    chmod +x "$AREKBOX_DIR/tts_test.py"
    print_success "TTS gotowe! Użyj: espeak 'tekst' lub python3 \$AREKBOX_DIR/tts_test.py 'tekst'"
    pause
}

install_whisper() {
    echo -e "${CYAN}Instalacja Whisper...${NC}"
    pip3 install --user openai-whisper faster-whisper 2>/dev/null
    print_success "Whisper zainstalowany! Użyj: whisper audio.mp3 --language Polish"
    pause
}

osint_tools_menu() {
    while true; do
        clear
        echo -e "${CYAN}=== NARZĘDZIA OSINT ===${NC}"
        echo "1) Instaluj podstawowe narzędzia"
        echo "2) TheHarvester"
        echo "3) Sherlock (username search)"
        echo "4) Recon-ng"
        echo "5) Spiderfoot"
        echo "6) Analiza zdjęć (EXIF)"
        echo "7) Analiza domen"
        echo "0) Powrót"
        read -p "Wybierz opcję: " choice
        case "$choice" in
            1)
                sudo apt install -y curl wget whois nmap exiftool imagemagick 2>/dev/null
                pip3 install --user requests beautifulsoup4 lxml dnspython 2>/dev/null
                mkdir -p "$AREKBOX_DIR/osint-tools"
                print_success "Podstawowe narzędzia OSINT zainstalowane!"; pause ;;
            2) cd "$AREKBOX_DIR/osint-tools" && git clone https://github.com/laramies/theHarvester.git 2>/dev/null && cd theHarvester && pip3 install --user -r requirements.txt 2>/dev/null; print_success "TheHarvester gotowy!"; pause ;;
            3) cd "$AREKBOX_DIR/osint-tools" && git clone https://github.com/sherlock-project/sherlock.git 2>/dev/null && cd sherlock && pip3 install --user -r requirements.txt 2>/dev/null; print_success "Sherlock gotowy!"; pause ;;
            4) cd "$AREKBOX_DIR/osint-tools" && git clone https://github.com/lanmaster53/recon-ng.git 2>/dev/null && cd recon-ng && pip3 install --user -r REQUIREMENTS 2>/dev/null; print_success "Recon-ng gotowy!"; pause ;;
            5) cd "$AREKBOX_DIR/osint-tools" && git clone https://github.com/smicallef/spiderfoot.git 2>/dev/null && cd spiderfoot && pip3 install --user -r requirements.txt 2>/dev/null; print_success "Spiderfoot gotowy!"; pause ;;
            6)
                cat > "$AREKBOX_DIR/osint-tools/image_analysis.sh" << 'IMGEOF'
#!/bin/bash
[ -z "$1" ] && { echo "Użycie: $0 <zdjęcie>"; exit 1; }
echo "=== Analiza: $1 ==="
exiftool "$1"
IMGEOF
                chmod +x "$AREKBOX_DIR/osint-tools/image_analysis.sh"
                print_success "Skrypt analizy zdjęć: $AREKBOX_DIR/osint-tools/image_analysis.sh"; pause ;;
            7)
                cat > "$AREKBOX_DIR/osint-tools/domain_info.sh" << 'DOMEOF'
#!/bin/bash
[ -z "$1" ] && { echo "Użycie: $0 <domena>"; exit 1; }
echo "=== Informacje o domenie: $1 ==="
whois "$1" 2>/dev/null | head -20
echo "--- DNS ---"
dig "$1" 2>/dev/null | head -20
DOMEOF
                chmod +x "$AREKBOX_DIR/osint-tools/domain_info.sh"
                print_success "Skrypt analizy domen: $AREKBOX_DIR/osint-tools/domain_info.sh"; pause ;;
            0) return ;;
        esac
    done
}

run_local_chatbot() {
    cat > "$AREKBOX_DIR/chatbot.py" << 'CHATEOF'
#!/usr/bin/env python3
import requests, json, sys
MODEL = "llama3.2:3b"
URL = "http://localhost:11434/api/generate"
def ask(prompt):
    try:
        r = requests.post(URL, json={"model": MODEL, "prompt": prompt, "stream": False})
        return r.json().get("response", "Błąd") if r.ok else f"HTTP {r.status_code}"
    except Exception as e:
        return f"Błąd: {e}"
def main():
    print("=== ArekBox AI Chatbot ===")
    print("Model: llama3.2:3b | Wpisz 'quit' aby zakończyć")
    while True:
        u = input("\nTy: ")
        if u.lower() in ("quit","exit","q"): break
        if u.strip(): print("AI:", ask(u))
if __name__ == "__main__":
    main()
CHATEOF
    chmod +x "$AREKBOX_DIR/chatbot.py"
    print_success "Chatbot utworzony! Uruchamianie..."
    python3 "$AREKBOX_DIR/chatbot.py"
}

check_ai_services() {
    echo -e "${CYAN}Status usług AI:${NC}"
    if systemctl is-active --quiet ollama 2>/dev/null; then echo -e "${GREEN}✓ Ollama: AKTYWNA${NC}"
    else echo -e "${RED}✗ Ollama: NIEAKTYWNA${NC}"; fi
    if curl -s --connect-timeout 2 http://localhost:11434/api/tags >/dev/null 2>&1; then echo -e "${GREEN}✓ Ollama API: DOSTĘPNE${NC}"
    else echo -e "${RED}✗ Ollama API: NIEDOSTĘPNE${NC}"; fi
    echo -e "\n${CYAN}Modele:${NC}"
    ollama list 2>/dev/null || echo "Brak"
    echo
    if docker ps 2>/dev/null | grep -q open-webui; then echo -e "${GREEN}✓ Open WebUI: URUCHOMIONE${NC}"
    else echo -e "${RED}✗ Open WebUI: ZATRZYMANE${NC}"; fi
    pause
}

ai_tools_menu
