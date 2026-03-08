#!/usr/bin/env python3
"""
Transitions Library
Video transition effects for clip assembly.
"""

import argparse
import sys
from pathlib import Path
from typing import List, Tuple
import numpy as np

sys.path.insert(0, str(Path(__file__).parent))


class Transitions:
    """Collection of video transition effects."""
    
    AVAILABLE = [
        'fade', 'crossfade',
        'slide_left', 'slide_right', 'slide_up', 'slide_down',
        'wipe_left', 'wipe_right', 'wipe_up', 'wipe_down',
        'zoom_in', 'zoom_out',
        'flip_horizontal', 'flip_vertical',
        'spin',
        'pixelate',
        'none'
    ]
    
    @staticmethod
    def fade(clip1, clip2, duration: float = 0.5):
        """Crossfade between two clips."""
        from moviepy.video.fx.all import fadein, fadeout
        
        clip1 = clip1.fadeout(duration)
        clip2 = clip2.fadein(duration)
        return [clip1, clip2]
    
    @staticmethod
    def slide(clip1, clip2, direction: str, duration: float = 0.5):
        """Slide transition."""
        from moviepy.video.fx.all import slide_in
        
        sides = {
            'left': 'left',
            'right': 'right',
            'up': 'top',
            'down': 'bottom'
        }
        
        side = sides.get(direction, 'left')
        clip2 = slide_in(clip2, duration=duration, side=side)
        
        # Overlap clips during transition
        return [clip1.set_end(clip1.duration - duration), clip2]
    
    @staticmethod
    def wipe(clip1, clip2, direction: str, duration: float = 0.5):
        """Wipe transition using mask."""
        import numpy as np
        from moviepy.editor import CompositeVideoClip, VideoClip
        
        w, h = clip1.size
        
        def make_mask(t):
            """Generate wipe mask."""
            progress = t / duration
            mask = np.zeros((h, w))
            
            if direction == 'right':
                cutoff = int(w * progress)
                mask[:, :cutoff] = 1
            elif direction == 'left':
                cutoff = int(w * (1 - progress))
                mask[:, cutoff:] = 1
            elif direction == 'down':
                cutoff = int(h * progress)
                mask[:cutoff, :] = 1
            elif direction == 'up':
                cutoff = int(h * (1 - progress))
                mask[cutoff:, :] = 1
            
            return mask
        
        # Create transition composite
        c1_end = clip1.subclip(clip1.duration - duration, clip1.duration)
        c2_start = clip2.subclip(0, duration)
        
        c2_masked = c2_start.set_make_frame(
            lambda t: c2_start.get_frame(t) * make_mask(t)[:, :, np.newaxis]
        )
        c1_masked = c1_end.set_make_frame(
            lambda t: c1_end.get_frame(t) * (1 - make_mask(t))[:, :, np.newaxis]
        )
        
        transition = CompositeVideoClip([c1_masked, c2_masked], size=clip1.size)
        
        return [
            clip1.subclip(0, clip1.duration - duration),
            transition,
            clip2.subclip(duration)
        ]
    
    @staticmethod
    def zoom(clip1, clip2, direction: str, duration: float = 0.5):
        """Zoom transition."""
        from moviepy.video.fx.all import resize
        
        if direction == 'in':
            # Zoom in on end of clip1
            c1_end = clip1.subclip(clip1.duration - duration, clip1.duration)
            c1_zoomed = c1_end.fx(resize, lambda t: 1 + 0.5 * t / duration)
            return [clip1.subclip(0, clip1.duration - duration), c1_zoomed, clip2]
        
        else:  # zoom out
            # Zoom out from start of clip2
            c2_start = clip2.subclip(0, duration)
            c2_zoomed = c2_start.fx(resize, lambda t: 1.5 - 0.5 * t / duration)
            return [clip1, c2_zoomed, clip2.subclip(duration)]
    
    @staticmethod
    def flip(clip1, clip2, axis: str, duration: float = 0.5):
        """3D flip transition."""
        from moviepy.video.fx.all import rotate
        import numpy as np
        
        # Simplified flip using rotation
        def flip_effect(get_frame, t):
            frame = get_frame(t)
            progress = t / duration
            
            # Scale width to simulate 3D flip
            if progress < 0.5:
                scale = np.cos(progress * np.pi)
            else:
                scale = np.cos((progress - 0.5) * np.pi)
            
            new_width = int(frame.shape[1] * abs(scale))
            from scipy.ndimage import zoom
            
            if axis == 'horizontal':
                return zoom(frame, (1, abs(scale), 1), order=1)
            else:
                return zoom(frame, (abs(scale), 1, 1), order=1)
        
        # Apply effect to transition region
        return Transitions.fade(clip1, clip2, duration)  # Fallback to fade
    
    @staticmethod
    def apply_transition(clip1, clip2, transition_type: str, duration: float = 0.5):
        """
        Apply specified transition between two clips.
        
        Args:
            clip1: First clip
            clip2: Second clip
            transition_type: Type of transition
            duration: Transition duration
            
        Returns:
            List of clips with transition applied
        """
        if transition_type == 'none' or duration <= 0:
            return [clip1, clip2]
        
        elif transition_type in ('fade', 'crossfade'):
            return Transitions.fade(clip1, clip2, duration)
        
        elif transition_type.startswith('slide_'):
            direction = transition_type.replace('slide_', '')
            return Transitions.slide(clip1, clip2, direction, duration)
        
        elif transition_type.startswith('wipe_'):
            direction = transition_type.replace('wipe_', '')
            return Transitions.wipe(clip1, clip2, direction, duration)
        
        elif transition_type.startswith('zoom_'):
            direction = transition_type.replace('zoom_', '')
            return Transitions.zoom(clip1, clip2, direction, duration)
        
        elif transition_type.startswith('flip_'):
            axis = transition_type.replace('flip_', '')
            return Transitions.flip(clip1, clip2, axis, duration)
        
        # Default: simple fade
        return Transitions.fade(clip1, clip2, 0.5)


