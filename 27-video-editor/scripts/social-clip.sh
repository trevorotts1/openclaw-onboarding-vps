#!/bin/bash
# social-clip.sh - Full workflow: cut + resize + caption
# Usage: social-clip.sh --input video.mp4 --start 00:02:00 --duration 30 --platform tiktok --output clip.mp4

set -e

INPUT=""
START=""
DURATION=""
PLATFORM=""
OUTPUT=""
SKIP_CAPTION=false

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
    --platform)
      PLATFORM="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --skip-caption)
      SKIP_CAPTION=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$START" || -z "$DURATION" || -z "$PLATFORM" || -z "$OUTPUT" ]]; then
  echo "Usage: social-clip.sh --input <file> --start <HH:MM:SS> --duration <seconds> --platform <tiktok|instagram|youtube|linkedin> --output <file> [--skip-caption]"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_CUT="/tmp/temp_cut_$(date +%s).mp4"
TEMP_RESIZED="/tmp/temp_resized_$(date +%s).mp4"

echo "Step 1: Cutting clip..."
"$SCRIPT_DIR/cut.sh" --input "$INPUT" --start "$START" --duration "$DURATION" --output "$TEMP_CUT"

echo "Step 2: Resizing for $PLATFORM..."
"$SCRIPT_DIR/resize.sh" --input "$TEMP_CUT" --platform "$PLATFORM" --output "$TEMP_RESIZED"

if [[ "$SKIP_CAPTION" == false ]]; then
  echo "Step 3: Adding captions..."
  "$SCRIPT_DIR/caption.sh" --input "$TEMP_RESIZED" --output "$OUTPUT"
else
  mv "$TEMP_RESIZED" "$OUTPUT"
fi

rm -f "$TEMP_CUT" "$TEMP_RESIZED"
echo "Done: $OUTPUT"