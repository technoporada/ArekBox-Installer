# ArekBox

Zaawansowany zestaw narzędzi administracyjnych dla systemów Linux (Ubuntu/Mint/Debian).

## Instalacja i uruchomienie

```bash
bash arekbox.sh
```

Przy pierwszym uruchomieniu ArekBox sam zaproponuje instalację środowiska
(pakiety `apt` + venv Python z `venvs/media`). Możesz też wywołać to wprost:

```bash
bash arekbox.sh --setup
```

Co instaluje bootstrap:
- **apt**: ffmpeg, poppler-utils, espeak, fzf, bat, ripgrep, clamav, ufw, nmap, whois, itp.
- **venv** `venvs/media`: yt-dlp, PyPDF2, pyttsx3, gTTS, openai-whisper, requests, beautifulsoup4, dnspython, itp.
  (binaria z tego venvu są dodawane do `PATH` podczas sesji)

Wymagania:
- System Ubuntu/Debian (Linux Mint, itp.)
- Bash
- Dostęp do sudo

## Kategorie

| # | Kategoria | Opis |
|---|-----------|------|
| 1 | **AI Tools** | Ollama, Open WebUI, TTS, Whisper, OSINT, lokalny chatbot |
| 2 | **Dev Tools** | Node.js, Python venv, Docker, Git, VS Code |
| 3 | **System Info** | CPU, RAM, dysk, procesy, temperatury, sieć, bateria |
| 4 | **ThinkPad Fan** | Sterowanie wentylatorem ThinkPad (auto, poziomy, monitor) |
| 5 | **Backup Tools** | Backup pakietów, konfiguracji, home (rsync), archiwa tar |
| 6 | **Gaming Tools** | Steam, Lutris, Wine, GameMode, MangoHud, Heroic |
| 7 | **Terminal Tools** | Tmux, fzf, bat, ripgrep, htop/btop |
| 8 | **System Optimization** | Czyszczenie, cache RAM, dysk, manager procesów, tweaki |
| 9 | **PDF Tools** | Łączenie, dzielenie, kompresja, ekstrakcja tekstu, PDF→obraz |
| 10 | **Security Tools** | UFW, ClamAV, Fail2ban, Nmap, backup firewalla |
| 11 | **Multimedia Tools** | yt-dlp, MPV, FFmpeg, OBS, VLC, GIMP, Audacity |
| 12 | **Cleanup Tools** | Czyszczenie APT, cache, logów, kerneli, pip, snap |

## Opcjonalne wymagania

- **ThinkPad** — sterowanie wentylatorem (wymaga modułu `thinkpad_acpi`)
- **Docker** — Open WebUI do interakcji z modelami AI
- **PyPDF2** — narzędzia PDF (dzielenie, łączenie)
