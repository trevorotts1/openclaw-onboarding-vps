#!/usr/bin/env python3
"""
text-overlay.py - Add styled text overlays using MoviePy
Use when: You need animated text, multiple text layers, or custom styling

Usage:
  python3 text-overlay.py --input video.mp4 --text "My Title" --position center --output output.mp4
  python3 text-overlay.py --input video.mp4 --text "Subscribe!" --position bottom --color yellow --start 5 --duration 3 --output output.mp4

Why MoviePy for this?
  - Easier text styling and positioning than FFmpeg drawtext
  - Can animate text (fade in/out, move)
  - Multiple text layers are simpler
  - Better font handling
"""

import argparse
import sys
from moviepy.editor import VideoFileClip, TextClip, CompositeVideoClip

def main():
    parser = argparse.ArgumentParser(description='Add text overlay to video')
    parser.add_argument('--input', required=True, help='Input video file')
    parser.add_argument('--text', required=True, help='Text to overlay')
    parser.add_argument('--output', required=True, help='Output video file')
    parser.add_argument('--position', default='center', choices=['center', 'top', 'bottom', 'topleft', 'topright'], help='Text position')
    parser.add_argument('--color', default='white', help='Text color')
    parser.add_argument('--fontsize', type=int, default=70, help='Font size')
    parser.add_argument('--start', type=float, default=0, help='Start time in seconds')
    parser.add_argument('--duration', type=float, help='Duration in seconds (default: rest of video)')
    
    args = parser.parse_args()
    
    # Load video
    video = VideoFileClip(args.input)
    
    # Calculate duration
    duration = args.duration if args.duration else (video.duration - args.start)
    
    # Create text clip
    txt_clip = TextClip(
        args.text, 
        fontsize=args.fontsize, 
        color=args.color,
        font='Arial-Bold',
        stroke_color='black',
        stroke_width=2
    ).set_duration(duration).set_start(args.start)
    
    # Set position
    position_map = {
        'center': 'center',
        'top': ('center', 50),
        'bottom': ('center', video.h - 150),
        'topleft': (50, 50),
        'topright': (video.w - 50, 50)
    }
    txt_clip = txt_clip.set_position(position_map.get(args.position, 'center'))
    
    # Composite
    final = CompositeVideoClip([video, txt_clip])
    
    # Write output
    final.write_videofile(args.output, codec='libx264', audio_codec='aac')
    
    print(f"Created: {args.output}")

if __name__ == '__main__':
    main()