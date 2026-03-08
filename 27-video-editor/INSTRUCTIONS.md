# Video Editor Skill - Complete Instructions

## What This Skill Is

The **Video Editor Skill** is a complete video editing toolkit. Cut clips, resize for platforms, add B-roll, analyze videos, download from YouTube, and more. This is your **Opus Clip replacement** - completely free and local.

**Purpose:** Professional video editing without expensive software or subscriptions.

---

## What It Does

1. **Download Videos** - From YouTube or any URL (yt-dlp)
2. **Cut/Trim Clips** - Extract specific segments by timestamp
3. **Resize/Reframe** - Convert to TikTok (9:16), Instagram (1:1), YouTube (16:9)
4. **Add Captions** - Auto-transcribe and burn in subtitles
5. **B-Roll Integration** - Merge B-roll with talking head videos
6. **Scene Detection** - Automatically find cut points (PySceneDetect)
7. **Audio Extraction** - Pull voiceover tracks
8. **Text Overlays** - Add titles, lower thirds, CTAs
9. **Video Analysis** - Understand content structure
10. **Multi-Platform Export** - One video, many formats

---

## How to Install

### Step 1: Install All Dependencies
```bash
pip install yt-dlp moviepy scenedetect opencv-python openai-whisper
```

### Step 2: Install FFmpeg (if not already installed)
```bash
# macOS
brew install ffmpeg

# Ubuntu/Debian
sudo apt install ffmpeg

# Windows: Download from ffmpeg.org
```

### Step 3: Install the Skill
```bash
openclaw skill install video-editor.skill
```

Or manually:
```bash
unzip video-editor.skill -d ~/.openclaw/skills/
chmod +x ~/.openclaw/skills/video-editor/scripts/*.sh
```

---

## How to Run

### Download YouTube Video
```bash
~/.openclaw/skills/video-editor/scripts/download.sh \
  --url "https://youtube.com/watch?v=..." \
  --output video.mp4
```

### Cut a Clip
```bash
~/.openclaw/skills/video-editor/scripts/cut.sh \
  --input video.mp4 \
  --start 00:05:30 \
  --duration 60 \
  --output clip.mp4
```

### Resize for Platform
```bash
~/.openclaw/skills/video-editor/scripts/resize.sh \
  --input clip.mp4 \
  --platform tiktok \
  --output tiktok_version.mp4
```

### Analyze Video Structure
```bash
~/.openclaw/skills/video-editor/scripts/analyze-video.sh \
  --input video.mp4 \
  --output analysis.json
```

### Add B-Roll to Talking Head
```bash
~/.openclaw/skills/video-editor/scripts/merge-broll.sh \
  --main talking_head.mp4 \
  --broll "broll1.mp4,broll2.mp4" \
  --insert-at "15,45" \
  --output with_broll.mp4
```

### Complete B-Roll Workflow
```bash
~/.openclaw/skills/video-editor/scripts/broll-workflow.sh \
  --input video.mp4 \
  --output final.mp4 \
  --num-broll 3
```

---

## Memory File Updates Required

### Update TOOLS.md
```markdown
### Video Editor (Opus Clip Replacement)
- **Purpose:** Full video editing suite
- **Location:** ~/.openclaw/skills/video-editor/
- **Key Scripts:** download.sh, cut.sh, resize.sh, analyze-video.sh, merge-broll.sh
- **Dependencies:** yt-dlp, moviepy, scenedetect, opencv-python, whisper, ffmpeg
- **Platforms:** TikTok (9:16), Instagram (1:1), YouTube (16:9), LinkedIn
- **Features:** Download, cut, resize, captions, B-roll, scene detection
```

### Update AGENTS.md
```markdown
## Video Editor Agent (Opus Clip Alternative)
I can professionally edit any video:
- Download from YouTube/URLs
- Cut and trim clips
- Resize for any platform (TikTok, IG, YT, LinkedIn)
- Add auto-captions
- Integrate B-roll footage
- Analyze video structure
- Extract audio/voiceover
- Add text overlays

All processing is LOCAL - no subscriptions needed.
```

### Update USER.md
```markdown
## Video Editing Preferences
- Preferred platforms: [tiktok/instagram/youtube/linkedin]
- Default caption style: [minimal/full/animated]
- B-roll insertion style: [frequent/sparse]
- Export quality: [1080p/720p/4K]
```

### Update IDENTITY.md (Optional)
```markdown
### Professional Video Editor
I provide enterprise-level video editing capabilities without enterprise-level costs. I help clients repurpose content, create social media clips, and produce professional videos using local, open-source tools.
```

---

## GitHub Repositories Used

1. **yt-dlp/yt-dlp** - YouTube/video downloading
   - https://github.com/yt-dlp/yt-dlp
   - Downloads videos from 1000+ sites

2. **Zulko/moviepy** - Video editing
   - https://github.com/Zulko/moviepy
   - Python video manipulation

3. **Breakthrough/PySceneDetect** - Scene detection
   - https://github.com/Breakthrough/PySceneDetect
   - Finds optimal cut points automatically

