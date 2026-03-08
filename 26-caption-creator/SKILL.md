# Caption Creator Skill

> **Professional video captioning with AI-powered transcription, multiple styles, and flexible export options.**

## Overview

The Caption Creator Skill provides a complete solution for adding professional captions to videos. It leverages OpenAI's Whisper for accurate transcription and offers multiple caption styles, positioning options, and export formats.

## Features

### Core Capabilities
- **Auto-Transcription**: Whisper-powered speech-to-text with high accuracy
- **Multiple Caption Styles**: Minimal, full, animated/karaoke-style
- **Flexible Positioning**: Bottom, top, centered, follow speaker
- **Customization**: Font, size, color, background controls
- **Smart Enhancements**: Auto-emoji and keyword highlighting
- **Multi-Language**: Support for 99+ languages
- **Video Integration**: Burn captions directly into video
- **Export Options**: SRT, VTT, ASS subtitle formats
- **Template Library**: 10 pre-built professional styles

## Quick Start

```bash
# Install dependencies
pip install openai-whisper moviepy opencv-python

# Generate captions from video
python caption_creator.py --input video.mp4 --style minimal --burn

# Export SRT only
python caption_creator.py --input video.mp4 --export-srt --output captions.srt

# Use a template
python caption_creator.py --input video.mp4 --template youtuber-v1
```

## Caption Styles

### 1. Minimal
Clean, understated captions for professional content.
- White text, subtle shadow
- Bottom-center position
- No background box
- 24px font size

### 2. Full
Comprehensive captions with speaker identification.
- Colored text per speaker
- Background blur box
- Top or bottom position
- 28px font size

### 3. Animated/Karaoke
Word-by-word highlighting for music/lyrics.
- Progressive word highlighting
- Bouncing ball indicator
- Synchronized timing
- 32px bold font

### 4. Social Media
Optimized for Instagram/TikTok/Reels.
- Large bold text (48px)
- High contrast background
- Centered position
- Emoji integration

### 5. Documentary
Cinematic feel for long-form content.
- Serif fonts
- Lower third positioning
- Elegant transitions
- 22px font

### 6. Educational
Enhanced learning with keyword highlights.
- Technical terms highlighted
- Definition popups
- Slower display timing
- 26px font

### 7. News/Broadcast
TV news style captions.
- All caps text
- Solid background bar
- Lower third position
- 30px bold sans-serif

### 8. Gaming
Optimized for gameplay videos.
- Compact size (20px)
- Semi-transparent background
- Minimal obstruction
- High contrast colors

### 9. Interview
Two-person conversation formatting.
- Name labels
- Color-coded speakers
- Side-by-side positioning
- 24px font

### 10. Cinematic
Movie-style captions.
- Yellow text (traditional)
- Black outline
- Bottom position
- 26px font

## Position Options

| Position | Description | Best For |
|----------|-------------|----------|
| `bottom` | Standard bottom-center | General use |
| `top` | Top of screen | Content with bottom UI |
| `center` | Screen center | Short phrases, impact |
| `follow-speaker` | Dynamic positioning | Multi-speaker, interviews |
| `lower-third` | Professional broadcast | News, documentaries |

## Usage

### Command Line

```bash
# Basic usage
python caption_creator.py --input video.mp4

# With specific style
python caption_creator.py --input video.mp4 --style social --position center

# Custom colors
python caption_creator.py --input video.mp4 --font-color "#FFFFFF" --bg-color "#00000080"

# Multi-language
python caption_creator.py --input video.mp4 --language es --translate en

# Export formats
python caption_creator.py --input video.mp4 --export-srt --export-vtt
```

### Python API

```python
from caption_creator import CaptionCreator

# Initialize
creator = CaptionCreator()

# Transcribe
result = creator.transcribe("video.mp4", language="en")

# Generate styled captions
creator.generate_captions(
    style="social",
    position="center",
    font_size=48,
    font_color="#FFFFFF",
    highlight_keywords=True,
    add_emojis=True
)

# Burn to video
creator.burn_to_video("output.mp4")

# Export subtitle files
creator.export_srt("captions.srt")
creator.export_vtt("captions.vtt")
```

## Configuration

