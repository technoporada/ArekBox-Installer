# ArekBox

[![CI](https://github.com/technoporada/ArekBox-Installer/actions/workflows/ci.yml/badge.svg)](https://github.com/technoporada/ArekBox-Installer/actions)
[![License: GPL v3](https://img.shields.io/badge/license-GPLv3-blue.svg)](LICENSE)
[![Bash](https://img.shields.io/badge/bash-5+-green.svg)](https://gnu.org)
[![Python](https://img.shields.io/badge/python-3.10+-blue.svg)](https://python.org)
[![Platform](https://img.shields.io/badge/platform-Ubuntu%20%7C%20Debian%20%7C%20Mint-orange.svg)](https://ubuntu.com)

**Modular Linux toolkit — AI tools, dev environment, multimedia, security, optimization.**

Single script installer with web dashboard, 12 category modules, and 50+ tools.

> **Keywords:** `linux-toolkit` `ai-tools` `ollama` `multimedia` `security` `system-optimization` `bash` `flask` `yt-dlp` `ffmpeg`

---

## Quick Start

```bash
git clone https://github.com/technoporada/ArekBox-Installer.git
cd ArekBox-Installer
bash arekbox.sh
```

First run auto-installs everything (apt packages + Python venv).

## What's Inside

| Module | Tools |
|--------|-------|
| **AI Tools** | Ollama, Open WebUI, TTS, Whisper, OSINT, local chatbot |
| **Dev Tools** | Node.js, Python venv, Docker, Git, VS Code |
| **System Info** | CPU, RAM, disk, processes, temperatures, network, battery |
| **ThinkPad Fan** | Fan control (auto, manual, monitor) |
| **Backup Tools** | Package backup, config backup, home rsync, tar archives |
| **Gaming Tools** | Steam, Lutris, Wine, GameMode, MangoHud, Heroic |
| **Terminal Tools** | Tmux, fzf, bat, ripgrep, htop/btop |
| **System Optimization** | RAM cache, disk cleanup, process manager, tweaks |
| **PDF Tools** | Merge, split, compress, text extract, PDF→image |
| **Security Tools** | UFW, ClamAV, Fail2ban, Nmap, firewall backup |
| **Multimedia Tools** | yt-dlp, MPV, FFmpeg, OBS, VLC, GIMP, Audacity |
| **Cleanup Tools** | APT cache, logs, kernels, pip, snap cleanup |

## Dashboard

```bash
bash arekbox-dashboard.sh
# → http://localhost:5050
```

Web UI with live system monitor, module browser, audio visualizer.

## System Requirements

- Ubuntu / Debian / Linux Mint
- Bash 5+
- Python 3.10+
- sudo access

## Project Structure

```
ArekBox-Installer/
├── arekbox.sh                 # Main installer + menu
├── arekbox-dashboard.sh       # Dashboard launcher
├── modules/
│   ├── ai_tools.sh            # Ollama, TTS, Whisper, OSINT
│   ├── dev_tools.sh           # Node, Python, Docker, Git
│   ├── system_info.sh         # CPU, RAM, disk, network
│   ├── fan_thinkpad.sh        # ThinkPad fan control
│   ├── backup_tools.sh        # rsync, tar, config backup
│   ├── gaming_tools.sh        # Steam, Lutris, Wine
│   ├── terminal_tools.sh      # tmux, fzf, bat, ripgrep
│   ├── optimize_tools.sh      # RAM, disk, process manager
│   ├── pdf_tools.sh           # PyPDF2 operations
│   ├── security_tools.sh      # UFW, ClamAV, Nmap
│   ├── multimedia_tools.sh    # yt-dlp, FFmpeg, MPV
│   └── cleanup_tools.sh       # APT, cache, logs, snap
├── dashboard/
│   ├── arekbox_dashboard.py   # Flask web dashboard
│   ├── audio_visualizer.html  # Audio spectrum visualizer
│   └── yt_dlp_dashboard.py    # yt-dlp web UI
├── ffmpeg-scripts/            # Quick FFmpeg conversions
├── media-scripts/             # Quick media downloads
└── yt-dlp-dashboard.sh        # yt-dlp dashboard launcher
```

## License

GNU General Public License v3.0

## Author

**technoporada** — [github.com/technoporada](https://github.com/technoporada)