4. **openai/whisper** - Speech-to-text
   - https://github.com/openai/whisper
   - Local transcription for captions

5. **FFmpeg/FFmpeg** - Video processing engine
   - https://github.com/FFmpeg/FFmpeg
   - Industry-standard video processing

---

## For Clients/Customers

### What You Can Do

**"Turn one long video into 50+ social media clips. Add captions automatically. Resize for every platform. All without expensive software."**

**Use Cases:**
- **Repurpose webinars** - "Turn my 60-min webinar into 20 TikTok clips"
- **Podcast clips** - "Extract the best moments for Instagram Reels"
- **YouTube Shorts** - "Convert my long-form content to Shorts format"
- **LinkedIn video** - "Resize my TikToks for LinkedIn engagement"
- **B-roll videos** - "Make my talking head videos more dynamic"

**Examples:**
- Input: 60-minute Zoom recording
- Output: 15 captioned clips ready for TikTok, Instagram, YouTube

- Input: Raw interview footage
- Output: Professional video with B-roll, transitions, captions

**Benefits:**
- **100% Free** - No Opus Clip subscription ($15-29/month)
- **100% Local** - Your videos stay on your machine
- **Unlimited processing** - No credit limits
- **Customizable** - Full control over every setting
- **Professional quality** - Same output as paid tools

---

## How This Skill Relates to Others

### The Foundation of Video Production

Video Editor is the **final step** in most workflows:

```
Storyboard Writer → Video Creator → Caption Creator → [VIDEO EDITOR] → Export
```

But it can also be the **first step:**

```
[VIDEO EDITOR] → Download/Cut → Caption Creator → Export
```

### Integrates With All Other Skills
- Takes output from Video Creator
- Enhances with Caption Creator
- Follows plans from Storyboard Writer
- Polishes and delivers final product

---

## Combined Usage Examples

### Example 1: Opus Clip Replacement Workflow
```bash
# Download YouTube video
video-editor --download "URL" --output raw.mp4

# Analyze for best moments
video-editor --analyze raw.mp4 --output analysis.json

# Extract 5 viral-worthy clips
video-editor --cut raw.mp4 --start 00:02:15 --duration 60 --output clip1.mp4
video-editor --cut raw.mp4 --start 00:08:30 --duration 45 --output clip2.mp4
# ... etc

# Resize for TikTok
video-editor --resize clip1.mp4 --platform tiktok --output clip1_tiktok.mp4

# Add captions
caption-creator --input clip1_tiktok.mp4 --output clip1_final.mp4
```

### Example 2: Professional B-Roll Video
```bash
# Extract segments from main video
video-editor --cut main.mp4 --start 00:00 --duration 8 --output person_intro.mp4
video-editor --cut main.mp4 --start 00:30 --duration 8 --output person_middle.mp4
video-editor --cut main.mp4 --start 01:00 --duration 8 --output person_outro.mp4

# Generate B-roll (using Video Creator)
video-creator --prompt "Office scene" --output broll1.mp4
video-creator --prompt "City skyline" --output broll2.mp4

# Merge with B-roll
video-editor --merge-broll \
  --main main.mp4 \
  --broll "broll1.mp4,broll2.mp4" \
  --insert-at "8,38" \
  --output with_broll.mp4

# Add captions
caption-creator --input with_broll.mp4 --output final.mp4
```

---

## Platform Specifications

| Platform | Ratio | Resolution | Best For |
|----------|-------|------------|----------|
| TikTok | 9:16 | 1080x1920 | Short-form viral |
| Instagram Reels | 9:16 | 1080x1920 | Discovery |
| Instagram Feed | 1:1 | 1080x1080 | Profile grid |
| YouTube | 16:9 | 1920x1080 | Long-form |
| YouTube Shorts | 9:16 | 1080x1920 | Short-form |
| LinkedIn | 16:9 | 1920x1080 | Professional |

---

## Troubleshooting

**"yt-dlp not found"**
→ Run: `pip install yt-dlp`

**"scenedetect error"**
→ Run: `pip install scenedetect`

**"ffmpeg not found"**
→ Install FFmpeg using brew (Mac) or apt (Linux)

**"Permission denied"**
→ Run: `chmod +x ~/.openclaw/skills/video-editor/scripts/*.sh`

**"Whisper model download slow"**
→ First run downloads ~1GB model, be patient

---

## Comparison: Video Editor vs Opus Clip

| Feature | Opus Clip | Video Editor Skill |
|---------|-----------|-------------------|
| **Price** | $15-29/month | **FREE** |
| **Processing** | Cloud (upload needed) | **Local** (private) |
| **Limits** | 60-100 min/month | **Unlimited** |
| **Captions** | Yes | **Yes** |
| **B-Roll** | Yes | **Yes** |
| **Multi-platform** | Yes | **Yes** |
| **Storage** | 3-30 days | **Permanent** |
| **Watermark** | Free plan | **None** |

**Winner:** Video Editor Skill - Same features, zero cost, total privacy.