### config.json
```json
{
  "whisper_model": "base",
  "default_style": "minimal",
  "default_position": "bottom",
  "font_family": "Arial",
  "output_directory": "./captions_output",
  "auto_sync": true,
  "keyword_highlights": {
    "enabled": true,
    "color": "#FFD700",
    "keywords": []
  },
  "emoji_map": {
    "happy": "😊",
    "love": "❤️",
    "fire": "🔥",
    "warning": "⚠️"
  }
}
```

## Templates

Access pre-built templates:

```bash
# List available templates
python caption_creator.py --list-templates

# Apply template
python caption_creator.py --input video.mp4 --template youtuber-v1

# Create custom template
python caption_creator.py --save-template my-template --style full --font-size 32
```

### Available Templates

1. **youtuber-v1** - Popular YouTuber style (bold, colorful)
2. **tiktok-v1** - Mobile-optimized vertical video
3. **podcast-v1** - Audio-focused with speaker names
4. **corporate-v1** - Professional business style
5. **tutorial-v1** - Educational with highlights
6. **vlog-v1** - Casual vlogging style
7. **news-v1** - Broadcast news format
8. **movie-v1** - Cinematic film style
9. **lyrics-v1** - Music/karaoke style
10. **minimal-v1** - Clean and simple

## Advanced Features

### Keyword Highlighting

Automatically highlight important terms:

```python
creator.set_keywords([
    "important",
    "remember",
    "key point",
    "conclusion"
])
```

### Auto-Emoji

Enable contextual emoji insertion:

```python
creator.enable_auto_emoji(
    sentiment_analysis=True,
    keyword_mapping=True
)
```

### Speaker Detection

For multi-speaker content:

```python
creator.enable_speaker_detection(
    diarization=True,
    max_speakers=4,
    show_labels=True
)
```

### Synchronization

Fix timing issues with ffsubsync integration:

```bash
python caption_creator.py --input video.mp4 --sync --reference reference.srt
```

## File Structure

```
caption-creator/
├── SKILL.md                 # This file
├── INSTALL.md              # Installation guide
├── EXAMPLES.md             # Usage examples
├── Scripts/
│   ├── caption_creator.py  # Main script
│   ├── styles.py           # Style definitions
│   ├── templates.py        # Template manager
│   ├── transcribe.py       # Whisper integration
│   ├── burn_captions.py    # Video rendering
│   └── sync.py             # ffsubsync wrapper
├── References/
│   ├── whisper-docs.md     # Whisper documentation
│   ├── ffsubsync-guide.md  # Synchronization guide
│   └── api-reference.md    # API documentation
└── Templates/
    ├── minimal.json
    ├── full.json
    ├── social.json
    └── ... (10 templates)
```

## Troubleshooting

### Common Issues

**Whisper model download fails**
```bash
# Download manually
whisper --model base --language en dummy.mp3
```

**Video codec issues**
```bash
# Install ffmpeg
brew install ffmpeg  # macOS
apt-get install ffmpeg  # Linux
```

**Memory errors on long videos**
```bash
# Process in chunks
python caption_creator.py --input video.mp4 --chunk-size 300
```

### Performance Tips

- Use smaller Whisper models (tiny/base) for faster processing
- Enable GPU acceleration with `--device cuda`
- Process audio extraction once, reuse for multiple styles
- Use `--preview` to test styles before full render

## Integration with your workflow

### Workflow Integration

```yaml
# In your workflow
steps:
  - name: Generate Captions
    skill: caption-creator
    input: "{{ video_path }}"
    config:
      style: "social"
      position: "center"
      burn: true
      export_srt: true
```

### API Endpoint

```python
# FastAPI endpoint example
@app.post("/captions/generate")
async def generate_captions(
    video: UploadFile,
    style: str = "minimal",
    language: str = "en"
):
    creator = CaptionCreator()
    result = await creator.process(video, style, language)
    return {"output": result.output_path}
```

## References

- [OpenAI Whisper](https://github.com/openai/whisper)
- [ffsubsync](https://github.com/smacke/ffsubsync) - Subtitle synchronization
- [autosub](https://github.com/BingLingGroup/autosub) - Transcription workflow
- [MoviePy](https://zulko.github.io/moviepy/) - Video editing

## License

MIT License - See LICENSE file for details.

## Support

For issues and feature requests, please refer to the your internal documentation or create an issue in the repository.
