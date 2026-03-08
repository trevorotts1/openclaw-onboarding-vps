#!/bin/bash
# extract-audio.sh - Extract audio from video to use as voiceover
# Usage: extract-audio.sh --input video.mp4 --output audio.aac

set -e

INPUT=""
OUTPUT=""
FORMAT="aac"

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

ffmpeg -i "$INPUT" -vn -c:a copy "$OUTPUT"
echo "Extracted audio: $OUTPUT"