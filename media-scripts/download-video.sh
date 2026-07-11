#!/bin/bash
source ~/arekbox/venvs/media/bin/activate
yt-dlp -f 'best[height<=1080]' "$1"
