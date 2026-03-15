# Video Editor Examples

All examples assume you are inside the skill folder:

```bash
cd video-editor
```

If you installed the skill into OpenClaw, the scripts live at:

```bash
/data/.openclaw/skills/video-editor/scripts/
```

## Example 1: Download a video from YouTube

```bash
./scripts/download.sh \
  --url "https://www.youtube.com/watch?v=VIDEO_ID" \
  --output input.mp4
```

## Example 2: Cut a 45-second clip starting at 2 minutes

```bash
./scripts/cut.sh \
  --input input.mp4 \
  --start 00:02:00 \
  --duration 45 \
  --output clip.mp4
```

## Example 3: Resize for TikTok/Reels/Shorts (vertical 9:16)

```bash
./scripts/resize.sh \
  --input clip.mp4 \
  --platform tiktok \
  --output clip-vertical.mp4
```

## Example 4: Resize for Instagram square (1:1)

```bash
./scripts/resize.sh \
  --input clip.mp4 \
  --platform instagram \
  --output clip-square.mp4
```

## Example 5: Add captions (Whisper + burn-in)

```bash
./scripts/caption.sh \
  --input clip-vertical.mp4 \
  --output clip-vertical-captioned.mp4 \
  --model medium
```

If you want faster captions, try `--model small`.

## Example 6: One command workflow (cut + resize + caption)

```bash
./scripts/social-clip.sh \
  --input input.mp4 \
  --start 00:00:30 \
  --duration 30 \
  --platform tiktok \
  --output final-30s-captioned.mp4
```

Skip captions:

```bash
./scripts/social-clip.sh \
  --input input.mp4 \
  --start 00:00:30 \
  --duration 30 \
  --platform tiktok \
  --output final-30s-no-captions.mp4 \
  --skip-caption
```

## Example 7: Extract audio (voiceover)

AAC (default):

```bash
./scripts/extract-audio.sh \
  --input input.mp4 \
  --output voiceover.aac
```

MP3:

```bash
./scripts/extract-audio.sh \
  --input input.mp4 \
  --output voiceover.mp3 \
  --format mp3
```

WAV:

```bash
./scripts/extract-audio.sh \
  --input input.mp4 \
  --output voiceover.wav \
  --format wav
```

## Example 8: Analyze a video for scene changes (B-roll planning)

```bash
./scripts/analyze-video.sh \
  --input input.mp4 \
  --output analysis.json
```

Notes:
- The scene count and suggested insertion points depend on the content and the PySceneDetect version.
- Treat `analysis.json` as a starting point for editing decisions.

## Example 9: Merge B-roll into a talking-head video

This uses `moviepy` via the Python helper `scripts/broll_merge.py`.

```bash
./scripts/merge-broll.sh \
  --main talking-head.mp4 \
  --broll "broll1.mp4,broll2.mp4" \
  --insert-at "12,38" \
  --output talking-head-with-broll.mp4
```

If you do NOT want to keep the main audio (rare):

```bash
./scripts/merge-broll.sh \
  --main talking-head.mp4 \
  --broll "broll1.mp4" \
  --insert-at "12" \
  --output talking-head-with-broll.mp4 \
  --no-keep-audio
```

## Example 10: Guided B-roll workflow (staging + suggestions)

This script stages a temporary working folder, prints suggested timestamps, and tells you exactly where to drop your generated B-roll files.

```bash
./scripts/broll-workflow.sh \
  --input talking-head.mp4 \
  --output final.mp4 \
  --num-broll 3
```
