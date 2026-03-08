# Caption Creator - Usage Examples

This document provides practical examples for using the Caption Creator Skill in various scenarios.

## Table of Contents

1. [Basic Examples](#basic-examples)
2. [Style Examples](#style-examples)
3. [Social Media Workflows](#social-media-workflows)
4. [Multi-Language Content](#multi-language-content)
5. [Advanced Features](#advanced-features)
6. [Batch Processing](#batch-processing)
7. [Integration Examples](#integration-examples)

---

## Basic Examples

### Example 1: Simple Caption Generation

Generate captions for a video with default settings:

```bash
python Scripts/caption_creator.py --input my_video.mp4
```

Output: `my_video_captioned.mp4` with minimal-style bottom captions.

### Example 2: Export Subtitle Files Only

Generate SRT and VTT without burning to video:

```bash
python Scripts/caption_creator.py \
  --input my_video.mp4 \
  --export-srt \
  --export-vtt \
  --no-burn
```

Output: `my_video.srt`, `my_video.vtt`

### Example 3: Custom Output Location

```bash
python Scripts/caption_creator.py \
  --input my_video.mp4 \
  --output-dir ./my_captions/ \
  --filename "final_video"
```

---

## Style Examples

### Example 4: Social Media Style (TikTok/Instagram)

Bold, centered captions optimized for mobile:

```bash
python Scripts/caption_creator.py \
  --input my_video.mp4 \
  --style social \
  --position center \
  --font-size 48 \
  --font-color "#FFFFFF" \
  --bg-color "#00000080"
```

### Example 5: YouTube Vlog Style

Clean, professional captions:

```bash
python Scripts/caption_creator.py \
  --input my_video.mp4 \
  --style minimal \
  --position bottom \
  --font "Arial" \
  --font-size 24 \
  --add-shadow
```

### Example 6: Karaoke/Lyrics Style

Animated word-by-word highlighting for music:

```bash
python Scripts/caption_creator.py \
  --input song_video.mp4 \
  --style karaoke \
  --highlight-color "#FFD700" \
  --animation bounce
```

### Example 7: Documentary Style

Cinematic feel with elegant typography:

```bash
python Scripts/caption_creator.py \
  --input documentary.mp4 \
  --style documentary \
  --font "Georgia" \
  --position lower-third \
  --transition fade
```

### Example 8: Gaming Style

Non-intrusive captions for gameplay:

```bash
python Scripts/caption_creator.py \
  --input gameplay.mp4 \
  --style gaming \
  --position bottom \
  --font-size 20 \
  --bg-opacity 0.5
```

---

## Social Media Workflows

### Example 9: Instagram Reels Workflow

Create mobile-optimized vertical video captions:

```bash
#!/bin/bash
# reels_workflow.sh

INPUT_VIDEO=$1

python Scripts/caption_creator.py \
  --input "$INPUT_VIDEO" \
  --style social \
  --position center \
  --font-size 42 \
  --font-color "#FFFFFF" \
  --bg-color "#000000AA" \
  --add-emojis \
  --max-line-length 20 \
  --output "${INPUT_VIDEO%.mp4}_reels.mp4"
```

### Example 10: YouTube Shorts

```bash
python Scripts/caption_creator.py \
  --input short_video.mp4 \
  --template youtuber-v1 \
  --position bottom \
  --keyword-highlights \
  --export-srt
```

### Example 11: LinkedIn Professional

Corporate-style captions:

```bash
python Scripts/caption_creator.py \
  --input presentation.mp4 \
  --style corporate \
  --font "Helvetica" \
  --font-size 26 \
  --position bottom \
  --no-emojis
```

---

## Multi-Language Content

### Example 12: Spanish Video with English Captions

```bash
python Scripts/caption_creator.py \
  --input spanish_video.mp4 \
  --source-language es \
  --translate en \
  --style minimal \
  --export-srt
```

### Example 13: Generate Captions in Multiple Languages

```bash
#!/bin/bash
# multi_language.sh

VIDEO=$1

# Generate for different markets
for lang in en es fr de zh; do
  python Scripts/caption_creator.py \
    --input "$VIDEO" \
    --target-language "$lang" \
    --export-srt \
    --output "${VIDEO%.mp4}_${lang}.srt"
done
```

### Example 14: Bilingual Captions

Show both source and translated text:

```bash
python Scripts/caption_creator.py \
  --input japanese_video.mp4 \
  --source-language ja \
  --bilingual \
  --translation-lang en \
  --style full
```

---

## Advanced Features

### Example 15: Keyword Highlighting

Highlight important terms:

```bash
python Scripts/caption_creator.py \
  --input tutorial.mp4 \
  --style educational \
  --keywords "important,remember,tip,warning,step" \
  --highlight-color "#FFD700" \
  --bold-keywords
```

### Example 16: Auto-Emoji Insertion

Add contextual emojis:

```bash
python Scripts/caption_creator.py \
  --input fun_video.mp4 \
  --style social \
  --auto-emoji \
  --sentiment-analysis \
  --emoji-map '{"love":"❤️","fire":"🔥","wow":"😮"}'
```

### Example 17: Speaker Detection

For multi-speaker content:

```bash
python Scripts/caption_creator.py \
  --input interview.mp4 \
  --style interview \
  --speaker-diarization \
  --max-speakers 2 \
  --show-speaker-labels \
  --speaker-colors '["#FF6B6B","#4ECDC4"]'
```

### Example 18: Custom Template

Create and use a custom template:

```bash
# Create template
python Scripts/caption_creator.py \
  --save-template brand-template \
  --style minimal \
  --font "BrandFont" \
  --font-size 28 \
  --font-color "#FF5733" \
  --bg-color "#00000060"

# Use template
python Scripts/caption_creator.py \
  --input video.mp4 \
  --template brand-template
```

---

## Batch Processing

### Example 19: Process Multiple Videos

```bash
#!/bin/bash
# batch_caption.sh

for video in *.mp4; do
  echo "Processing: $video"
  python Scripts/caption_creator.py \
    --input "$video" \
    --style minimal \
    --export-srt \
    --output-dir ./output/
done
```

### Example 20: Python Batch Script

```python
# batch_process.py
import os
import glob
from Scripts.caption_creator import CaptionCreator

creator = CaptionCreator()

# Process all videos in folder
for video_path in glob.glob("./videos/*.mp4"):
    print(f"Processing: {video_path}")
    
    # Transcribe once
    result = creator.transcribe(video_path)
    
    # Generate multiple styles
    for style in ["minimal", "social", "full"]:
        output_name = f"{video_path[:-4]}_{style}.mp4"
        creator.generate_captions(style=style)
        creator.burn_to_video(output_name)
    
    # Export subtitles
    creator.export_srt(f"{video_path[:-4]}.srt")
```

---

## Integration Examples

### Example 21: FastAPI Endpoint

```python
# api.py
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse
import tempfile
import os

app = FastAPI()

@app.post("/captions/generate")
async def generate_captions(
    video: UploadFile = File(...),
    style: str = "minimal",
    language: str = "en",
    burn: bool = True
):
    # Save uploaded file
    with tempfile.NamedTemporaryFile(delete=False, suffix=".mp4") as tmp:
        tmp.write(await video.read())
        tmp_path = tmp.name
    
    # Process
    from Scripts.caption_creator import CaptionCreator
    creator = CaptionCreator()
    
    creator.transcribe(tmp_path, language=language)
    creator.generate_captions(style=style)
    
    if burn:
        output_path = tmp_path.replace(".mp4", "_captioned.mp4")
        creator.burn_to_video(output_path)
    else:
        output_path = tmp_path.replace(".mp4", ".srt")
        creator.export_srt(output_path)
    
    # Cleanup temp file
    os.unlink(tmp_path)
    
    return FileResponse(output_path)
```

### Example 22: Workflow Integration

```yaml
# workflow.yaml
name: Caption Video
steps:
  - name: Extract Audio
    run: ffmpeg -i {{ input.video }} -vn -acodec copy audio.aac
    
  - name: Generate Captions
    skill: caption-creator
    input: {{ input.video }}
    config:
      style: {{ input.style | default("minimal") }}
      language: {{ input.language | default("en") }}
      position: {{ input.position | default("bottom") }}
      burn: {{ input.burn | default(true) }}
      export_srt: {{ input.export_srt | default(false) }}
      
  - name: Upload to CDN
    run: aws s3 cp {{ output.captioned_video }} s3://bucket/videos/
```

### Example 23: Discord Bot Integration

```python
# discord_bot.py
import discord
from discord.ext import commands
from Scripts.caption_creator import CaptionCreator

bot = commands.Bot(command_prefix="!")

@bot.command()
async def caption(ctx, style: str = "minimal"):
    """Add captions to attached video."""
    if not ctx.message.attachments:
        await ctx.send("Please attach a video!")
        return
    
    attachment = ctx.message.attachments[0]
    await attachment.save("temp_video.mp4")
    
    # Generate captions
    creator = CaptionCreator()
    creator.transcribe("temp_video.mp4")
    creator.generate_captions(style=style)
    creator.burn_to_video("captioned.mp4")
    
    # Send back
    await ctx.send(file=discord.File("captioned.mp4"))
```

---

## Real-World Use Cases

### Use Case 1: Content Creator Workflow

**Scenario**: YouTuber creating daily vlogs

```bash
# Daily workflow script
VIDEO=$1
THUMBNAIL=$2

# 1. Generate captions
python Scripts/caption_creator.py \
  --input "$VIDEO" \
  --template youtuber-v1 \
  --export-srt

# 2. Create thumbnail with captions (optional)
python Scripts/create_thumbnail.py \
  --video "$VIDEO" \
  --template "$THUMBNAIL" \
  --output thumbnail.jpg

# 3. Upload to YouTube
youtube-upload \
  --title "My Vlog $(date +%Y-%m-%d)" \
  --description "Check out my day!" \
  --tags "vlog,daily" \
  --caption-file "${VIDEO%.mp4}.srt" \
  "${VIDEO%.mp4}_captioned.mp4"
```

### Use Case 2: Podcast to Video

**Scenario**: Convert audio podcast to captioned video

```bash
# podcast_video.sh
AUDIO=$1
BACKGROUND=$2  # Static image or video

# 1. Create video from audio + background
ffmpeg -loop 1 -i "$BACKGROUND" -i "$AUDIO" \
  -c:v libx264 -tune stillimage -c:a aac \
  -b:a 192k -pix_fmt yuv420p -shortest \
  podcast_video.mp4

# 2. Add captions
python Scripts/caption_creator.py \
  --input podcast_video.mp4 \
  --style podcast \
  --speaker-diarization \
  --highlight-quotes

# 3. Export clips for social media
python Scripts/extract_clips.py \
  --input podcast_video_captioned.mp4 \
  --timestamps "00:02:30,00:05:45,00:10:20" \
  --output-dir clips/
```

### Use Case 3: Online Course Production

**Scenario**: Creating educational content

```python
# course_production.py
import os
from Scripts.caption_creator import CaptionCreator

creator = CaptionCreator()

def process_lesson(video_path, lesson_number):
    """Process a single lesson with educational enhancements."""
    
    # Transcribe
    result = creator.transcribe(video_path)
    
    # Generate captions with keyword highlighting
    creator.generate_captions(
        style="educational",
        keywords=[
            "definition",
            "example",
            "important",
            "remember",
            "quiz"
        ],
        highlight_color="#FFD700",
        show_progress_bar=True
    )
    
    # Burn to video
    output = f"lesson_{lesson_number:02d}_captioned.mp4"
    creator.burn_to_video(output)
    
    # Export multiple formats
    creator.export_srt(f"lesson_{lesson_number:02d}.srt")
    creator.export_vtt(f"lesson_{lesson_number:02d}.vtt")
    
    # Generate transcript document
    creator.export_transcript(f"lesson_{lesson_number:02d}_transcript.txt")
    
    return output

# Process all lessons
for i, video in enumerate(sorted(os.listdir("./lessons/")), 1):
    if video.endswith(".mp4"):
        process_lesson(f"./lessons/{video}", i)
```

---

## Tips and Best Practices

1. **Always export SRT**: Even if burning captions, keep SRT for accessibility
2. **Test styles first**: Use `--preview` to check style before full render
3. **Optimize for platform**: Use platform-specific templates
4. **Keep backups**: Save original videos before processing
5. **Batch process**: Process multiple videos overnight
6. **Use GPU**: Enable CUDA for 10x faster Whisper processing
7. **Sync subtitles**: Use ffsubsync if timing seems off
8. **Review output**: Always watch a portion before publishing

## Troubleshooting Examples

### Fix timing issues:
```bash
python Scripts/caption_creator.py \
  --input video.mp4 \
  --sync \
  --ffsubsync-args "--max-offset-seconds 120"
```

### Reduce file size:
```bash
python Scripts/caption_creator.py \
  --input video.mp4 \
  --compress \
  --quality 23 \
  --preset fast
```

### Process long videos in chunks:
```bash
python Scripts/caption_creator.py \
  --input long_video.mp4 \
  --chunk-size 600 \
  --parallel 4
```
