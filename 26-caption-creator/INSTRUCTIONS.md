# Caption Creator Skill - Complete Instructions

## What This Skill Is

The **Caption Creator Skill** automatically generates professional captions for any video. It uses OpenAI's Whisper for transcription and MoviePy for rendering captions directly into videos.

**Purpose:** Make videos accessible, engaging, and platform-ready with perfectly timed captions.

---

## What It Does

1. **Auto-Transcribe** - Converts speech to text with 95%+ accuracy
2. **Multiple Caption Styles** - Minimal, full, or animated/karaoke-style
3. **Multi-Language Support** - Works with 25+ languages
4. **Export Options** - Burn captions into video or export SRT files
5. **Position Control** - Bottom, top, centered, or follow speaker

---

## How to Install

### Step 1: Install Dependencies
```bash
pip install openai-whisper moviepy opencv-python
```

### Step 2: Install the Skill
```bash
openclaw skill install caption-creator.skill
```

Or manually:
```bash
unzip caption-creator.skill -d ~/.openclaw/skills/
chmod +x ~/.openclaw/skills/caption-creator/Scripts/*.sh
```

---

## How to Run

### Basic Caption Generation
```bash
~/.openclaw/skills/caption-creator/Scripts/generate-captions.sh \
  --input video.mp4 \
  --output video_captioned.mp4 \
  --style minimal
```

### Export SRT Only
```bash
~/.openclaw/skills/caption-creator/Scripts/export-srt.sh \
  --input video.mp4 \
  --output captions.srt
```

### Python API
```python
from caption_creator import generate_captions
generate_captions("video.mp4", "output.mp4", style="animated")
```

---

## Memory File Updates Required

### Update TOOLS.md
```markdown
### Caption Creator
- **Purpose:** Auto-generate video captions
- **Location:** ~/.openclaw/skills/caption-creator/
- **Key Scripts:** generate-captions.sh, export-srt.sh
- **Dependencies:** whisper, moviepy, opencv-python
- **Styles:** minimal, full, animated
```

### Update AGENTS.md
```markdown
## Caption Creator Agent
I can add professional captions to videos:
- Auto-transcribe any video
- Multiple caption styles (minimal, full, animated)
- Export SRT files separately
- Multi-language support

Usage: Use generate-captions.sh with --style flag
```

### Update USER.md
```markdown
## Video Caption Preferences
- Default caption style: [minimal/full/animated]
- Preferred position: [bottom/top/center]
- Languages needed: [list]
```

### Update IDENTITY.md (Optional)
```markdown
### Caption Specialist
Part of my role includes making content accessible through professional captioning.
```

---

## GitHub Repositories Used

1. **openai/whisper** - Speech-to-text transcription
   - https://github.com/openai/whisper
   - Local processing, no API needed

2. **Zulko/moviepy** - Video editing and caption rendering
   - https://github.com/Zulko/moviepy
   - Python-based video manipulation

---

## For Clients/Customers

### What You Can Do

**"Make any video accessible and engaging with professional captions."**

**Examples:**
- Add captions to your YouTube videos for better engagement
- Make Instagram Reels accessible to deaf/hard-of-hearing viewers
- Export SRT files for professional editing workflows
- Create karaoke-style animated captions for TikTok

**Benefits:**
- Increases video engagement by 12%
- Makes content accessible to 466M deaf/hard-of-hearing people worldwide
- Improves SEO (search engines can read captions)
- Works in sound-off environments (social media scrolling)

---

## How This Skill Relates to Others

### Works With Video Editor
1. Edit video (Video Editor)
2. Add captions (Caption Creator)
3. Export final video

### Works With Video Creator
1. Create video from script (Video Creator)
2. Add captions (Caption Creator)
3. Post to social media

### Works With Storyboard Writer
1. Plan video structure (Storyboard Writer)
2. Create video (Video Creator)
3. Add captions (Caption Creator)

---

## Combined Usage Examples

### Example 1: Full Video Production Pipeline
```bash
# 1. Plan video
storyboard-writer --duration 300 --model veo-3-1 --topic "Product Demo"

# 2. Create video
video-creator --script script.txt --output video.mp4

# 3. Add captions
caption-creator --input video.mp4 --output final.mp4 --style animated
```

### Example 2: Edit Existing Video
```bash
# 1. Download YouTube video
video-editor --download "URL" --output raw.mp4

# 2. Extract best clips
video-editor --clip raw.mp4 --start 00:05:00 --duration 60 --output clip.mp4

# 3. Add captions
caption-creator --input clip.mp4 --output clip_captioned.mp4
```

---

## Troubleshooting

**"Whisper not found"**
→ Run: `pip install openai-whisper`

**"MoviePy import error"**
→ Run: `pip install moviepy opencv-python`

**"Permission denied on scripts"**
→ Run: `chmod +x ~/.openclaw/skills/caption-creator/Scripts/*.sh`

---

## Quick Reference

| Style | Best For | Command |
|-------|----------|---------|
| minimal | Clean, professional | `--style minimal` |
| full | Maximum readability | `--style full` |
| animated | Social media, TikTok | `--style animated` |