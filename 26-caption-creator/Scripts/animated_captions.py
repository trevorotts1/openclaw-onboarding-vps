#!/usr/bin/env python3
"""
animated_captions.py - Create animated karaoke-style captions

This script uses FFmpeg's drawtext filter.
Important: drawtext treats ':' as an option separator, so caption text must be escaped.
"""

import argparse
import subprocess
import re


def parse_srt(srt_file):
    """Parse SRT file and return list of (start, end, text) tuples"""
    with open(srt_file, "r", encoding="utf-8") as f:
        content = f.read()

    pattern = r"(\d+)\s+([0-9:,]+) --> ([0-9:,]+)\s+(.+?)(?=\n\d+\s+\n|\Z)"
    matches = re.findall(pattern, content, re.DOTALL)

    captions = []
    for match in matches:
        _, start, end, text = match
        text = text.replace("\n", " ").strip()
        captions.append((start, end, text))

    return captions


def time_to_seconds(time_str):
    """Convert SRT time to seconds"""
    parts = time_str.split(":")
    hours = int(parts[0])
    minutes = int(parts[1])
    seconds = float(parts[2].replace(",", "."))
    return hours * 3600 + minutes * 60 + seconds


def escape_drawtext_text(text):
    """
    Escape caption text for FFmpeg drawtext.

    We wrap text in single quotes: text='...'
    - Escape backslashes first
    - Escape ':' because drawtext uses ':' as an option separator
    - Escape single quotes
    """
    text = text.replace("\\", r"\\")
    text = text.replace(":", r"\:")
    text = text.replace("'", r"\'")
    return text


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--srt", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    captions = parse_srt(args.srt)

    # Create FFmpeg filter complex for animated captions
    filter_parts = []

    for start, end, text in captions:
        start_sec = time_to_seconds(start)
        end_sec = time_to_seconds(end)

        safe_text = escape_drawtext_text(text)

        # Create animated subtitle effect
        filter_parts.append(
            f"drawtext=text='{safe_text}':fontcolor=white:fontsize=24:"
            f"x=(w-text_w)/2:y=h-text_h-50:"
            f"enable='between(t,{start_sec},{end_sec})':"
            f"borderw=2:bordercolor=black"
        )

    # Join filters
    filter_complex = ",".join(filter_parts)

    cmd = [
        "ffmpeg",
        "-i",
        args.input,
        "-vf",
        filter_complex,
        "-c:a",
        "copy",
        args.output,
    ]

    subprocess.run(cmd, check=True)
    print(f"Created: {args.output}")


if __name__ == "__main__":
    main()
