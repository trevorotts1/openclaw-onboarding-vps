# Social Media Platform Specs

## TikTok / Instagram Reels / YouTube Shorts
- **Resolution:** 1080 x 1920
- **Aspect Ratio:** 9:16
- **Frame Rate:** 30 fps (minimum), 60 fps (recommended)
- **Video Length:** 
  - TikTok: 15 seconds to 10 minutes
  - Reels: 15 to 90 seconds
  - Shorts: up to 60 seconds
- **Format:** MP4
- **Audio:** AAC codec

## Instagram Feed (Square)
- **Resolution:** 1080 x 1080
- **Aspect Ratio:** 1:1
- **Frame Rate:** 30 fps
- **Video Length:** 3 to 60 seconds
- **Format:** MP4

## YouTube (Standard)
- **Resolution:** 1920 x 1080 (1080p) or higher
- **Aspect Ratio:** 16:9
- **Frame Rate:** 24, 30, or 60 fps
- **Format:** MP4

## LinkedIn
- **Resolution:** 1920 x 1080 (landscape) or 1080 x 1920 (vertical)
- **Aspect Ratio:** 16:9 (landscape) or 9:16 (vertical)
- **Video Length:** 3 seconds to 30 minutes
- **File Size:** max 5GB
- **Format:** MP4

## Quick Reference Script Usage

```bash
# TikTok/Reels/Shorts
resize.sh --input video.mp4 --platform tiktok --output tiktok.mp4

# Instagram Square
resize.sh --input video.mp4 --platform instagram --output ig.mp4

# YouTube/LinkedIn
resize.sh --input video.mp4 --platform youtube --output yt.mp4
```