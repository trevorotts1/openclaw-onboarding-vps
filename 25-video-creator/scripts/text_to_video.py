#!/usr/bin/env python3
"""
Text-to-Video Generator
Converts text descriptions into video using AI providers.
"""

import argparse
import os
import sys
import json
import time
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from ai_providers import AIProvider


def load_config():
    """Load configuration from ~/.blackceo/config.json"""
    config_path = Path.home() / ".blackceo" / "config.json"
    if config_path.exists():
        with open(config_path) as f:
            return json.load(f)
    return {}


def text_to_video(prompt, duration=5, resolution="1080p", provider="kieai", 
                  style="cinematic", output=None, **kwargs):
    """
    Generate video from text description.
    
    Args:
        prompt: Text description of the video
        duration: Length in seconds
        resolution: Output resolution (720p, 1080p, 4k)
        provider: AI provider to use
        style: Visual style
        output: Output filename
        
    Returns:
        Path to generated video
    """
    config = load_config()
    
    # Set default output name
    if output is None:
        safe_prompt = "".join(c if c.isalnum() else "_" for c in prompt[:30])
        output = f"{safe_prompt}_{int(time.time())}.mp4"
    
    # Ensure output directory exists
    output_path = Path(output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Initialize AI provider
    ai = AIProvider(provider, config.get("video_providers", {}))
    
    print(f"🎬 Generating video...")
    print(f"   Prompt: {prompt}")
    print(f"   Duration: {duration}s")
    print(f"   Resolution: {resolution}")
    print(f"   Provider: {provider}")
    print(f"   Style: {style}")
    
    # Generate video via AI provider
    try:
        video_path = ai.generate_video(
            prompt=prompt,
            duration=duration,
            resolution=resolution,
            style=style,
            output=output_path,
            **kwargs
        )
        
        print(f"✓ Video saved: {video_path}")
        return str(video_path)
        
    except Exception as e:
        print(f"✗ Generation failed: {e}")
        # Fallback: Create placeholder video with MoviePy
        return create_placeholder_video(prompt, duration, resolution, output_path)


def create_placeholder_video(prompt, duration, resolution, output_path):
    """Create a placeholder video when AI generation fails."""
    try:
        from moviepy.editor import ColorClip, TextClip, CompositeVideoClip
        
        # Parse resolution
        res_map = {"720p": (1280, 720), "1080p": (1920, 1080), "4k": (3840, 2160)}
        width, height = res_map.get(resolution, (1920, 1080))
        
        # Create background
        bg = ColorClip(size=(width, height), color=(20, 20, 40)).set_duration(duration)
        
        # Add text
        text = TextClip(
            f"VIDEO PLACEHOLDER\n\n{prompt[:100]}...\n\n(AI generation unavailable)",
            fontsize=40,
            color='white',
            size=(width-100, None),
            method='caption',
            align='center'
        ).set_duration(duration).set_position('center')
        
        # Composite
        video = CompositeVideoClip([bg, text])
        video.write_videofile(str(output_path), fps=30, codec='libx264', audio=False)
        video.close()
        
        print(f"✓ Placeholder video saved: {output_path}")
        return str(output_path)
        
    except ImportError:
        print("✗ MoviePy not installed. Cannot create placeholder.")
        return None


def main():
    parser = argparse.ArgumentParser(description='Generate video from text description')
    parser.add_argument('prompt', help='Text description of the video')
    parser.add_argument('--duration', type=int, default=5, help='Video duration in seconds')
    parser.add_argument('--resolution', default='1080p', choices=['720p', '1080p', '4k'],
                       help='Output resolution')
    parser.add_argument('--provider', default='kieai', choices=['kieai', 'runway', 'pika', 'mock'],
                       help='AI provider to use')
    parser.add_argument('--style', default='cinematic', 
                       choices=['cinematic', 'animated', 'realistic', 'abstract'],
                       help='Visual style')
    parser.add_argument('--output', '-o', help='Output filename')
    parser.add_argument('--seed', type=int, help='Random seed for reproducibility')
    parser.add_argument('--negative-prompt', help='What to avoid in generation')
    
    args = parser.parse_args()
    
    result = text_to_video(
        prompt=args.prompt,
        duration=args.duration,
        resolution=args.resolution,
        provider=args.provider,
        style=args.style,
        output=args.output,
        seed=args.seed,
        negative_prompt=args.negative_prompt
    )
    
    if result:
        print(f"\n🎥 Video ready: {result}")
        return 0
    else:
        return 1


if __name__ == '__main__':
    sys.exit(main())
