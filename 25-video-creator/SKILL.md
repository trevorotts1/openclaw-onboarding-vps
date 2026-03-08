# VIDEO CREATOR SKILL

Create professional videos from text, scripts, and AI-generated content.

## Overview

The Video Creator Skill provides a complete workflow for generating videos using AI models and assembling them with professional editing capabilities. Built on MoviePy with integrations for AI video generation services.

## Features

- **Text-to-Video**: Convert text descriptions into video content
- **Script-to-Video**: Transform written scripts into complete videos with scenes
- **Multi-Clip Assembly**: Combine multiple video clips with transitions
- **Background Music**: Auto-select and mix soundtracks
- **Transitions**: Professional effects between clips
- **Template Library**: Pre-built video templates for common formats
- **AI Integration**: Connect to KIE.AI and other providers
- **Export**: Multiple formats and quality levels

## Quick Start

```bash
# Install dependencies
pip install moviepy opencv-python requests

# Generate a video from text
python scripts/text_to_video.py "A serene forest with morning light" --duration 5

# Create from script
python scripts/script_to_video.py my_script.txt --output final.mp4

# Use a template
python scripts/template_video.py product_showcase --data product.json
```

## Directory Structure

```
video-creator/
├── SKILL.md              # This file
├── INSTALL.md            # Setup instructions
├── EXAMPLES.md           # Usage examples
├── scripts/              # Video creation tools
│   ├── text_to_video.py
│   ├── script_to_video.py
│   ├── image_to_video.py
│   ├── multi_clip_assembly.py
│   ├── add_music.py
│   ├── transitions.py
│   └── ai_providers.py
├── templates/            # Video templates
│   ├── product_showcase/
│   ├── social_media/
│   ├── tutorial/
│   └── podcast/
└── output/               # Generated videos
```

## Core Tools

### 1. Text-to-Video Generation

```bash
python scripts/text_to_video.py "DESCRIPTION" [options]
```

Options:
- `--duration` - Video length in seconds (default: 5)
- `--resolution` - Output resolution: 720p, 1080p, 4k (default: 1080p)
- `--provider` - AI provider: kieai, runway, pika (default: kieai)
- `--output` - Output filename
- `--style` - Visual style: cinematic, animated, realistic

### 2. Script-to-Video Conversion

```bash
python scripts/script_to_video.py SCRIPT_FILE [options]
```

Script format:
```
SCENE 1: [Description of visual]
VOICEOVER: Text to speak
DURATION: 5s

SCENE 2: [Next scene description]
VOICEOVER: More text
DURATION: 3s
BGM: upbeat
```

### 3. Multi-Clip Assembly

```bash
python scripts/multi_clip_assembly.py clip1.mp4 clip2.mp4 clip3.mp4 [options]
```

Options:
- `--transition` - Effect: fade, slide, wipe, zoom, none
- `--duration` - Max duration per clip
- `--music` - Background music track
- `--output` - Output filename

### 4. Image-to-Video

```bash
python scripts/image_to_video.py IMAGE_PATH [options]
```

Options:
- `--motion` - Animation type: zoom, pan, ken_burns
- `--duration` - Length in seconds
- `--music` - Add background music

### 5. Template Videos

```bash
python scripts/template_video.py TEMPLATE_NAME --data DATA_FILE
```

Available templates:
- `product_showcase` - Product highlight reel
- `social_post` - Optimized for social media
- `tutorial` - Instructional video format
- `testimonial` - Customer testimonial layout
- `podcast_clip` - Audio visualization

## AI Provider Configuration

Configure API keys in `~/.blackceo/config.json`:

```json
{
  "video_providers": {
    "kieai": {
      "api_key": "your_key",
      "endpoint": "https://api.kie.ai/v1"
    },
    "runway": {
      "api_key": "your_key"
    },
    "pika": {
      "api_key": "your_key"
    }
  }
}
```

## Video Templates

### Product Showcase
```bash
python scripts/template_video.py product_showcase --data product.json
```

