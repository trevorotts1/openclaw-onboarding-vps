# Caption Creator - Examples

This file gives copy-paste examples for the scripts that ship with this skill.

## Table of contents

1. [Export an SRT file](#export-an-srt-file)
2. [Create a captioned video (minimal)](#create-a-captioned-video-minimal)
3. [Create a captioned video (full)](#create-a-captioned-video-full)
4. [Create a captioned video (animated)](#create-a-captioned-video-animated)
5. [Pick a faster or more accurate model](#pick-a-faster-or-more-accurate-model)
6. [Batch process a folder](#batch-process-a-folder)

---

## Export an SRT file

Use this when you want subtitles for YouTube or for your video editor.

```bash
~/.openclaw/skills/caption-creator/Scripts/export-srt.sh \
  --input "my_video.mp4" \
  --output "my_video.srt" \
  --model medium
```

## Create a captioned video (minimal)

```bash
~/.openclaw/skills/caption-creator/Scripts/generate-captions.sh \
  --input "my_video.mp4" \
  --output "my_video_captioned.mp4" \
  --style minimal \
  --model medium
```

## Create a captioned video (full)

Use this when you want bigger captions and maximum readability.

```bash
~/.openclaw/skills/caption-creator/Scripts/generate-captions.sh \
  --input "my_video.mp4" \
  --output "my_video_captioned_full.mp4" \
  --style full \
  --model medium
```

## Create a captioned video (animated)

This style uses `Scripts/animated_captions.py` internally.

```bash
~/.openclaw/skills/caption-creator/Scripts/generate-captions.sh \
  --input "my_video.mp4" \
  --output "my_video_captioned_animated.mp4" \
  --style animated \
  --model medium
```

## Pick a faster or more accurate model

Fast (lower accuracy):

```bash
~/.openclaw/skills/caption-creator/Scripts/export-srt.sh \
  --input "my_video.mp4" \
  --output "my_video.srt" \
  --model base
```

More accurate (slower):

```bash
~/.openclaw/skills/caption-creator/Scripts/export-srt.sh \
  --input "my_video.mp4" \
  --output "my_video.srt" \
  --model large
```

## Batch process a folder

Example: export SRT files for every MP4 in a folder.

1. Open Terminal.
2. `cd` into the folder that contains your videos.
3. Run:

```bash
mkdir -p subtitles

for f in *.mp4; do
  stem="${f%.*}"
  ~/.openclaw/skills/caption-creator/Scripts/export-srt.sh \
    --input "$f" \
    --output "subtitles/${stem}.srt" \
    --model medium

done
```

After it finishes, you will have `subtitles/*.srt`.
