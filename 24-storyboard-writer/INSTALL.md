# Storyboard Writer - Installation Guide

## Quick Install

```bash
pip install pyyaml
```

## Usage

### Basic Storyboard

Create a 5-minute product demo using Veo 3.1:

```bash
cd ~/.openclaw/skills/storyboard-writer/scripts
python3 create_storyboard.py --duration 300 --model veo-3-1 --topic "Product Demo"
```

### With Sora 25s Model

```bash
python3 create_storyboard.py --duration 300 --model sora-25s --topic "Tutorial Video"
```

## Available Models

- `veo-3-1` - 8s clips, ~$0.40/video
- `sora-10s` - 10s clips, $0.15/video
- `sora-15s` - 15s clips, $0.23/video
- `sora-25s` - 25s clips, $0.38/video
- `kling-3` - Variable duration
- `seed-dance` - Movement focused
- `wan-2-6` - General purpose

## Output Files

- `storyboard.json` - Machine-readable format
- `storyboard.md` - Human-readable with all prompts