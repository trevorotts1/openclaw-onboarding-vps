#!/usr/bin/env python3
"""
broll_merge.py - Merge B-roll clips with talking head video
Keeps audio continuous from main video, inserts B-roll at specified timestamps
"""

import sys
from moviepy.editor import VideoFileClip, CompositeVideoClip, concatenate_videoclips

def merge_broll(main_video, broll_clips, insert_times, output, keep_main_audio=True):
    """
    Merge B-roll clips into main video at specified timestamps.
    Audio continues from main video throughout.
    
    Args:
        main_video: Path to main talking head video
        broll_clips: List of paths to B-roll videos
        insert_times: List of timestamps (seconds) to insert B-roll
        output: Output file path
        keep_main_audio: Whether to keep main video's audio throughout
    """
    
    # Load main video
    main = VideoFileClip(main_video)
    main_audio = main.audio if keep_main_audio else None
    
    # Create segments
    segments = []
    current_time = 0
    
    # Sort insertion points
    insert_data = sorted(zip(insert_times, broll_clips))
    
    for insert_time, broll_path in insert_data:
        # Add main video segment before this insertion
        if insert_time > current_time:
            segment = main.subclip(current_time, min(insert_time, main.duration))
            segments.append(segment)
        
        # Add B-roll clip
        broll = VideoFileClip(broll_path)
        
        # Resize B-roll to match main video dimensions
        if broll.size != main.size:
            broll = broll.resize(newsize=main.size)
        
        segments.append(broll)
        
        # Update current time (skip ahead in main video by B-roll duration)
        current_time = insert_time + broll.duration
    
    # Add remaining main video
    if current_time < main.duration:
        segments.append(main.subclip(current_time, main.duration))
    
    # Concatenate all segments
    final = concatenate_videoclips(segments, method="compose")
    
    # Keep main audio throughout
    if keep_main_audio and main_audio:
        # Extend audio if final video is longer
        if final.duration > main_audio.duration:
            # Loop audio or extend with silence
            from moviepy.audio.AudioClip import AudioArrayClip
            import numpy as np
            
            # Create extended audio
            audio_duration = final.duration
            audio_array = main_audio.to_soundarray()
            
            # If audio is shorter, extend with silence
            if audio_duration > main_audio.duration:
                silence_duration = audio_duration - main_audio.duration
                silence_samples = int(silence_duration * main_audio.fps)
                silence = np.zeros((silence_samples, audio_array.shape[1]))
                extended_array = np.vstack([audio_array, silence])
                extended_audio = AudioArrayClip(extended_array, fps=main_audio.fps)
                final = final.set_audio(extended_audio)
        else:
            final = final.set_audio(main_audio)
    
    # Write output
    final.write_videofile(output, codec='libx264', audio_codec='aac')
    
    # Cleanup
    main.close()
    for seg in segments:
        seg.close()
    
    print(f"Created: {output}")

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Merge B-roll with talking head video')
    parser.add_argument('--main', required=True, help='Main talking head video')
    parser.add_argument('--broll', required=True, help='Comma-separated B-roll video paths')
    parser.add_argument('--insert-at', required=True, help='Comma-separated timestamps in seconds')
    parser.add_argument('--output', required=True, help='Output video path')
    
    args = parser.parse_args()
    
    merge_broll(
        main_video=args.main,
        broll_clips=args.broll.split(','),
        insert_times=[float(x) for x in args.insert_at.split(',')],
        output=args.output
    )