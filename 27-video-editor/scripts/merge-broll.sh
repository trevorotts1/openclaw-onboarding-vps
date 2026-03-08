#!/bin/bash
# merge-broll.sh - Merge B-roll clips with talking head video, keeping audio continuous
# Usage: merge-broll.sh --main video.mp4 --broll broll1.mp4,broll2.mp4 --insert-at 5,15,25 --output final.mp4

set -e

MAIN=""
BROLL=""
INSERT_AT=""
OUTPUT=""
KEEP_AUDIO=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --main)
      MAIN="$2"
      shift 2
      ;;
    --broll)
      BROLL="$2"
      shift 2
      ;;
    --insert-at)
      INSERT_AT="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --no-keep-audio)
      KEEP_AUDIO=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$MAIN" || -z "$BROLL" || -z "$INSERT_AT" || -z "$OUTPUT" ]]; then
  echo "Usage: merge-broll.sh --main <talking-head.mp4> --broll <broll1.mp4,broll2.mp4> --insert-at <5,15,25> --output <final.mp4>"
  echo ""
  echo "Example: Insert broll clips at 5 seconds, 15 seconds, and 25 seconds"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/broll_$(date +%s)"
mkdir -p "$TEMP_DIR"

# Extract audio from main video if keeping audio
if [[ "$KEEP_AUDIO" == true ]]; then
  echo "Extracting audio from main video..."
  "$SCRIPT_DIR/extract-audio.sh" --input "$MAIN" --output "$TEMP_DIR/audio.aac"
  AUDIO_TRACK="$TEMP_DIR/audio.aac"
fi

# Create concat list for FFmpeg
CONCAT_LIST="$TEMP_DIR/concat.txt"
echo "" > "$CONCAT_LIST"

# Parse B-roll files and insertion points
IFS=',' read -ra BROLL_FILES <<< "$BROLL"
IFS=',' read -ra INSERT_POINTS <<< "$INSERT_AT"

if [[ ${#BROLL_FILES[@]} != ${#INSERT_POINTS[@]} ]]; then
  echo "Error: Number of B-roll clips (${#BROLL_FILES[@]}) must match number of insertion points (${#INSERT_POINTS[@]})"
  rm -rf "$TEMP_DIR"
  exit 1
fi

# Build the filter complex for FFmpeg
FILTER_COMPLEX=""
INPUT_COUNT=0

# Add main video as first input
FILTER_COMPLEX="[0:v]setpts=PTS-STARTPTS[main];"

# Add each B-roll clip
for i in "${!BROLL_FILES[@]}"; do
  BROLL_FILE="${BROLL_FILES[$i]}"
  INSERT_TIME="${INSERT_POINTS[$i]}"
  
  if [[ ! -f "$BROLL_FILE" ]]; then
    echo "Error: B-roll file not found: $BROLL_FILE"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  echo "Will insert $BROLL_FILE at $INSERT_TIME seconds"
  
  # Add B-roll to filter complex
  INPUT_COUNT=$((INPUT_COUNT + 1))
done

# For simplicity, use Python/MMoviePy for complex merging
echo "Using Python for complex B-roll merging..."

python3 << PYTHON_EOF
import sys
sys.path.insert(0, "${SCRIPT_DIR}")
from broll_merge import merge_broll

broll_files = "${BROLL}".split(',')
insert_times = [float(x) for x in "${INSERT_AT}".split(',')]

merge_broll(
    main_video="${MAIN}",
    broll_clips=broll_files,
    insert_times=insert_times,
    output="${OUTPUT}",
    keep_main_audio=${KEEP_AUDIO}
)
PYTHON_EOF

# Clean up
rm -rf "$TEMP_DIR"

echo "Created: $OUTPUT"