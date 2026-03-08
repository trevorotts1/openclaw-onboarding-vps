#!/usr/bin/env python3
"""
Test Video Creator Installation
Verify all components are working correctly.
"""

import sys
from pathlib import Path

def test_imports():
    """Test that required packages are installed."""
    print("Testing imports...")
    
    tests = [
        ("moviepy", "MoviePy"),
        ("cv2", "OpenCV"),
        ("PIL", "Pillow"),
        ("numpy", "NumPy"),
        ("requests", "Requests"),
    ]
    
    all_passed = True
    for module, name in tests:
        try:
            __import__(module)
            print(f"  ✓ {name} installed")
        except ImportError:
            print(f"  ✗ {name} NOT installed")
            all_passed = False
    
    return all_passed


def test_ffmpeg():
    """Test FFmpeg is available."""
    print("\nTesting FFmpeg...")
    
    import subprocess
    try:
        result = subprocess.run(
            ["ffmpeg", "-version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            version = result.stdout.split('\n')[0]
            print(f"  ✓ FFmpeg available: {version[:50]}...")
            return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    
    print("  ✗ FFmpeg NOT found in PATH")
    return False


def test_imagemagick():
    """Test ImageMagick is available."""
    print("\nTesting ImageMagick...")
    
    import subprocess
    try:
        result = subprocess.run(
            ["convert", "--version"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if result.returncode == 0:
            version = result.stdout.split('\n')[0]
            print(f"  ✓ ImageMagick available: {version[:50]}...")
            return True
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    
    print("  ⚠ ImageMagick NOT found (some features may not work)")
    return False


def test_scripts():
    """Test that script files exist."""
    print("\nTesting script files...")
    
    scripts_dir = Path(__file__).parent
    
    required_scripts = [
        "text_to_video.py",
        "script_to_video.py",
        "image_to_video.py",
        "multi_clip_assembly.py",
        "add_music.py",
        "transitions.py",
        "template_video.py",
        "avatar_video.py",
        "ai_providers.py",
    ]
    
    all_present = True
    for script in required_scripts:
        path = scripts_dir / script
        if path.exists():
            print(f"  ✓ {script}")
        else:
            print(f"  ✗ {script} missing")
            all_present = False
    
    return all_present


def test_moviepy_functionality():
    """Test basic MoviePy functionality."""
    print("\nTesting MoviePy functionality...")
    
    try:
        from moviepy.editor import ColorClip, TextClip, CompositeVideoClip
        
        # Create a simple test clip
        clip = ColorClip(size=(640, 480), color=(50, 50, 100), duration=1)
        
        # Try to write a frame
        frame = clip.get_frame(0)
        assert frame.shape == (480, 640, 3), f"Unexpected frame shape: {frame.shape}"
        
        clip.close()
        print("  ✓ MoviePy working correctly")
        return True
        
    except Exception as e:
        print(f"  ✗ MoviePy test failed: {e}")
        return False


def create_test_video():
    """Create a test video file."""
    print("\nCreating test video...")
    
    try:
        from moviepy.editor import ColorClip, TextClip, CompositeVideoClip
        
        # Background
        bg = ColorClip(size=(1280, 720), color=(40, 40, 60), duration=3)
        
        # Text
        txt = TextClip(
            "Video Creator\nInstallation Test",
            fontsize=60,
            color='white',
            align='center'
        ).set_duration(3).set_position('center')
        
        # Composite
        video = CompositeVideoClip([bg, txt])
        
        # Output path
        output_dir = Path(__file__).parent.parent / "output"
        output_dir.mkdir(exist_ok=True)
        output_path = output_dir / "test_video.mp4"
        
        # Write
        video.write_videofile(
            str(output_path),
            fps=30,
            codec='libx264',
            audio=False,
            verbose=False
        )
        
        video.close()
        
        if output_path.exists():
            print(f"  ✓ Test video created: {output_path}")
            return True
        else:
            print("  ✗ Test video not created")
            return False
            
    except Exception as e:
        print(f"  ✗ Test video failed: {e}")
        return False


def test_config():
    """Test configuration file."""
    print("\nTesting configuration...")
    
    config_path = Path.home() / ".blackceo" / "config.json"
    
    if config_path.exists():
        import json
        try:
            with open(config_path) as f:
                config = json.load(f)
            
            if "video_providers" in config:
                providers = list(config["video_providers"].keys())
                print(f"  ✓ Config loaded, providers: {', '.join(providers)}")
            else:
                print("  ⚠ Config exists but no video_providers defined")
            
            return True
            
        except json.JSONDecodeError:
            print("  ✗ Config file is invalid JSON")
            return False
    else:
        print(f"  ⚠ Config not found at {config_path}")
        print("    Run: mkdir -p ~/.blackceo && create config.json")
        return False


def main():
    """Run all tests."""
    print("="*50)
    print("Video Creator Skill - Installation Test")
    print("="*50)
    
    results = []
    
    results.append(("Imports", test_imports()))
    results.append(("FFmpeg", test_ffmpeg()))
    results.append(("ImageMagick", test_imagemagick()))
    results.append(("Scripts", test_scripts()))
    results.append(("MoviePy", test_moviepy_functionality()))
    results.append(("Test Video", create_test_video()))
    results.append(("Config", test_config()))
    
    print("\n" + "="*50)
    print("Test Summary")
    print("="*50)
    
    for name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status}: {name}")
    
    all_passed = all(r[1] for r in results)
    
    print("\n" + "="*50)
    if all_passed:
        print("✓ All tests passed! Video Creator is ready.")
        return 0
    else:
        print("✗ Some tests failed. Check output above.")
        return 1


if __name__ == '__main__':
    sys.exit(main())
