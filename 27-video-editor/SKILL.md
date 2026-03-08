# 🎬 VIDEO EDITOR SKILL

**Purpose:** Edit existing videos - chop, clip, add B-roll, captions, resize

**For:** Any brand or creator - create viral content like Opus Clip

---

## 🎯 Capabilities Overview

This skill provides professional video editing capabilities with AI-powered features:

| Feature | Description | Tool Used |
|---------|-------------|-----------|
| 📥 Download | Download videos from YouTube/any URL | yt-dlp |
| ✂️ AI Clip Detection | Find viral moments automatically | PySceneDetect + AI analysis |
| 📝 Auto-Captions | 97%+ accuracy subtitle generation | VideoCaptioner + Whisper |
| 🎨 Caption Styles | Animated, minimal, full templates | MoviePy |
| 📐 Reframe/Resize | 9:16, 1:1, 16:9 for all platforms | MoviePy |
| 🎬 Multi-clip Stitch | Combine multiple moments | MoviePy |
| ⭐ Extract Highlights | Auto-extract best moments from long videos | AI analysis |
| 🎭 Add B-roll | Insert supplementary footage | MoviePy |
| 🎨 Brand Templates | Custom fonts, colors, logos | JSON configs |
| 📊 Transcribe & Analyze | Full content transcription + analysis | Whisper + NLP |

---

## 🛠️ Tools Used

| Tool | Stars | Purpose |
|------|-------|---------|
| **MoviePy** | ⭐ 14,352 | Core video editing, compositing, effects |
| **PySceneDetect** | ⭐ 4,559 | Scene detection, shot boundaries |
| **VideoCaptioner** | ⭐ 13,287 | AI subtitle workflow |
| **Auto-Editor** | ⭐ 3,988 | Remove silence, filler words |
| **ffsubsync** | ⭐ 7,575 | Subtitle synchronization |
| **yt-dlp** | ⭐ 100k+ | YouTube/video downloading |
| **Whisper** | OpenAI | Speech-to-text transcription |
| **FFmpeg** | Industry standard | Video processing backend |

---

## 📁 File Structure

