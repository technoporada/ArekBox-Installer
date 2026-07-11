#!/bin/bash
AREKBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_VENV="$AREKBOX_DIR/venvs/media"

if [ ! -x "$MEDIA_VENV/bin/python" ]; then
    echo "Środowisko nie skonfigurowane. Uruchom: bash arekbox.sh --setup"
    exit 1
fi

export PATH="$MEDIA_VENV/bin:$PATH"
cd "$AREKBOX_DIR/dashboard"
exec "$MEDIA_VENV/bin/python" yt_dlp_dashboard.py
