#!/bin/bash
# resize.sh - Resize video for social media platforms
# Usage: resize.sh --input video.mp4 --platform tiktok --output resized.mp4

set -e

INPUT=""
PLATFORM=""
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --input)
      INPUT="$2"
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
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT" || -z "$PLATFORM" || -z "$OUTPUT" ]]; then
  echo "Usage: resize.sh --input <file> --platform <tiktok|instagram|youtube|linkedin> --output <file>"
  exit 1
fi

case $PLATFORM in
  tiktok|reels|shorts|vertical)
    # 9:16 aspect ratio, 1080x1920
    ffmpeg -i "$INPUT" -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -crf 23 -c:a copy "$OUTPUT"
    ;;
  instagram|square)
    # 1:1 aspect ratio, 1080x1080
    ffmpeg -i "$INPUT" -vf "scale=1080:1080:force_original_aspect_ratio=decrease,pad=1080:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -crf 23 -c:a copy "$OUTPUT"
    ;;
  youtube|linkedin|landscape)
    # 16:9 aspect ratio, 1920x1080
    ffmpeg -i "$INPUT" -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1" -c:v libx264 -crf 23 -c:a copy "$OUTPUT"
    ;;
  *)
    echo "Unknown platform: $PLATFORM"
    echo "Supported: tiktok, reels, shorts, vertical, instagram, square, youtube, linkedin, landscape"
    exit 1
    ;;
esac

echo "Resized for $PLATFORM: $OUTPUT"