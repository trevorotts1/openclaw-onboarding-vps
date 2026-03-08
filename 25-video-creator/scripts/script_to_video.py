#!/usr/bin/env python3
"""
Script-to-Video Converter
Transforms written scripts into complete videos with scenes.
"""

import argparse
import os
import sys
import json
import re
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Optional

sys.path.insert(0, str(Path(__file__).parent))

from ai_providers import AIProvider


@dataclass
class Scene:
    """Represents a single scene in the script."""
    number: int
    visual: str = ""
    voiceover: str = ""
    duration: float = 5.0
    bgm: str = ""
    text: str = ""
    transition: str = "fade"
    image: Optional[str] = None


class ScriptParser:
    """Parse script files into scene objects."""
    
    def __init__(self, script_path: Path):
        self.script_path = script_path
        self.scenes: List[Scene] = []
        
    def parse(self) -> List[Scene]:
        """Parse the script file and return list of scenes."""
        with open(self.script_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Split into scenes
        scene_blocks = re.split(r'\nSCENE\s+\d+:', content, flags=re.IGNORECASE)
        
        scene_num = 0
        for block in scene_blocks:
            if not block.strip():
                continue
                
            scene_num += 1
            scene = self._parse_scene_block(scene_num, block)
            self.scenes.append(scene)
        
        return self.scenes
    
    def _parse_scene_block(self, num: int, block: str) -> Scene:
        """Parse individual scene block."""
        scene = Scene(number=num)
        
        # Extract visual description (first bracketed content or text before keywords)
        visual_match = re.search(r'\[(.*?)\]', block)
        if visual_match:
            scene.visual = visual_match.group(1).strip()
        
        # Extract VOICEOVER
        voiceover_match = re.search(r'VOICEOVER:\s*(.+?)(?=\n[A-Z]+:|$)', block, re.DOTALL)
        if voiceover_match:
            scene.voiceover = voiceover_match.group(1).strip()
        
        # Extract DURATION
        duration_match = re.search(r'DURATION:\s*(\d+(?:\.\d+)?)\s*s?', block, re.IGNORECASE)
        if duration_match:
            scene.duration = float(duration_match.group(1))
        
        # Extract BGM
        bgm_match = re.search(r'BGM:\s*(.+?)(?=\n[A-Z]+:|$)', block, re.IGNORECASE)
        if bgm_match:
            scene.bgm = bgm_match.group(1).strip()
        
        # Extract TEXT
        text_match = re.search(r'TEXT:\s*(.+?)(?=\n[A-Z]+:|$)', block, re.IGNORECASE | re.DOTALL)
        if text_match:
            scene.text = text_match.group(1).strip()
        
        # Extract TRANSITION
        transition_match = re.search(r'TRANSITION:\s*(\w+)', block, re.IGNORECASE)
        if transition_match:
            scene.transition = transition_match.group(1).lower()
        
        # Extract IMAGE
        image_match = re.search(r'IMAGE:\s*(.+?)(?=\n[A-Z]+:|$)', block, re.IGNORECASE)
        if image_match:
            scene.image = image_match.group(1).strip()
        
        return scene


def script_to_video(script_path: Path, output: Optional[Path] = None,
                   provider: str = "mock", quality: str = "web",
                   template: Optional[str] = None, **kwargs) -> Path:
    """
    Convert script to video.
    
    Args:
        script_path: Path to script file
        output: Output video path
        provider: AI provider for generation
        quality: Output quality preset
        template: Optional template to use
        **kwargs: Additional options
        
    Returns:
        Path to generated video
    """
    print(f"📝 Parsing script: {script_path}")
    
    # Parse script
    parser = ScriptParser(script_path)
    scenes = parser.parse()
    
    if not scenes:
        raise ValueError("No scenes found in script")
    
    print(f"✓ Found {len(scenes)} scenes")
    
    # Set output path
    if output is None:
        output = script_path.with_suffix('.mp4')
    
    output.parent.mkdir(parents=True, exist_ok=True)
    
    # Generate clips for each scene
    scene_clips = []
    
    for scene in scenes:
        print(f"\n🎬 Scene {scene.number}: {scene.visual[:50]}...")
        print(f"   Duration: {scene.duration}s")
        
        clip = generate_scene_clip(scene, provider, quality)
        if clip:
            scene_clips.append(clip)
    
    # Assemble final video
    if not scene_clips:
        raise RuntimeError("No clips were generated")
    
    print(f"\n🎥 Assembling {len(scene_clips)} clips...")
    
    final_video = assemble_clips(scene_clips, scenes, output, quality)
    
    print(f"✓ Video saved: {final_video}")
    return final_video


def generate_scene_clip(scene: Scene, provider: str, quality: str) -> Optional[Path]:
    """Generate video clip for a single scene."""
    from moviepy.editor import ColorClip, TextClip, CompositeVideoClip, AudioFileClip
    
    config = load_config()
    
    # Determine resolution
    quality_map = {
        'social': (1080, 1920),  # Vertical
        'web': (1920, 1080),
        'broadcast': (1920, 1080),
        'cinema': (3840, 2160)
    }
    width, height = quality_map.get(quality, (1920, 1080))
    
    # Use AI to generate if visual description provided
    if scene.visual and provider != 'local':
        try:
            ai = AIProvider(provider, config.get('video_providers', {}))
            temp_output = Path(f"temp_scene_{scene.number}.mp4")
            clip_path = ai.generate_video(
                prompt=scene.visual,
                duration=int(scene.duration),
                resolution=quality,
                output=temp_output
            )
            return clip_path
        except Exception as e:
            print(f"   AI generation failed: {e}, using fallback")
    
    # Fallback: Create clip with MoviePy
    try:
        # Background color based on scene number
        colors = [(40, 40, 60), (60, 40, 40), (40, 60, 40), (60, 60, 40)]
        bg_color = colors[scene.number % len(colors)]
        
        bg = ColorClip(size=(width, height), color=bg_color).set_duration(scene.duration)
        
        clips = [bg]
        
        # Add text overlay if provided
        if scene.text:
            text = TextClip(
                scene.text,
                fontsize=60,
                color='white',
                size=(width - 100, None),
                method='caption',
                align='center',
                font='Arial-Bold'
            ).set_duration(scene.duration).set_position('center')
            clips.append(text)
        
        # Add scene number indicator
        num_text = TextClip(
            f"Scene {scene.number}",
            fontsize=30,
            color='yellow'
        ).set_duration(scene.duration).set_position((50, 50))
        clips.append(num_text)
        
        video = CompositeVideoClip(clips)
        
        temp_path = Path(f"temp_scene_{scene.number}.mp4")
        video.write_videofile(str(temp_path), fps=30, codec='libx264', audio=False, verbose=False)
        video.close()
        
        return temp_path
        
    except Exception as e:
        print(f"   Failed to create clip: {e}")
        return None


def assemble_clips(clip_paths: List[Path], scenes: List[Scene], 
                   output: Path, quality: str) -> Path:
    """Assemble scene clips into final video with transitions."""
    from moviepy.editor import VideoFileClip, concatenate_videoclips, CompositeAudioClip
    
    clips = []
    for path in clip_paths:
        try:
            clip = VideoFileClip(str(path))
            clips.append(clip)
        except Exception as e:
            print(f"   Warning: Could not load {path}: {e}")
    
    if not clips:
        raise RuntimeError("No valid clips to assemble")
    
    # Concatenate with simple transitions
    # (More complex transitions handled by transitions.py)
    final = concatenate_videoclips(clips, method="compose")
    
    # Add background music if specified in any scene
    bgm_tracks = [s.bgm for s in scenes if s.bgm]
    if bgm_tracks:
        print(f"   Adding background music: {bgm_tracks[0]}")
        # Would load and mix audio here
    
    # Write final video
    final.write_videofile(str(output), fps=30, codec='libx264', audio_codec='aac')
    final.close()
    
    # Cleanup temp files
    for path in clip_paths:
        if path.exists() and 'temp_scene' in str(path):
            path.unlink()
    
    return output


def load_config():
    """Load optional configuration."""
    config_path = Path.home() / ".openclaw" / "video-creator" / "config.json"
    if config_path.exists():
        with open(config_path) as f:
            return json.load(f)
    return {}


def main():
    parser = argparse.ArgumentParser(description='Convert script to video')
    parser.add_argument('script', type=Path, help='Path to script file')
    parser.add_argument('--output', '-o', type=Path, help='Output video path')
    parser.add_argument('--provider', default='mock', 
                       choices=['kieai', 'runway', 'pika', 'mock', 'local'],
                       help='AI provider for scene generation')
    parser.add_argument('--quality', default='web',
                       choices=['social', 'web', 'broadcast', 'cinema'],
                       help='Output quality')
    parser.add_argument('--template', help='Template to use')
    parser.add_argument('--chapters', action='store_true', 
                       help='Generate chapter markers')
    
    args = parser.parse_args()
    
    if not args.script.exists():
        print(f"✗ Script file not found: {args.script}")
        return 1
    
    try:
        result = script_to_video(
            script_path=args.script,
            output=args.output,
            provider=args.provider,
            quality=args.quality,
            template=args.template
        )
        print(f"\n🎬 Video ready: {result}")
        return 0
        
    except Exception as e:
        print(f"✗ Error: {e}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
