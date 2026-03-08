#!/usr/bin/env python3
"""
Multi-Clip Assembly
Combine multiple video clips with transitions and effects.
"""

import argparse
import os
import sys
from pathlib import Path
from typing import List, Optional, Tuple

sys.path.insert(0, str(Path(__file__).parent))


def get_resolution(preset: str) -> Tuple[int, int]:
    """Get dimensions from quality preset."""
    presets = {
        '720p': (1280, 720),
        '1080p': (1920, 1080),
        '4k': (3840, 2160),
        'vertical': (1080, 1920),
        'square': (1080, 1080),
        'social': (1080, 1920),
    }
    return presets.get(preset, (1920, 1080))


def apply_transition(clip1, clip2, transition_type: str, duration: float = 0.5):
    """
    Apply transition between two clips.
    
    Args:
        clip1: First video clip
        clip2: Second video clip
        transition_type: Type of transition
        duration: Transition duration in seconds
        
    Returns:
        List of clips with transition applied
    """
    from moviepy.editor import CompositeVideoClip, concatenate_videoclips
    from moviepy.video.fx.all import fadein, fadeout
    
    if transition_type == 'none' or duration <= 0:
        return [clip1, clip2]
    
    if transition_type == 'fade':
        # Crossfade
        clip1 = clip1.fadeout(duration)
        clip2 = clip2.fadein(duration)
        return [clip1, clip2]
    
    elif transition_type == 'slide_left':
        # Slide transition
        from moviepy.video.fx.all import slide_in
        clip2 = slide_in(clip2, duration=duration, side='left')
        return [clip1.set_end(clip1.duration - duration), clip2]
    
    elif transition_type == 'slide_right':
        from moviepy.video.fx.all import slide_in
        clip2 = slide_in(clip2, duration=duration, side='right')
        return [clip1.set_end(clip1.duration - duration), clip2]
    
    elif transition_type == 'wipe':
        # Wipe effect using mask
        import numpy as np
        
        def wipe_mask(t):
            """Generate wipe mask."""
            progress = t / duration
            mask = np.zeros((clip1.h, clip1.w))
            cutoff = int(clip1.w * progress)
            mask[:, :cutoff] = 1
            return mask
        
        # Create transition clip
        overlap = CompositeVideoClip([
            clip1.subclip(clip1.duration - duration, clip1.duration),
            clip2.subclip(0, duration).set_mask(wipe_mask)
        ], size=clip1.size)
        
        return [
            clip1.subclip(0, clip1.duration - duration),
            overlap,
            clip2.subclip(duration)
        ]
    
    elif transition_type in ('zoom_in', 'zoom_out'):
        # Zoom transition
        from moviepy.video.fx.all import resize
        
        if transition_type == 'zoom_in':
            clip1_out = clip1.subclip(clip1.duration - duration, clip1.duration)
            clip1_out = clip1_out.fx(resize, lambda t: 1 + 0.5 * t / duration)
        else:
            clip2_in = clip2.subclip(0, duration)
            clip2_in = clip2_in.fx(resize, lambda t: 1.5 - 0.5 * t / duration)
            return [clip1, clip2_in, clip2.subclip(duration)]
        
        return [clip1.subclip(0, clip1.duration - duration), clip1_out, clip2]
    
    # Default: simple fade
    return [clip1.fadeout(0.5), clip2.fadein(0.5)]


