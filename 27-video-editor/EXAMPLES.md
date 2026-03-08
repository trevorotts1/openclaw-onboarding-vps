# 📚 Usage Examples & Tutorials

**Video Editor Skill (Client-Generic)**

---

## Table of Contents

1. [Basic Workflows](#basic-workflows)
2. [Viral Clip Creation](#viral-clip-creation)
3. [Caption Workflows](#caption-workflows)
4. [Platform Optimization](#platform-optimization)
5. [Advanced Techniques](#advanced-techniques)
6. [Batch Processing](#batch-processing)

---

## Basic Workflows

### Example 1: Download & Repurpose YouTube Video

```bash
# Step 1: Download video
python scripts/01_download.py \
  "https://youtube.com/watch?v=EXAMPLE" \
  --output raw_video.mp4

# Step 2: Detect best clips
python scripts/02_detect_clips.py \
  raw_video.mp4 \
  --min-duration 30 \
  --max-duration 60 \
  --output clips.json

# Step 3: Process best clip
python scripts/video_editor.py process \
  --input raw_video.mp4 \
  --clips clips.json \
  --clip-index 0 \
  --add-captions \
  --style blackceo \
  --output viral_clip.mp4
```

### Example 2: Add Captions to Existing Video

```bash
# Simple captions
python scripts/03_auto_caption.py \
  my_video.mp4 \
  --style minimal \
  --output captioned.mp4

# With custom positioning
python scripts/03_auto_caption.py \
  my_video.mp4 \
  --style bold \
  --position bottom \
  --highlight-keywords \
  --output viral.mp4
```

### Example 3: Resize for Multiple Platforms

```bash
# Create all platform versions
python scripts/05_reframe.py \
  video.mp4 \
  --platforms tiktok,instagram,youtube \
  --output-dir ./exports/

# Individual platform
python scripts/05_reframe.py \
  video.mp4 \
  --ratio 9:16 \
  --smart-crop center \
  --output tiktok_version.mp4
```

---

## Viral Clip Creation

### Example 4: Full Viral Pipeline

```bash
# Complete workflow from URL to viral clips
python scripts/video_editor.py viral \
  --url "https://youtube.com/watch?v=..." \
  --num-clips 5 \
  --style blackceo \
  --platforms tiktok,instagram,youtube \
  --output-dir ./viral_clips/
```

This will:
1. Download the video
2. Detect viral-worthy moments
3. Generate captions for each clip
4. Resize for all platforms
5. Export ready-to-post files

### Example 5: Extract Hook Moments

```bash
# Find the best hooks (first 3 seconds of clips)
python scripts/02_detect_clips.py \
  long_video.mp4 \
  --detect-hooks \
  --hook-duration 3 \
  --output hooks.json

# Preview hooks
python scripts/video_editor.py preview \
  --input long_video.mp4 \
  --clips hooks.json
```

### Example 6: Multi-clip Compilation

```bash
# Create compilation from multiple sources
python scripts/06_stitch_clips.py \
  --clips clip1.mp4 clip2.mp4 clip3.mp4 \
  --transitions crossfade \
  --add-captions \
  --output compilation.mp4

# With auto-selected B-roll
python scripts/06_stitch_clips.py \
  --clips clip1.mp4 clip2.mp4 \
  --broll broll_folder/ \
  --broll-frequency 10 \
  --output final.mp4
```

---

## Caption Workflows

### Example 7: Custom Caption Style

```bash
# Create custom style
python scripts/03_auto_caption.py \
  video.mp4 \
  --custom-style '{
    "font": "Montserrat-Bold",
    "size": 72,
    "color": "#FFD700",
    "background": "#000000",
    "animation": "bounce"
  }' \
  --output custom.mp4
```

### Example 8: Edit Captions Manually

```bash
# Generate SRT first
python scripts/09_transcribe.py \
  video.mp4 \
  --format srt \
  --output subtitles.srt

# Edit subtitles.srt in any text editor
# Then apply to video
python scripts/04_add_captions.py \
  video.mp4 \
  --srt subtitles.srt \
  --style blackceo \
  --output final.mp4
```

### Example 9: Multi-language Captions

```bash
# Generate captions in multiple languages
for lang in en es fr; do
  python scripts/03_auto_caption.py \
    video.mp4 \
    --language $lang \
    --style minimal \
    --output "video_${lang}.mp4"
done
```

---

## Platform Optimization

### Example 10: TikTok-Optimized Export

```bash
python scripts/video_editor.py export \
  --input video.mp4 \
  --platform tiktok \
  --duration 60 \
  --hook-strength high \
  --captions-style bold \
  --output tiktok_ready.mp4

# Settings applied:
# - 9:16 aspect ratio
# - 1080x1920 resolution
# - H.264 codec
# - Captions optimized for mobile
```

### Example 11: YouTube Shorts

```bash
python scripts/video_editor.py export \
  --input video.mp4 \
  --platform youtube_shorts \
  --duration 58 \
  --loop-optimization \
  --output shorts_ready.mp4

# Ensures video loops seamlessly
# Optimized for Shorts algorithm
```

### Example 12: Instagram Reels

```bash
python scripts/video_editor.py export \
  --input video.mp4 \
  --platform instagram_reels \
  --safe-zones \
  --output reels_ready.mp4

# Adds safe zones for UI elements
# Optimized for engagement
```

### Example 13: LinkedIn Professional

```bash
python scripts/video_editor.py export \
  --input video.mp4 \
  --platform linkedin \
  --style professional \
  --caption-professional \
  --output linkedin_ready.mp4

# Professional caption style
# Optimized for sound-off viewing
```

---

## Advanced Techniques

### Example 14: Remove Silence & Fillers

```bash
# Remove dead air
python scripts/10_remove_silence.py \
  video.mp4 \
  --threshold 4% \
  --min-silence 0.5 \
  --output tight.mp4

# Remove filler words
auto-editor video.mp4 \
  --edit audio:threshold=3% \
  --cut-out "um,uh,like,you know" \
  --output polished.mp4
```

### Example 15: Add B-roll with AI Sync

```bash
# Auto-sync B-roll to content
python scripts/08_add_broll.py \
  main_video.mp4 \
  --broll ./broll_library/ \
  --sync-mode ai \
  --keywords "office,meeting,computer" \
  --output with_broll.mp4

# Manual sync points
python scripts/08_add_broll.py \
  main_video.mp4 \
  --broll broll1.mp4 broll2.mp4 \
  --insert-at 5.2 15.8 32.1 \
  --duration 2.0 \
  --output manual_broll.mp4
```

### Example 16: Content Analysis

```bash
# Full video analysis
python scripts/09_transcribe.py \
  video.mp4 \
  --analyze \
  --output analysis.json

# Output includes:
# - Full transcript
# - Key topics
# - Sentiment over time
# - Engagement predictions
# - Suggested clips
```

### Example 17: Brand Template Application

```bash
# Apply example brand preset
python scripts/video_editor.py brand \
  --input video.mp4 \
  --brand blackceo \
  --captions \
  --logo \
  --outro \
  --output branded.mp4

# Custom brand
python scripts/video_editor.py brand \
  --input video.mp4 \
  --brand-config ./my_brand.json \
  --output branded.mp4
```

---

## Batch Processing

### Example 18: Batch Process Multiple Videos

```bash
# Process all videos in folder
python scripts/video_editor.py batch \
  --input-dir ./raw_videos/ \
  --config batch_config.json \
  --output-dir ./processed/

# batch_config.json example:
{
  "operations": [
    {"type": "remove_silence", "threshold": 4},
    {"type": "detect_clips", "min_duration": 30, "max_duration": 60},
    {"type": "add_captions", "style": "blackceo"},
    {"type": "reframe", "platforms": ["tiktok", "instagram"]}
  ],
  "parallel": true,
  "workers": 4
}
```

### Example 19: YouTube Channel to Shorts

```bash
# Convert entire channel to Shorts
python scripts/video_editor.py channel \
  --channel "@YourChannel" \
  --strategy shorts \
  --num-videos 10 \
  --output-dir ./shorts/

# Process:
# 1. Download latest videos
# 2. Detect viral moments
# 3. Create 10 Shorts per video
# 4. Apply branding
# 5. Export batch
```

---

## JSON Configuration Examples

### Complete Project Config

```json
{
  "project": {
    "name": "CEO Tips Series",
    "output_dir": "./exports/"
  },
  "source": {
    "type": "youtube",
    "url": "https://youtube.com/watch?v=..."
  },
  "processing": {
    "download": {
      "quality": "1080p",
      "format": "mp4"
    },
    "clip_detection": {
      "enabled": true,
      "min_duration": 30,
      "max_duration": 60,
      "viral_threshold": 0.7
    },
    "captions": {
      "enabled": true,
      "style": "blackceo",
      "highlight_keywords": true,
      "animation": "word_by_word"
    },
    "reframe": {
      "platforms": ["tiktok", "instagram", "youtube"]
    },
    "broll": {
      "enabled": true,
      "source": "./broll/",
      "frequency": "every_15_seconds"
    }
  },
  "branding": {
    "template": "blackceo",
    "logo": "./assets/logo.png",
    "outro": "./assets/outro.mp4"
  },
  "export": {
    "formats": ["mp4"],
    "quality": "high",
    "max_file_size": "50MB"
  }
}
```

Run with:
```bash
python scripts/video_editor.py run --config project.json
```

---

## Command Reference Quick Sheet

```bash
# Download
01_download.py <url> --output <file>

# Detect clips
02_detect_clips.py <video> --min-duration 30 --max-duration 60

# Auto caption
03_auto_caption.py <video> --style <style> --output <file>

# Reframe
05_reframe.py <video> --ratio 9:16 --output <file>

# Stitch
06_stitch_clips.py --clips <files> --output <file>

# Transcribe
09_transcribe.py <video> --analyze --output <file>

# Remove silence
10_remove_silence.py <video> --threshold 4 --output <file>

# Full pipeline
video_editor.py viral --url <url> --num-clips 5
```

---

## Troubleshooting Common Issues

### "Caption text is too small/big"
```bash
python scripts/03_auto_caption.py video.mp4 --style blackceo --font-scale 1.5
```

### "Video quality is poor"
```bash
python scripts/05_reframe.py video.mp4 --quality high --bitrate 8M
```

### "Audio is out of sync"
```bash
ffsubsync video.mp4 -i subtitles.srt -o synced.srt
```

### "Processing is slow"
```bash
# Use GPU acceleration
export WHISPER_GPU=true
python scripts/03_auto_caption.py video.mp4 --gpu
```

---

## Best Practices

1. **Always preview clips before full export**
2. **Keep source videos in original quality**
3. **Use consistent branding across all content**
4. **Test captions on mobile devices**
5. **Monitor viral scores and iterate**
6. **Batch process during off-peak hours**
7. **Keep B-roll organized by category**
8. **Backup your brand templates**

---

**Ready to create viral content!** 🚀

For more help, see SKILL.md or check the references/ folder.
