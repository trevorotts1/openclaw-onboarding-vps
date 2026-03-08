# FFmpeg vs MoviePy Decision Guide

## Use FFmpeg (scripts/cut.sh, resize.sh) when:
- Simple operations: cut, trim, resize, format conversion
- Speed matters (FFmpeg is faster for these)
- One-off operations
- You know the exact timestamps

## Use MoviePy (scripts/text-overlay.py) when:
- Adding styled text overlays
- Multiple text layers needed
- Text animation (fade in/out, movement)
- Complex compositing (multiple video layers)
- Custom positioning that's hard in FFmpeg drawtext
- Building templates with dynamic text

## Quick Examples

### FFmpeg - Resize for TikTok:
```bash
resize.sh --input video.mp4 --platform tiktok --output tiktok.mp4
```

### MoviePy - Add animated title:
```bash
python3 scripts/text-overlay.py --input video.mp4 --text "NEW TRAINING" --position top --start 0 --duration 3 --output titled.mp4
```

## Performance Note
FFmpeg is generally 5-10x faster for simple operations because it doesn't decode/re-encode the entire video pipeline the same way MoviePy does. Use FFmpeg for cuts/resizes, MoviePy only when you need its text/compositing features.