#!/bin/bash
# caption.sh - Auto-generate and burn captions into video
# Usage: caption.sh --input video.mp4 --output captioned.mp4

set -e

INPUT=""
OUTPUT=""
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
  echo "Usage: caption.sh --input <file> --output <file> [--model tiny|base|small|medium|large]"
  exit 1
fi

BASENAME=$(basename "$INPUT" | sed 's/\.[^.]*$//')
SRT_FILE="/tmp/${BASENAME}.srt"

echo "Generating captions with Whisper (model: $MODEL)..."
whisper "$INPUT" --model "$MODEL" --output_format srt --output_dir /tmp

echo "Burning captions into video..."
ffmpeg -i "$INPUT" -vf "subtitles=$SRT_FILE:force_style='FontSize=24,Alignment=2,OutlineColour=&H80000000,Outline=2'" -c:a copy "$OUTPUT"

echo "Created captioned video: $OUTPUT"