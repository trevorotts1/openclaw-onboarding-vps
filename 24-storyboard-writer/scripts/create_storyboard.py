#!/usr/bin/env python3
"""
create_storyboard.py - Generate video storyboards matching AI model capabilities
"""

import argparse
import json
from datetime import timedelta
from model_database import get_model, calculate_cost

def format_time(seconds):
    """Format seconds as HH:MM:SS"""
    return str(timedelta(seconds=int(seconds)))

def generate_segment_prompt(topic, segment_num, total_segments, style="neutral"):
    """Generate a prompt for a video segment"""
    
    prompts = {
        "intro": [
            f"Opening shot establishing {topic}, professional lighting",
            f"Wide shot introducing {topic} theme, cinematic",
            f"Dynamic intro to {topic}, eye-catching visuals"
        ],
        "middle": [
            f"Medium shot showing {topic} details, engaging",
            f"Close-up of key {topic} elements, clear focus",
            f"Action shot demonstrating {topic}, dynamic movement"
        ],
        "outro": [
            f"Closing shot summarizing {topic}, memorable",
            f"Final image reinforcing {topic} message",
            f"Call-to-action visual for {topic}, compelling"
        ]
    }
    
    if segment_num == 0:
        return prompts["intro"][0]
    elif segment_num == total_segments - 1:
        return prompts["outro"][0]
    else:
        return prompts["middle"][segment_num % len(prompts["middle"])]

def create_storyboard(duration, model_id, topic, style="neutral"):
    """Create a complete storyboard"""
    
    model = get_model(model_id)
    if not model:
        print(f"Error: Unknown model '{model_id}'")
        print(f"Available: {', '.join(list_models())}")
        return None
    
    # Calculate segments
    clip_duration = model["durations"][0]
    num_clips = duration // clip_duration
    if duration % clip_duration > 0:
        num_clips += 1
    
    cost_info = calculate_cost(model_id, duration)
    
    # Generate segments
    segments = []
    current_time = 0
    
    for i in range(num_clips):
        segment = {
            "segment_number": i + 1,
            "start_time": format_time(current_time),
            "end_time": format_time(min(current_time + clip_duration, duration)),
            "duration": min(clip_duration, duration - current_time),
            "prompt": generate_segment_prompt(topic, i, num_clips, style),
            "notes": ""
        }
        segments.append(segment)
        current_time += clip_duration
    
    storyboard = {
        "project": {
            "topic": topic,
            "total_duration": format_time(duration),
            "style": style
        },
        "model": {
            "id": model_id,
            "name": model["name"],
            "provider": model["provider"],
            "clip_duration": clip_duration,
            "resolution": model["resolution"]
        },
        "calculations": {
            "num_segments": num_clips,
            "cost_per_segment": cost_info["cost_per_clip"],
            "estimated_total_cost": cost_info["total_cost"]
        },
        "segments": segments
    }
    
    return storyboard

def export_to_json(storyboard, filename):
    """Export storyboard to JSON"""
    with open(filename, 'w') as f:
        json.dump(storyboard, f, indent=2)
    print(f"Exported to JSON: {filename}")

def export_to_markdown(storyboard, filename):
    """Export storyboard to Markdown"""
    with open(filename, 'w') as f:
        f.write(f"# {storyboard['project']['topic']} - Storyboard\n\n")
        f.write(f"**Model:** {storyboard['model']['name']}\n\n")
        f.write(f"**Total Duration:** {storyboard['project']['total_duration']}\n\n")
        f.write(f"**Segments:** {storyboard['calculations']['num_segments']}\n\n")
        f.write(f"**Estimated Cost:** ${storyboard['calculations']['estimated_total_cost']}\n\n")
        f.write("---\n\n")
        
        for seg in storyboard['segments']:
            f.write(f"## Segment {seg['segment_number']}\n\n")
            f.write(f"**Time:** {seg['start_time']} - {seg['end_time']}\n\n")
            f.write(f"**Duration:** {seg['duration']}s\n\n")
            f.write(f"**Prompt:** {seg['prompt']}\n\n")
            if seg['notes']:
                f.write(f"**Notes:** {seg['notes']}\n\n")
            f.write("---\n\n")
    
    print(f"Exported to Markdown: {filename}")

def main():
    parser = argparse.ArgumentParser(description='Create video storyboard')
    parser.add_argument('--duration', type=int, required=True, help='Total video duration in seconds')
    parser.add_argument('--model', type=str, required=True, help='AI model ID (veo-3-1, sora-10s, etc.)')
    parser.add_argument('--topic', type=str, required=True, help='Video topic/theme')
    parser.add_argument('--style', type=str, default='neutral', help='Visual style')
    parser.add_argument('--output', type=str, default='storyboard', help='Output filename prefix')
    
    args = parser.parse_args()
    
    print(f"Creating storyboard for {args.duration}s {args.topic} video using {args.model}...")
    
    storyboard = create_storyboard(args.duration, args.model, args.topic, args.style)
    
    if storyboard:
        export_to_json(storyboard, f"{args.output}.json")
        export_to_markdown(storyboard, f"{args.output}.md")
        
        print("\n✅ Storyboard created!")
        print(f"Segments: {storyboard['calculations']['num_segments']}")
        print(f"Estimated cost: ${storyboard['calculations']['estimated_total_cost']}")

if __name__ == '__main__':
    from model_database import list_models
    main()