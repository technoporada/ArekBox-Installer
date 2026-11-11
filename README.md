# ArekBox

[![CI](https://github.com/technoporada/ArekBox-Installer/actions/workflows/ci.yml/badge.svg)](https://github.com/technoporada/ArekBox-Installer/actions)
[![License: GPL v3](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5+-green.svg)](https://gnu.org)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://python.org)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian%20%7C%20Mint-orange.svg)](https://ubuntu.com)

**Modular Linux toolkit — AI tools, dev environment, multimedia, security, optimization.**

Single script installer with web dashboard, 12 category modules, and 50+ tools. Wszystkie instalacje są interaktywne — nie wykonujemy kodu z internetu w ciemnie z uprawnieniami roota.

> **Keywords:** `linux-toolkit` `ai-tools` `ollama` `multimedia` `security` `system-optimization` `bash` `flask` `yt-dlp` `ffmpeg`

---

## 🚀 Quick Start

```bash
git clone https://github.com/technoporada/ArekBox-Installer.git
cd ArekBox-Installer
bash arekbox.sh
```

Przy pierwszym uruchomieniu zostaniesz zapytany o konfigurację środowiska (Python venv, certyfikaty CA). Pakiety systemowe i narzędzia są instalowane na żądanie z menu, nie wszystkie naraz.

---

## 📦 Co jest w środku

| Moduł | Narzędzia |
|-------|-----------|
| **AI Tools** | Ollama, Open WebUI, TTS, Whisper, lokalny chatbot |
| **Dev Tools** | Node.js, Python venv, Docker, Git, VS Code, Java (OpenJDK) |
| **System Info** | CPU, RAM, dysk, procesy, temperatury, sieć, bateria |
| **ThinkPad Fan** | Sterowanie wentylatorem (auto, manualny, monitor) |
| **Backup Tools** | Kopia pakietów, konfiguracji, home (rsync), archiwa tar |
| **Gaming Tools** | Steam, Lutris, Wine, GameMode, MangoHud, Heroic |
| **Terminal Tools** | Tmux, fzf, bat, ripgrep, htop/btop |
| **System Optimization** | RAM cache, disk cleanup, menedżer procesów, tweaki |
| **PDF Tools** | Scalanie, dzielenie, kompresja, ekstrakt tekstu, PDF→obraz |
| **Security Tools** | UFW, ClamAV, Fail2ban, Nmap, kopia zapasowa firewalla |
| **Multimedia Tools** | yt-dlp, MPV, FFmpeg, OBS, VLC, GIMP, Audacity |
| **Cleanup Tools** | Cache APT, logi, stare kernele, pip, snap |

---

## 🖥️ Dashboard

```bash
bash arekbox-dashboard.sh
# → http://localhost:5050
```

Web UI z na żywo monitorem systemu, przeglądarką modułów i wizualizatorem audio.

Dodatkowo dostępny jest dashboard yt-dlp:

```bash
bash yt-dlp-dashboard.sh
# → http://localhost:5000
```

---

## 🔐 Bezpieczeństwo

W ramach dbałości o bezpieczeństwo wprowadzono następujące zmiany:

- **Brak `curl | sudo bash`** — skrypt nodesource (Node.js) oraz get.docker.com (Docker) są najpierw pobierane do `/tmp`, wyświetlany jest ich hash **SHA256** oraz link do źródła, a instalacja odbywa się dopiero po wyraźnym potwierdzeniu użytkownika (`y/N`). Skrypt tymczasowy jest usuwany po użyciu.
- **Brak `--trusted-host` w pip** — instalacje Pythona opierają się na systemowych certyfikatach CA (`ca-certificates` + `update-ca-certificates` uruchamiane w `bootstrap()`), a nie na omijaniu weryfikacji SSL/TLS.
- **Certyfikaty CA** — przy pierwszym uruchomieniu (`--setup`) aktualizowane są repozytoria apt i certyfikaty CA, co zapobiega błędom `certificate verify failed`.
- **Bezpieczny odczyt plików** — np. przywracanie pakietów w `backup_tools.sh` używa cytowanego redirectu `< "$f"` zamiast niebezpiecznych konstrukcji z `sudo`.

---

## 📦 Wersje / Release

| Wersja | Data | Co nowego |
|--------|------|-----------|
| `v1.1.0-security` | 2026-11-12 | Usunięto `curl | sudo bash` (Node.js, Docker) — pobierz + SHA256 + potwierdzenie; usunięto `--trusted-host` z pip; dodano `ca-certificates` + `update-ca-certificates`; przywrócono instalację Java (OpenJDK 17); naprawiono wszystkie ostrzeżenia ShellCheck |
| `v1.0.0` | 2026-11-11 | Pierwsza stabilna wersja: 12 modułów, dashboard web, yt-dlp dashboard, skrypty ffmpeg/media |

Wszystkie release są otagowane na GitHubie:  
https://github.com/technoporada/ArekBox-Installer/releases

---

## 📋 Wymagania systemowe

- Ubuntu / Debian / Linux Mint
- Bash 5+
- Python 3.10+
- Dostęp do `sudo`

---

## 📁 Struktura projektu

```text
ArekBox-Installer/
├── arekbox.sh                 # Główny instalator + menu
├── arekbox-dashboard.sh       # Uruchomienie dashboardu web
├── yt-dlp-dashboard.sh        # Uruchomienie dashboardu yt-dlp
├── modules/
│   ├── ai_tools.sh            # Ollama, TTS, Whisper, lokalny chatbot
│   ├── dev_tools.sh           # Node, Python, Docker, Git, Java, VS Code
│   ├── system_info.sh         # CPU, RAM, dysk, sieć
│   ├── fan_thinkpad.sh        # Sterowanie wentylatorem ThinkPad
│   ├── backup_tools.sh        # Kopie pakietów, konfiguracji, home
│   ├── gaming_tools.sh        # Steam, Lutris, Wine i inne
│   ├── terminal_tools.sh      # tmux, fzf, bat, ripgrep
│   ├── optimize_tools.sh      # RAM, dysk, procesy, tweaki
│   ├── pdf_tools.sh           # Operacje na PDF
│   ├── security_tools.sh      # UFW, ClamAV, Fail2ban, Nmap
│   ├── multimedia_tools.sh    # yt-dlp, FFmpeg, MPV, OBS i inne
│   └── cleanup_tools.sh       # Czyszczenie APT, logów, pip, snap
├── dashboard/
│   ├── arekbox_dashboard.py   # Flask web dashboard
│   ├── audio_visualizer.html  # Wizualizator audio
│   └── yt_dlp_dashboard.py    # yt-dlp web UI
├── ffmpeg-scripts/            # Szybkie konwersje FFmpeg
├── media-scripts/             # Szybkie pobieranie mediów
└── venvs/                     # Środowiska wirtualne Python (tworzone przy instalacji)
```

---

## 📄 Licencja

GNU General Public License v3.0 — [LICENSE](LICENSE)

---

## 👤 Autor

**technoporada** — [github.com/technoporada](https://github.com/technoporada)

Koordynacja i nadzór: użytkownik  
Wykonanie i poprawki bezpieczeństwa: Cline (AI asystent)
