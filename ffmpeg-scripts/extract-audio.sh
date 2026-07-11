#!/bin/bash
[ -z "$1" ] && { echo "Użycie: $0 <plik>"; exit 1; }
ffmpeg -i "$1" -vn -acodec mp3 -ab 192k "${1%.*}.mp3"