def assemble_clips(clip_paths: List[Path], transition: str = 'fade',
                  transition_duration: float = 0.5, target_duration: Optional[float] = None,
                  music: Optional[str] = None, output: Optional[Path] = None,
                  resolution: str = '1080p', fps: int = 30) -> Path:
    """
    Assemble multiple clips into single video.
    
    Args:
        clip_paths: List of video file paths
        transition: Transition type between clips
        transition_duration: Length of transition in seconds
        target_duration: Max duration per clip (None = full clip)
        music: Background music file or genre
        output: Output file path
        resolution: Output resolution preset
        fps: Frames per second
        
    Returns:
        Path to output video
    """
    from moviepy.editor import VideoFileClip, concatenate_videoclips, AudioFileClip, CompositeAudioClip
    from moviepy.audio.fx.all import audio_fadein, audio_fadeout
    
    if not clip_paths:
        raise ValueError("No input clips provided")
    
    print(f"🎬 Assembling {len(clip_paths)} clips...")
    print(f"   Transition: {transition}")
    print(f"   Resolution: {resolution}")
    
    # Load and prepare clips
    target_width, target_height = get_resolution(resolution)
    clips = []
    
    for i, path in enumerate(clip_paths):
        if not path.exists():
            print(f"   ⚠️  Skipping missing file: {path}")
            continue
            
        print(f"   Loading: {path.name}")
        
        try:
            clip = VideoFileClip(str(path))
            
            # Trim if target duration specified
            if target_duration and clip.duration > target_duration:
                clip = clip.subclip(0, target_duration)
            
            # Resize to target resolution (maintaining aspect ratio)
            if clip.w != target_width or clip.h != target_height:
                clip = clip.resize(newsize=(target_width, target_height))
            
            clips.append(clip)
            
        except Exception as e:
            print(f"   ✗ Error loading {path}: {e}")
            continue
    
    if not clips:
        raise RuntimeError("No valid clips to assemble")
    
    # Apply transitions
    if len(clips) > 1 and transition != 'none':
        print(f"   Applying {transition} transitions...")
        
        final_clips = [clips[0]]
        
        for i in range(1, len(clips)):
            transitioned = apply_transition(
                final_clips[-1], 
                clips[i], 
                transition, 
                transition_duration
            )
            final_clips = final_clips[:-1] + transitioned
        
        clips = final_clips
    
    # Concatenate all clips
    print("   Concatenating clips...")
    final_video = concatenate_videoclips(clips, method="compose")
    
    # Add background music
    if music:
        final_video = add_background_music(final_video, music)
    
    # Set output path
    if output is None:
        output = Path("assembled_video.mp4")
    
    output.parent.mkdir(parents=True, exist_ok=True)
    
    # Export
    print(f"   Exporting to {output}...")
    final_video.write_videofile(
        str(output),
        fps=fps,
        codec='libx264',
        audio_codec='aac',
        threads=4,
        preset='medium'
    )
    
    # Cleanup
    final_video.close()
    for clip in clips:
        clip.close()
    
    print(f"✓ Video saved: {output}")
    return output


def add_background_music(video, music_source: str, volume: float = 0.3):
    """
    Add background music to video.
    
    Args:
        video: Video clip
        music_source: File path or genre name
        volume: Music volume (0-1)
        
    Returns:
        Video with music added
    """
    from moviepy.editor import AudioFileClip, CompositeAudioClip
    from moviepy.audio.fx.all import audio_fadein, audio_fadeout, volumex
    
    # Check if music_source is a file or genre
    music_path = Path(music_source)
    
    if music_path.exists():
        # Use provided file
        music = AudioFileClip(str(music_path))
    else:
        # Use built-in genre
        music = get_music_by_genre(music_source, video.duration)
    
    if music is None:
        print(f"   ⚠️  Could not load music: {music_source}")
        return video
    
    # Loop or trim music to match video
    if music.duration < video.duration:
        # Loop music
        loops = int(video.duration / music.duration) + 1
        music = concatenate_audioclips([music] * loops)
    
    music = music.subclip(0, video.duration)
    
    # Adjust volume
    music = music.fx(volumex, volume)
    
    # Fade in/out
    music = music.fx(audio_fadein, 1.0).fx(audio_fadeout, 1.0)
    
    # Mix with existing audio or use as only audio
    if video.audio is not None:
        final_audio = CompositeAudioClip([video.audio, music])
    else:
        final_audio = music
    
    return video.set_audio(final_audio)


def get_music_by_genre(genre: str, duration: float):
    """Get background music by genre (placeholder for library)."""
    # This would load from a music library
    # For now, return None - user should provide file path
    print(f"   Note: Genre '{genre}' not implemented, provide file path instead")
    return None


def concatenate_audioclips(clips):
    """Concatenate audio clips."""
    from moviepy.editor import concatenate_audioclips as concat
    return concat(clips)


def main():
    parser = argparse.ArgumentParser(description='Assemble multiple video clips')
    parser.add_argument('clips', nargs='+', type=Path, help='Input video files')
    parser.add_argument('--transition', '-t', default='fade',
                       choices=['fade', 'slide_left', 'slide_right', 'slide_up', 'slide_down',
                               'wipe', 'zoom_in', 'zoom_out', 'none'],
                       help='Transition type between clips')
    parser.add_argument('--transition-duration', type=float, default=0.5,
                       help='Transition duration in seconds')
    parser.add_argument('--duration', type=float,
                       help='Max duration per clip (seconds)')
    parser.add_argument('--music', '-m', help='Background music file or genre')
    parser.add_argument('--output', '-o', type=Path, default='assembled.mp4',
                       help='Output filename')
    parser.add_argument('--resolution', '-r', default='1080p',
                       choices=['720p', '1080p', '4k', 'vertical', 'square', 'social'],
                       help='Output resolution')
    parser.add_argument('--fps', type=int, default=30, help='Frames per second')
    
    args = parser.parse_args()
    
    try:
        result = assemble_clips(
            clip_paths=args.clips,
            transition=args.transition,
            transition_duration=args.transition_duration,
            target_duration=args.duration,
            music=args.music,
            output=args.output,
            resolution=args.resolution,
            fps=args.fps
        )
        print(f"\n🎥 Video ready: {result}")
        return 0
        
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