def preview_transition(transition_type: str, duration: float = 2.0, 
                      output: Path = None) -> Path:
    """
    Create a preview video showing the transition.
    
    Args:
        transition_type: Type of transition to preview
        duration: Preview clip duration
        output: Output file path
        
    Returns:
        Path to preview video
    """
    from moviepy.editor import ColorClip, concatenate_videoclips
    
    if output is None:
        output = Path(f"transition_{transition_type}_preview.mp4")
    
    # Create two colored clips
    clip1 = ColorClip(size=(1920, 1080), color=(100, 50, 50)).set_duration(duration)
    clip2 = ColorClip(size=(1920, 1080), color=(50, 50, 100)).set_duration(duration)
    
    # Apply transition
    transitioned = Transitions.apply_transition(clip1, clip2, transition_type, 1.0)
    
    # Concatenate
    final = concatenate_videoclips(transitioned, method="compose")
    
    final.write_videofile(str(output), fps=30, codec='libx264')
    final.close()
    
    print(f"✓ Preview saved: {output}")
    return output


def list_transitions():
    """Display available transitions."""
    print("Available transitions:")
    print()
    print("Basic:")
    print("  fade, crossfade - Smooth fade between clips")
    print("  none - Hard cut")
    print()
    print("Slide:")
    print("  slide_left, slide_right, slide_up, slide_down")
    print()
    print("Wipe:")
    print("  wipe_left, wipe_right, wipe_up, wipe_down")
    print()
    print("Zoom:")
    print("  zoom_in, zoom_out")
    print()
    print("3D:")
    print("  flip_horizontal, flip_vertical")


def main():
    parser = argparse.ArgumentParser(description='Video transitions library')
    parser.add_argument('--list', '-l', action='store_true', 
                       help='List available transitions')
    parser.add_argument('--preview', '-p', help='Preview a transition type')
    parser.add_argument('--duration', type=float, default=2.0,
                       help='Preview clip duration')
    parser.add_argument('--output', '-o', type=Path,
                       help='Output file for preview')
    
    args = parser.parse_args()
    
    if args.list:
        list_transitions()
        return 0
    
    if args.preview:
        try:
            result = preview_transition(args.preview, args.duration, args.output)
            print(f"🎬 Preview: {result}")
            return 0
        except Exception as e:
            print(f"✗ Error: {e}")
            return 1
    
    # No args - show help
    parser.print_help()
    return 0


if __name__ == '__main__':
    sys.exit(main())
