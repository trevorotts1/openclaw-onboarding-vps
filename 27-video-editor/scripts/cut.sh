#!/bin/bash
# cut.sh - Extract a clip from a video
# Usage: cut.sh --input video.mp4 --start 00:02:00 --duration 30 --output clip.mp4

set -e

INPUT=""
START=""
DURATION=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --input)
      INPUT="$2"
      shift 2
      ;;
    --start)
      START="$2"
      shift 2
      ;;
    --duration)
      DURATION="$2"
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

if [[ -z "$INPUT" || -z "$START" || -z "$DURATION" || -z "$OUTPUT" ]]; then
  echo "Usage: cut.sh --input <file> --start <HH:MM:SS> --duration <seconds> --output <file>"
  exit 1
fi

ffmpeg -ss "$START" -t "$DURATION" -i "$INPUT" -c copy "$OUTPUT"
echo "Created: $OUTPUT"