```
skills/video-editor/
├── SKILL.md                    # This file
├── INSTALL.md                  # Setup & installation guide
├── EXAMPLES.md                 # Usage examples & tutorials
├── scripts/
│   ├── 01_download.py         # Download from YouTube/URL
│   ├── 02_detect_clips.py     # AI clip detection
│   ├── 03_auto_caption.py     # Auto-caption generation
│   ├── 04_add_captions.py     # Add captions to video
│   ├── 05_reframe.py          # Resize for platforms
│   ├── 06_stitch_clips.py     # Multi-clip stitching
│   ├── 07_extract_highlights.py # Highlight extraction
│   ├── 08_add_broll.py        # Add B-roll footage
│   ├── 09_transcribe.py       # Transcribe & analyze
│   ├── 10_remove_silence.py   # Remove dead air
│   ├── video_editor.py        # Main unified CLI
│   └── utils.py               # Shared utilities
├── brand-templates/
│   ├── blackceo.json          # Example brand config preset
│   ├── minimal.json           # Minimal style
│   ├── bold.json              # Bold/high-energy style
│   └── professional.json      # Corporate style
├── examples/
│   ├── example_short.json     # Short-form config example
│   └── example_long.json      # Long-form config example
└── references/
    ├── moviepy_docs.md        # MoviePy reference
    ├── whisper_setup.md       # Whisper installation
    └── ffmpeg_commands.md     # Useful FFmpeg commands
```

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
pip install yt-dlp moviepy scenedetect opencv-python
```

### 2. Download a Video
```bash
python scripts/01_download.py "https://youtube.com/watch?v=..." --output my_video.mp4
```

### 3. Auto-Generate Viral Clips
```bash
python scripts/02_detect_clips.py my_video.mp4 --min-duration 15 --max-duration 60
```

### 4. Add Captions
```bash
python scripts/03_auto_caption.py my_video.mp4 --style blackceo --output captioned.mp4
```

### 5. Resize for TikTok/Reels
```bash
python scripts/05_reframe.py captioned.mp4 --ratio 9:16 --output tiktok_version.mp4
```

---

## 🎨 Caption Templates

### Available Styles

| Style | Description | Best For |
|-------|-------------|----------|
| **minimal** | Clean white text, no background | Professional, educational |
| **bold** | Large yellow text with shadow | High-energy, sports |
| **animated** | Text animates in word-by-word | Storytelling, hooks |
| **full** | Karaoke-style highlighting | Music, quotes |
| **blackceo** | Example brand colors/fonts preset | Example content |

### Template Structure
```json
{
  "name": "blackceo",
  "font": {
    "family": "Montserrat-Bold",
    "size": 64,
    "color": "#FFFFFF",
    "stroke_color": "#000000",
    "stroke_width": 3
  },
  "background": {
    "enabled": true,
    "color": "#000000",
    "opacity": 0.7,
    "padding": 20,
    "border_radius": 10
  },
  "animation": {
    "type": "word_by_word",
    "speed": 0.3
  },
  "position": {
    "anchor": "bottom_center",
    "margin": 100
  }
}
```

---

## 📐 Platform Specifications

| Platform | Ratio | Resolution | Duration | Format |
|----------|-------|------------|----------|--------|
| **TikTok** | 9:16 | 1080x1920 | < 3 min | MP4 H.264 |
| **Instagram Reels** | 9:16 | 1080x1920 | < 90 sec | MP4 H.264 |
| **YouTube Shorts** | 9:16 | 1080x1920 | < 60 sec | MP4 H.264 |
| **Instagram Feed** | 1:1 | 1080x1080 | Any | MP4 H.264 |
| **Twitter/X** | 16:9 | 1920x1080 | < 2 min 20s | MP4 H.264 |
| **LinkedIn** | 1:1 or 16:9 | 1080x1080 or 1920x1080 | < 10 min | MP4 H.264 |
| **YouTube** | 16:9 | 1920x1080 | Any | MP4 H.264 |

---

## 🤖 AI Clip Detection Algorithm

The AI clip detection uses multiple signals to find viral-worthy moments:

### 1. Scene Detection (PySceneDetect)
- Detects shot boundaries
- Identifies visual changes
- Creates candidate segments

### 2. Audio Analysis
- Volume spikes (excitement)
- Speech rate changes (important points)
- Laughter/applause detection
- Music beat drops

### 3. Content Analysis
- Keyword detection ("important", "secret", "truth")
- Sentiment analysis (high emotion = viral potential)
- Topic clustering (identify main themes)

### 4. Engagement Prediction
- Hook strength (first 3 seconds)
- Pattern interrupts (visual changes)
- Cliffhanger detection

### Output Format
```json
{
  "clips": [
    {
      "start": 45.5,
      "end": 72.3,
      "duration": 26.8,
      "viral_score": 0.87,
      "hooks": ["pattern_interrupt_at_48s", "volume_spike_at_55s"],
      "transcript": "The real secret to success is...",
      "keywords": ["secret", "success"]
    }
  ]
}
```

---

## 📝 Caption Generation Pipeline

### Step 1: Transcription (Whisper)
```python
whisper model: large-v3
language: auto-detect
timestamp: word-level
confidence: > 97%
```

### Step 2: Text Processing
- Remove filler words (um, uh, like)
- Fix grammar/punctuation
- Split into caption chunks (max 40 chars per line)
- Identify speaker changes

### Step 3: Timing Synchronization (ffsubsync)
```
Align transcript with audio
Adjust for background music
Fix drift over time
```

### Step 4: Style Application
- Apply brand template
- Position captions
- Add animations
- Render final video

---

## 🔧 Advanced Features

### Remove Silence (Auto-Editor)
```bash
auto-editor my_video.mp4 --edit audio:threshold=4% --output edited.mp4
```

### Add B-roll
```bash
python scripts/08_add_broll.py main_video.mp4 --broll broll_folder/ --sync transcript.json
```

### Multi-clip Workflow
```bash
# 1. Detect clips
python scripts/02_detect_clips.py long_video.mp4 --output clips.json

# 2. Review and select
python scripts/video_editor.py review clips.json

# 3. Process selected clips
python scripts/video_editor.py batch --config batch_config.json
```

---

## 📊 Quality Checklist

Before publishing, verify:

- [ ] Captions are 97%+ accurate
- [ ] First 3 seconds have a strong hook
- [ ] Video is properly framed for target platform
- [ ] Audio levels are consistent
- [ ] No dead air longer than 2 seconds
- [ ] Brand colors/fonts applied
- [ ] B-roll adds value (not distracting)
- [ ] Export settings match platform specs

---

## 🔗 Useful Links

- [MoviePy Documentation](https://zulko.github.io/moviepy/)
- [PySceneDetect Docs](https://scenedetect.com/projects/Manual/en/latest/)
- [Whisper GitHub](https://github.com/openai/whisper)
- [Auto-Editor Docs](https://auto-editor.com/)
- [FFmpeg Filters](https://ffmpeg.org/ffmpeg-filters.html)

---

## 💡 Tips for Viral Content

1. **Hook in first 3 seconds** - Pattern interrupt, strong statement, or question
2. **Keep it moving** - Cut every 3-5 seconds minimum
3. **Captions are mandatory** - 85% watch without sound
4. **Loop-friendly** - End connects back to beginning
5. **One idea per clip** - Don't try to say everything
6. **Emotion drives shares** - Make them feel something
7. **CTA at the end** - Tell them what to do next

---

**Created for:** General use (originally authored for a specific brand)  
**Last Updated:** 2026-02-21  
**Version:** 1.0.0
