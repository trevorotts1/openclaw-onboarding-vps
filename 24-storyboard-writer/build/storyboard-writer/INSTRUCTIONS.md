# Storyboard Writer - Instructions

## What this skill does

Storyboard Writer plans a video before you generate any clips.

It:
1. takes a target runtime (in seconds)
2. uses the chosen model's clip duration
3. calculates how many clips you need
4. generates a prompt for each segment
5. exports JSON and Markdown files

## Where pricing and durations come from

Pricing and duration limits are read from:
- `scripts/model-database.json`

If estimates look wrong, update that JSON file.

## How to run

### 1) Create a storyboard

```bash
python3 scripts/create_storyboard.py \
  --duration 300 \
  --model sora-25s \
  --topic "Product Tutorial" \
  --output my_storyboard
```

You should see:
- a confirmation message
- the number of segments
- the estimated cost
- files written: `my_storyboard.json` and `my_storyboard.md`

### 2) List available model IDs

```bash
python3 -c "from scripts.model_database import list_models; print('\n'.join(list_models()))"
```

### 3) Get a cost estimate in Python

```python
from scripts.model_database import calculate_cost

cost = calculate_cost("sora-25s", 300)
print(cost)
```

## Allowed core file updates

This skill is only allowed to add pointers to:
- `TOOLS.md`
- `MEMORY.md`

Follow `CORE_UPDATES.md` for the exact text to add.

## Troubleshooting

### "Unknown model"
- Run the "List available model IDs" command above.
- Use one of the IDs it prints.

### No output files created
- Make sure you have permission to write to the current folder.
- Try running with a different `--output` name.
