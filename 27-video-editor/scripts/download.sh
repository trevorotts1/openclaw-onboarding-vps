#!/bin/bash
# download.sh - Download YouTube video
# Usage: download.sh --url "https://youtube.com/..." --output video.mp4

set -e

URL=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --url)
      URL="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$URL" || -z "$OUTPUT" ]]; then
  echo "Usage: download.sh --url <youtube-url> --output <file>"
  exit 1
fi

yt-dlp "$URL" -o "$OUTPUT" --format "bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4"
echo "Downloaded: $OUTPUT"