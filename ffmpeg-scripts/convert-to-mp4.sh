#!/bin/bash
[ -z "$1" ] && { echo "Użycie: $0 <plik>"; exit 1; }
ffmpeg -i "$1" -c:v libx264 -c:a aac -preset medium -crf 23 "${1%.*}.mp4"
