# Storyboard Writer - Examples

## Example 1: 5-Minute Tutorial with Veo 3.1

```bash
python3 scripts/create_storyboard.py \
  --duration 300 \
  --model veo-3-1 \
  --topic "How to Bake Sourdough" \
  --output sourdough_tutorial
```

**Result:**
- 38 segments (8s each)
- Estimated cost: $15.20
- Files: `sourdough_tutorial.json`, `sourdough_tutorial.md`

## Example 2: 3-Minute Promo with Sora 25s

```bash
python3 scripts/create_storyboard.py \
  --duration 180 \
  --model sora-25s \
  --topic "Summer Sale Promotion" \
  --output summer_sale
```

**Result:**
- 8 segments (25s each)
- Estimated cost: $3.04
- Files: `summer_sale.json`, `summer_sale.md`

## Example 3: 10-Minute Documentary with Sora 15s

```bash
python3 scripts/create_storyboard.py \
  --duration 600 \
  --model sora-15s \
  --topic "History of Coffee" \
  --output coffee_doc
```

**Result:**
- 40 segments (15s each)
- Estimated cost: $9.20

## Cost Comparison

For a 5-minute (300s) video:

| Model | Clips | Cost |
|-------|-------|------|
| Veo 3.1 (8s) | 38 | $15.20 |
| Sora 10s | 30 | $4.50 |
| Sora 15s | 20 | $4.60 |
| Sora 25s | 12 | $4.56 |

**Best value:** Sora 25s for longer scenes
**Most clips:** Veo 3.1 for variety