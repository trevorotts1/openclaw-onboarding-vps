#!/bin/bash
# extract-audio.sh - Extract audio from a video (voiceover, podcast audio, etc.)
# Usage:
#   extract-audio.sh --input video.mp4 --output audio.aac
#   extract-audio.sh --input video.mp4 --output audio.mp3 --format mp3
#   extract-audio.sh --input video.mp4 --output audio.wav --format wav

set -e

INPUT=""
OUTPUT=""
FORMAT="aac"   # aac|mp3|wav

while [[ $# -gt 0 ]]; do
  case $1 in
    --input)
      INPUT="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --format)
      FORMAT="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Usage: extract-audio.sh --input <video> --output <audio> [--format aac|mp3|wav]"
  exit 1
fi

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "ERROR: ffmpeg not found. Install it first (see INSTALL.md)."
  exit 1
fi

CODEC=""
EXTRA_ARGS=()

case "$FORMAT" in
  aac)
    CODEC="aac"
    EXTRA_ARGS=( -b:a 192k )
    ;;
  mp3)
    CODEC="libmp3lame"
    EXTRA_ARGS=( -q:a 2 )
    ;;
  wav)
    CODEC="pcm_s16le"
    EXTRA_ARGS=( -ar 44100 )
    ;;
  *)
    echo "Unknown format: $FORMAT"
    echo "Supported: aac, mp3, wav"
    exit 1
    ;;
esac

ffmpeg -y -i "$INPUT" -vn -c:a "$CODEC" "${EXTRA_ARGS[@]}" "$OUTPUT"

echo "Extracted audio ($FORMAT): $OUTPUT"
