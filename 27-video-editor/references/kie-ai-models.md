# KIE.AI Video Models Reference

Complete guide to KIE.AI video models available for video editing and B-roll generation.

## Text-to-Video Generation Models

### Veo 3.1 Series (Google)

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Veo 3.1 Fast** | ~$0.40/video | Up to 1080p | Rapid iteration, social media content, cost-effective B-roll |
| **Veo 3.1 Quality** | ~$2.00/video | Up to 1080p | Premium cinematic B-roll, professional visuals, smoother motion |

**Features:**
- Native audio generation (ambient sound, effects)
- Start & End Frame control for smooth transitions
- Multi-image reference for visual consistency
- Extend feature for clips beyond 8 seconds
- Strong prompt adherence

---

### Sora 2 Series (OpenAI)

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Sora 2** | $0.015/sec | Up to 720p | Creative control, narrative-driven content |
| **Sora 2 Pro (720P)** | $0.045/sec | 720p | Enhanced quality with richer visual/audio details |
| **Sora 2 Pro (1080P)** | $0.10-0.13/sec | 1080p | High-definition generation, commercial production |
| **Sora 2 Storyboard** | Variable | Variable | Precise frame-by-frame creative control, storyboard-based generation |

**Features:**
- Strong physics consistency
- Excellent for narrative sequences
- Creative control tools
- Storyboard integration (Storyboard variant)

**Comparison to Official OpenAI Pricing:**
- KIE.AI: $0.015/sec vs OpenAI: $0.10/sec = **85% savings**
- KIE.AI: $0.045/sec vs OpenAI: $0.30/sec = **85% savings**

---

### Kling 3.0

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Kling 3.0** | Variable | Variable | High-quality video generation, alternative to Veo/Sora |

**Features:**
- Competitive quality to Veo and Sora
- Good motion consistency
- Suitable for various video styles

---

### Wan 2.6

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Wan 2.6** | Variable | Variable | General video creation, diverse content types |

**Features:**
- Versatile video generation
- Good for experimentation
- Alternative style outputs

---

## Specialized Models

### Seed Dance Models

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Seed Dance** | Variable | Variable | Dance/movement-focused video generation, human motion |

**Features:**
- Specialized for human movement and dance
- Better motion capture for figures in motion
- Good for fitness, dance, or action content

---

### Runway Aleph

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Runway Aleph** | Variable | Variable | Video-to-video editing, object manipulation |

**Features:**
- In-context video model for multi-task editing
- Object add/remove
- Relighting
- Style changes
- Angle modifications

---

## Video Enhancement/Upscaling

### Topaz Video AI (via KIE.AI)

| Model | Cost | Resolution | Best For |
|-------|------|------------|----------|
| **Topaz Video Upscaler** | Variable | Up to 4K/8K | AI video upscaling, quality enhancement |

**Features:**
- Upscales low-resolution footage
- Denoising
- Frame interpolation (smooth slow-motion)
- Stabilization
- Face enhancement

**When to Use:**
- Upscaling old/low-res training footage
- Improving video quality before editing
- Creating multiple resolution versions

**Note:** Topaz is a premium tool. For free local upscaling, use **video2x** (`pip install video2x`)

---

## Model Selection Guide

### For B-Roll Generation:

| Budget | Recommended Model | Why |
|--------|-------------------|-----|
| **Tight** | Veo 3.1 Fast | $0.40/video, includes audio, good quality |
| **Standard** | Veo 3.1 Quality | $2.00/video, cinematic, premium output |
| **Creative Control** | Sora 2 Storyboard | Frame-by-frame precision |
| **Action/Dance Content** | Seed Dance | Better human motion |

### For Video Enhancement:

| Task | Recommended Tool |
|------|------------------|
| **Upscale to 4K** | Topaz Video Upscaler (via KIE.AI) or video2x (free local) |
| **Denoise** | Topaz or video2x |
| **Frame interpolation** | Topaz or video2x |

---

## KIE.AI Platform Details

**Pricing Advantage:**
- KIE.AI is 30-85% cheaper than official APIs
- Pay-as-you-go credit system (1 credit ≈ $0.005 USD)

**Technical Details:**
- All tasks are asynchronous (receive task_id, poll for completion)
- Media files stored for 14 days only
- Rate limit: 20 generation requests per 10 seconds per account

**Integration Note:**
KIE.AI is accessed via API calls. The skill doesn't directly integrate with KIE.AI; it provides the workflow and scripts for using KIE.AI-generated content. Users generate B-roll via KIE.AI interface/API separately, then use this skill to merge it with their talking head videos.

---

## Quick Reference: Cost Examples

| Task | Model | Duration | Cost |
|------|-------|----------|------|
| Single B-roll clip | Veo 3.1 Fast | 5 sec | ~$0.40 |
| Premium B-roll clip | Veo 3.1 Quality | 5 sec | ~$2.00 |
| Narrative sequence | Sora 2 | 10 sec | $0.15 |
| HD commercial | Sora 2 Pro 1080P | 10 sec | $1.00-1.30 |
| Upscale 1080p to 4K | Topaz | Per video | Variable |

---

## Workflow Integration

When user's AI helps with B-roll workflow:

1. **Analyze** their talking head video with `analyze-video.sh`
2. **Recommend** appropriate KIE.AI models based on their content and budget
3. **Guide** them to generate B-roll via KIE.AI (they do this step separately)
4. **Merge** the B-roll using `merge-broll.sh` with their original video

The AI doesn't directly call KIE.AI - it guides the user through the process and handles the post-generation editing.