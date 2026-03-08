#!/bin/bash
# export-srt.sh - Export SRT file from video
# Usage: export-srt.sh --input video.mp4 --output captions.srt

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
  echo "Usage: export-srt.sh --input <video> --output <srt> [--model tiny|base|small|medium|large]"
  exit 1
fi

echo "Transcribing with Whisper (model: $MODEL)..."
whisper "$INPUT" --model "$MODEL" --output_format srt --output_dir "$(dirname "$OUTPUT")"

echo "SRT exported to: $OUTPUT"