#!/bin/bash
# generate-captions.sh - Auto-generate captions from video using Whisper
# Usage: generate-captions.sh --input video.mp4 --output video_captioned.mp4 [--style minimal|full|animated]

set -e

INPUT=""
OUTPUT=""
STYLE="minimal"
MODEL="medium"

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
    --style)
      STYLE="$2"
      shift 2
      ;;
    --model)
      MODEL="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$OUTPUT" ]]; then
  echo "Usage: generate-captions.sh --input <video> --output <video> [--style minimal|full|animated] [--model tiny|base|small|medium|large]"
  exit 1
fi

BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
TEMP_DIR="/tmp/caption_$(date +%s)"
mkdir -p "$TEMP_DIR"

echo "Transcribing audio with Whisper (model: $MODEL)..."
whisper "$INPUT" --model "$MODEL" --output_format srt --output_dir "$TEMP_DIR"

SRT_FILE="$TEMP_DIR/${BASENAME}.srt"

if [[ ! -f "$SRT_FILE" ]]; then
  echo "Error: Transcription failed"
  exit 1
fi

echo "Applying caption style: $STYLE..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case $STYLE in
  minimal)
    # Simple white text, black outline, bottom center
    ffmpeg -i "$INPUT" -vf "subtitles=$SRT_FILE:force_style='FontSize=16,Alignment=2,OutlineColour=&H80000000,Outline=1,BorderStyle=3'" -c:a copy "$OUTPUT"
    ;;
  full)
    # Larger text, colored background
    ffmpeg -i "$INPUT" -vf "subtitles=$SRT_FILE:force_style='FontSize=20,Alignment=2,OutlineColour=&H80000000,Outline=2,BackColour=&H80000000,BorderStyle=4'" -c:a copy "$OUTPUT"
    ;;
  animated)
    # Uses Python for animated/karaoke-style
    python3 "$SCRIPT_DIR/animated_captions.py" --input "$INPUT" --srt "$SRT_FILE" --output "$OUTPUT"
    ;;
  *)
    echo "Unknown style: $STYLE"
    exit 1
    ;;
esac

rm -rf "$TEMP_DIR"
echo "Created: $OUTPUT"