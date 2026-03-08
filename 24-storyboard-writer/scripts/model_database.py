#!/usr/bin/env python3
"""
model_database.py - AI video model specifications
"""

MODELS = {
    "veo-3-1": {
        "name": "Veo 3.1",
        "provider": "Google (via KIE.AI)",
        "durations": [8],
        "cost_per_video": 0.40,
        "best_for": "Cost-effective, quick generation",
        "resolution": "Up to 1080p",
        "audio": "Native audio generation"
    },
    "sora-10s": {
        "name": "Sora 2 (10s)",
        "provider": "OpenAI (via KIE.AI)",
        "durations": [10],
        "cost_per_second": 0.015,
        "cost_per_video": 0.15,
        "best_for": "Creative control, physics",
        "resolution": "Up to 1080p",
        "audio": "Separate audio needed"
    },
    "sora-15s": {
        "name": "Sora 2 (15s)",
        "provider": "OpenAI (via KIE.AI)",
        "durations": [15],
        "cost_per_second": 0.015,
        "cost_per_video": 0.23,
        "best_for": "Medium length scenes",
        "resolution": "Up to 1080p",
        "audio": "Separate audio needed"
    },
    "sora-25s": {
        "name": "Sora 2 (25s)",
        "provider": "OpenAI (via KIE.AI)",
        "durations": [25],
        "cost_per_second": 0.015,
        "cost_per_video": 0.38,
        "best_for": "Longer continuous scenes",
        "resolution": "Up to 1080p",
        "audio": "Separate audio needed"
    },
    "kling-3": {
        "name": "Kling 3.0",
        "provider": "Kuaishou (via KIE.AI)",
        "durations": [5, 10],
        "cost_per_video": "Variable",
        "best_for": "Alternative style to Veo/Sora",
        "resolution": "Up to 1080p",
        "audio": "Varies"
    },
    "seed-dance": {
        "name": "Seed Dance",
        "provider": "KIE.AI",
        "durations": [5, 8],
        "cost_per_video": "Variable",
        "best_for": "Human movement, dance, fitness",
        "resolution": "Up to 1080p",
        "audio": "Varies"
    },
    "wan-2-6": {
        "name": "Wan 2.6",
        "provider": "KIE.AI",
        "durations": [8, 10],
        "cost_per_video": "Variable",
        "best_for": "General purpose, diverse content",
        "resolution": "Up to 1080p",
        "audio": "Varies"
    }
}

def get_model(model_id):
    """Get model specifications"""
    return MODELS.get(model_id)

def list_models():
    """List all available models"""
    return list(MODELS.keys())

def calculate_cost(model_id, total_duration_seconds):
    """Calculate estimated cost for video"""
    model = MODELS.get(model_id)
    if not model:
        return None
    
    clip_duration = model["durations"][0]  # Use first/default duration
    num_clips = total_duration_seconds // clip_duration
    if total_duration_seconds % clip_duration > 0:
        num_clips += 1
    
    if "cost_per_video" in model and isinstance(model["cost_per_video"], (int, float)):
        total_cost = num_clips * model["cost_per_video"]
    elif "cost_per_second" in model:
        total_cost = num_clips * clip_duration * model["cost_per_second"]
    else:
        total_cost = "Variable"
    
    return {
        "num_clips": num_clips,
        "clip_duration": clip_duration,
        "cost_per_clip": model.get("cost_per_video", "Variable"),
        "total_cost": total_cost
    }