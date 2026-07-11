#!/bin/bash
source ~/arekbox/venvs/media/bin/activate
yt-dlp -f 'bestaudio[ext=m4a]' --extract-audio --audio-format mp3 --audio-quality 0 "$1"
