# Storyboard Writer - Examples

## Example 1: 5-minute tutorial with Veo 3.1

```bash
python3 scripts/create_storyboard.py \
  --duration 300 \
  --model veo-3-1 \
  --topic "How to Bake Sourdough" \
  --output sourdough_tutorial
```

What you get:
- a segment-by-segment plan sized to the model's clip duration
- a cost estimate based on `scripts/model-database.json`
- files: `sourdough_tutorial.json`, `sourdough_tutorial.md`

## Example 2: 3-minute promo with Sora (25s clips)

```bash
python3 scripts/create_storyboard.py \
  --duration 180 \
  --model sora-25s \
  --topic "Summer Sale Promotion" \
  --output summer_sale
```

What you get:
- a storyboard with prompts for each segment
- files: `summer_sale.json`, `summer_sale.md`

## Example 3: compare models for the same runtime

```python
from scripts.model_database import calculate_cost

for model_id in ["veo-3-1", "sora-10s", "sora-15s", "sora-25s"]:
    cost = calculate_cost(model_id, 300)
    print(model_id, cost)
```

Notes:
- Pricing changes over time. Update `scripts/model-database.json` to keep estimates current.