Data format (product.json):
```json
{
  "product_name": "Widget Pro",
  "images": ["img1.jpg", "img2.jpg"],
  "features": ["Fast", "Reliable", "Affordable"],
  "music": "upbeat",
  "duration": 30
}
```

### Social Media Post
```bash
python scripts/template_video.py social_post --data post.json
```

### Tutorial
```bash
python scripts/template_video.py tutorial --data lesson.json
```

## Music and Audio

### Background Music Library

Built-in genres:
- `upbeat` - Energetic, positive
- `corporate` - Professional, clean
- `calm` - Relaxed, ambient
- `epic` - Dramatic, cinematic
- `lofi` - Chill, background

### Add Music to Video

```bash
python scripts/add_music.py video.mp4 --genre upbeat --fade
```

### Mix Audio Levels

```bash
python scripts/add_music.py video.mp4 --music bgm.mp3 --voiceover voice.mp3 --mix 0.3:1.0
```

## Transitions

Available transitions:
- `fade` - Crossfade between clips
- `slide_left` / `slide_right` - Horizontal slide
- `slide_up` / `slide_down` - Vertical slide
- `wipe` - Wipe transition
- `zoom_in` / `zoom_out` - Zoom effects
- `flip` - 3D flip transition
- `none` - Hard cut

```bash
python scripts/multi_clip_assembly.py *.mp4 --transition fade --duration 1s
```

## Export Options

### Formats
- `mp4` - Universal compatibility (default)
- `webm` - Web optimized
- `mov` - ProRes for editing
- `gif` - Animated GIF (short clips)

### Quality Presets
- `social` - 720p, optimized for platforms
- `web` - 1080p, balanced quality
- `broadcast` - 1080p, high bitrate
- `cinema` - 4K, maximum quality

```bash
python scripts/export.py project.json --format mp4 --quality cinema
```

## Advanced Usage

### Batch Processing

```bash
# Process multiple scripts
for script in scripts/*.txt; do
  python scripts/script_to_video.py "$script"
done
```

### Custom Effects Pipeline

```python
from video_creator import VideoPipeline

pipeline = VideoPipeline()
pipeline.add_clip("intro.mp4")
pipeline.add_transition("fade", duration=0.5)
pipeline.add_clip("content.mp4")
pipeline.add_music("bgm.mp3", volume=0.3)
pipeline.export("final.mp4", quality="1080p")
```

### AI Avatar/Presenter

```bash
python scripts/avatar_video.py --script script.txt --avatar presenter1 --background office
```

## Integration with your workflow

### Skill Commands

```
!video create "description" --duration 10
!video from-script myscript.txt
!video template product_showcase --data product.json
!video assemble clip1.mp4 clip2.mp4 --transition fade
!video add-music video.mp4 --genre upbeat
```

### API Usage

```python
from skills.video_creator import VideoCreator

vc = VideoCreator()
video = vc.text_to_video(
    prompt="A futuristic city at night",
    duration=10,
    style="cinematic"
)
video.add_music(genre="epic")
video.export("output.mp4")
```

## Troubleshooting

### Common Issues

**ImportError: No module named 'moviepy'`**
→ Run: `pip install moviepy opencv-python requests`

**AI generation timeout**
→ Increase timeout: `--timeout 300` or check API key

**Out of memory during export**
→ Reduce quality: `--quality web` or process in chunks

**Audio sync issues**
→ Use constant frame rate: `--fps 30`

### Performance Tips

- Use SSD for temp files: `--temp-dir /ssd/tmp`
- Enable GPU acceleration: `--gpu` (if available)
- Preview before export: `--preview`
- Lower resolution for testing: `--resolution 480p`

## Resources

- MoviePy Docs: https://zulko.github.io/moviepy/
- KIE.AI API: https://docs.kie.ai
- Video Codecs Guide: https://trac.ffmpeg.org/wiki/Encode/H.264

## License

MIT - See LICENSE file for details
