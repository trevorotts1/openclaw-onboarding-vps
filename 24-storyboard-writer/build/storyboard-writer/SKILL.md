---
name: storyboard-writer
description: Create video storyboards matching AI model capabilities. Plans video structure based on model duration limits (Veo 8s, Sora 10/15/25s, etc.) and generates segment prompts.
---

# Storyboard Writer

Plan a video before generating any clips.

This skill:
- matches your storyboard to the model's clip duration limits
- calculates how many clips you need for a target runtime
- estimates cost using the bundled model database
- exports a storyboard to JSON and Markdown

## Before Running - Collect These from the User

Ask the user ONE AT A TIME before calling the script:

1. **What is the video about?** (topic - required)
2. **How long should it be?** (seconds - default: 60s social, 300s YouTube)
3. **What platform?** YouTube / TikTok / Instagram / General
4. **Budget limit?** (optional - if given, use cheapest model that fits)
5. **Preferred model?** (optional - if none given, recommend based on platform)

**Model recommendation defaults:**
- TikTok / Reels / Shorts (vertical, under 60s) → `veo-3-1` (8s clips)
- YouTube (horizontal, 60s-10min) → `sora-25s` (fewer cuts)
- Budget-first → check `scripts/model-database.json` for lowest-cost option

**Important:** The script generates segment structure and timing. You (the agent) are responsible for writing the actual creative prompt for each segment based on topic, style, tone, and narrative arc. Do not use the template placeholders as final output - replace them with specific, visual, production-ready descriptions.

## Quick Start

### Example: 5-minute video plan with Veo 3.1

```bash
python3 scripts/create_storyboard.py --duration 300 --model veo-3-1 --topic "Product Demo" --output product_demo
```

### Example: 5-minute video plan with Sora (25s clips)

```bash
python3 scripts/create_storyboard.py --duration 300 --model sora-25s --topic "Tutorial" --output tutorial
```

## Model data (durations and pricing)

Durations and pricing come from:
- `scripts/model-database.json`

To see the model IDs this skill supports:

```bash
python3 -c "from scripts.model_database import list_models; print('\n'.join(list_models()))"
```

## What gets generated

Running `create_storyboard.py` writes two files:
- `<output>.json`
- `<output>.md`

## Included files

| File | Purpose |
|------|---------|
| `scripts/create_storyboard.py` | Main storyboard generator |
| `scripts/model_database.py` | Loads model durations and pricing from JSON |
| `scripts/model-database.json` | Canonical model database (durations and pricing) |
