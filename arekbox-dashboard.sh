#!/bin/bash
AREKBOX_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MEDIA_VENV="$AREKBOX_DIR/venvs/media"

if [ ! -x "$MEDIA_VENV/bin/python" ]; then
    echo "Środowisko nie skonfigurowane. Uruchom: bash arekbox.sh --setup"
    exit 1
fi

# Upewnij się, że Flask i psutil są dostępne
"$MEDIA_VENV/bin/python" -c "import flask, psutil" 2>/dev/null \
    || "$MEDIA_VENV/bin/python" -m pip install --quiet flask psutil

cd "$AREKBOX_DIR/dashboard"
exec "$MEDIA_VENV/bin/python" arekbox_dashboard.py
