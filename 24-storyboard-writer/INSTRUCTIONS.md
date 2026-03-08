# Storyboard Writer Skill - Complete Instructions

## What This Skill Is

The **Storyboard Writer Skill** plans video structures before creation. It calculates how many AI-generated clips you need based on your chosen model's duration limits (Veo 8s, Sora 10/15/25s, etc.) and generates prompts for each segment.

**Purpose:** Eliminate guesswork in AI video planning. Know exactly how many clips to generate and what they'll cost.

---

## What It Does

1. **Model Selection** - Choose from Veo, Sora, Kling, Seed Dance, Wan
2. **Segment Calculation** - Total duration ÷ Clip duration = Number of clips
3. **Cost Estimation** - Shows exact cost before you start
4. **Prompt Generation** - Creates AI prompts for each video segment
5. **Export** - JSON (for machines) and Markdown (for humans)

---

## How to Install

### Step 1: Install Dependencies
```bash
pip install pyyaml
```

### Step 2: Install the Skill
```bash
openclaw skill install storyboard-writer.skill
```

Or manually:
```bash
unzip storyboard-writer.skill -d ~/.openclaw/skills/
```

---

## How to Run

### Create Storyboard for 5-Minute Video
```bash
python3 ~/.openclaw/skills/storyboard-writer/scripts/create_storyboard.py \
  --duration 300 \
  --model sora-25s \
  --topic "Product Tutorial" \
  --output my_storyboard
```

### List Available Models
```python
from storyboard_writer.scripts.model_database import list_models
print(list_models())
```

### Calculate Cost
```python
from storyboard_writer.scripts.model_database import calculate_cost
cost = calculate_cost("sora-25s", 300)
print(f"Need {cost['num_clips']} clips, total cost: ${cost['total_cost']}")
```

---

## Memory File Updates Required

### Update TOOLS.md
```markdown
### Storyboard Writer
- **Purpose:** Plan AI video generation
- **Location:** ~/.openclaw/skills/storyboard-writer/
- **Key Scripts:** create_storyboard.py, model_database.py
- **Dependencies:** pyyaml
- **Models:** veo-3-1, sora-10s/15s/25s, kling-3, seed-dance, wan-2-6
```

### Update AGENTS.md
```markdown
## Storyboard Planning Agent
I can plan AI video generation projects:
- Calculate segments needed for any duration
- Estimate costs for different AI models
- Generate prompts for each video segment
- Export storyboards to JSON/Markdown

Models supported: Veo 3.1, Sora (10/15/25s), Kling, Seed Dance, Wan
```

### Update USER.md
```markdown
## AI Video Preferences
- Preferred model: [veo-3-1/sora-25s/kling-3/etc]
- Budget per video: [$ amount]
- Typical video length: [minutes]
```

### Update IDENTITY.md (Optional)
```markdown
### Video Planning Specialist
I help clients plan efficient AI video projects with accurate cost and timeline estimates.
```

---

## GitHub Repositories Used

This skill is client-generic and can be used for any brand or creator. No external repositories required - it uses Python standard library + pyyaml.

**Model pricing data sourced from:**
- KIE.AI documentation
- OpenAI Sora documentation
- Google Veo documentation

---

## For Clients/Customers

### What You Can Do

**"Plan your AI video before spending a dime. Know exactly what it will cost and how long it will take."**

**Example Scenario:**
You want a 5-minute product demo video.

**Without Storyboard Writer:**
- Guess how many clips you need
- Realize mid-project you're over budget
- Generated clips don't flow together

**With Storyboard Writer:**
- "You need 12 clips using Sora 25s model"
- "Total cost: $4.56"
- "Here are prompts for each segment with timing"
- Export and follow the plan

**Benefits:**
- No budget surprises
- Logical video flow
- Optimized model selection
- Ready-to-use prompts

---

## How This Skill Relates to Others

### First Step in Video Creation Pipeline
**Order: Storyboard → Video Creator → Caption Creator → Video Editor**

1. **Storyboard Writer** - Plan the video structure
2. **Video Creator** - Generate the AI clips
3. **Caption Creator** - Add captions
4. **Video Editor** - Final polish and export

### Works With Video Creator
Storyboard Writer outputs directly feed into Video Creator:
- Storyboard JSON → Script input
- Segment prompts → Text-to-video prompts

---

## Combined Usage Examples

### Example 1: Complete Video Production
```bash
# 1. PLAN: Create storyboard
python3 create_storyboard.py \
  --duration 300 \
  --model sora-25s \
  --topic "Coffee Brewing Guide" \
  --output coffee_guide

# Output: coffee_guide.json and coffee_guide.md

# 2. CREATE: Use storyboard to generate video
video-creator --storyboard coffee_guide.json --output coffee_video.mp4

# 3. CAPTION: Add captions
caption-creator --input coffee_video.mp4 --output coffee_final.mp4
```

### Example 2: Compare Costs Before Deciding
```python
# Compare different models for same 5-minute video
for model in ["veo-3-1", "sora-10s", "sora-25s"]:
    cost = calculate_cost(model, 300)
    print(f"{model}: {cost['num_clips']} clips, ${cost['total_cost']}")

# Output shows best value option
```

---

## Model Comparison Reference

| Model | Clip Length | Cost/Clip | Best For |
|-------|-------------|-----------|----------|
| Veo 3.1 | 8 sec | $0.40 | Budget-conscious, many clips |
| Sora 10s | 10 sec | $0.15 | Standard content |
| Sora 15s | 15 sec | $0.23 | Medium scenes |
| Sora 25s | 25 sec | $0.38 | Long continuous shots |

**Pro Tip:** For a 5-minute video, Sora 25s gives you the best value at ~$4.56 total.

---

## Troubleshooting

**"Model not found"**
→ Use exact model ID: veo-3-1, sora-10s, sora-15s, sora-25s

**"No output files"**
→ Check you have write permissions in current directory

**"Import error"**
→ Run: `pip install pyyaml`