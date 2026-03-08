---
name: storyboard-writer
description: Create video storyboards matching AI model capabilities. Plans video structure based on model duration limits (Veo 8s, Sora 10/15/25s, etc.) and generates segment prompts.
---

# Storyboard Writer

Plan videos before creating them. Matches storyboard to AI model capabilities and durations.

## Quick Start

### Create storyboard for 5-minute video with Veo 3.1:
```bash
python3 scripts/create_storyboard.py --duration 300 --model veo-3-1 --topic "Product Demo"
```

### Create storyboard with Sora 25s model:
```bash
python3 scripts/create_storyboard.py --duration 300 --model sora-25s --topic "Tutorial"
```

## AI Models Supported

| Model | Duration | Cost | Best For |
|-------|----------|------|----------|
| Veo 3.1 | 8 sec | ~$0.40 | Quick, cost-effective |
| Sora 10s | 10 sec | $0.15 | Standard clips |
| Sora 15s | 15 sec | $0.23 | Medium length |
| Sora 25s | 25 sec | $0.38 | Longer scenes |
| Kling 3.0 | Variable | Variable | Alternative style |
| Seed Dance | Variable | Variable | Movement/Dance |
| Wan 2.6 | Variable | Variable | General purpose |

## How It Works

1. **Input**: Total video duration, AI model, topic/theme
2. **Calculate**: Segments needed = Total duration ÷ Clip duration
3. **Generate**: Prompts for each segment with timing
4. **Export**: JSON and Markdown storyboards

## Example Output

For 5-minute (300s) video using Sora 25s:
- 12 segments needed
- Each segment gets prompt + timing
- Total cost estimate: ~$4.56

## Scripts

| Script | Purpose |
|--------|---------|
| create_storyboard.py | Main storyboard generator |
| model_database.py | AI model specs and pricing |
| calculate_segments.py | Math for segment planning |
| export_storyboard.py | Export to JSON/Markdown |

## Installation

```bash
pip install pyyaml
```