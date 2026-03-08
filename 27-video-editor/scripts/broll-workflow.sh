#!/bin/bash
# broll-workflow.sh - Complete workflow: Analyze video, generate B-roll with KIE.AI, merge together
# Usage: broll-workflow.sh --input talking-head.mp4 --output final.mp4

set -e

INPUT=""
OUTPUT="final.mp4"
NUM_BROLL=3
AUTO_INSERT=true

while [[ $# -gt 0 ]]; do
  case $1 in
    --input)
      INPUT="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --num-broll)
      NUM_BROLL="$2"
      shift 2
      ;;
    --manual-insert)
      AUTO_INSERT=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT" ]]; then
  echo "Usage: broll-workflow.sh --input <talking-head.mp4> [--output final.mp4] [--num-broll 3]"
  echo ""
  echo "This workflow:"
  echo "  1. Analyzes your video for scene changes"
  echo "  2. Extracts audio for continuous voiceover"
  echo "  3. Suggests strategic B-roll insertion points"
  echo "  4. (You'll need to generate B-roll with KIE.AI)"
  echo "  5. Merges everything together"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="/tmp/broll_workflow_$(date +%s)"
mkdir -p "$TEMP_DIR"

echo "=========================================="
echo "B-Roll Workflow Starting"
echo "=========================================="
echo ""

# Step 1: Analyze video for insertion points
echo "Step 1: Analyzing video for scene changes..."
ANALYSIS="$TEMP_DIR/analysis.json"
"$SCRIPT_DIR/analyze-video.sh" --input "$INPUT" --output "$ANALYSIS"
echo ""

# Step 2: Extract audio
echo "Step 2: Extracting audio for voiceover..."
AUDIO="$TEMP_DIR/audio.aac"
"$SCRIPT_DIR/extract-audio.sh" --input "$INPUT" --output "$AUDIO"
echo ""

# Step 3: Show suggested insertion points
echo "Step 3: Suggested B-roll insertion points:"
python3 << PYTHON_EOF
import json
with open('$ANALYSIS', 'r') as f:
    data = json.load(f)
    
print("\\nTop B-roll insertion opportunities:")
for i, point in enumerate(data.get('suggested_broll_insertion_points', []), 1):
    ts = point['timestamp']
    mins = int(ts // 60)
    secs = int(ts % 60)
    print(f"  {i}. {mins:02d}:{secs:02d} - {point['reason']}")
    print(f"     Suggested B-roll duration: {point['suggested_duration']:.1f}s")
print("\\n")
PYTHON_EOF

# Step 4: Prompt for B-roll generation
echo "Step 4: Generate B-roll with KIE.AI"
echo ""
echo "You need to generate $NUM_BROLL B-roll clips using KIE.AI."
echo ""
echo "Suggested prompts based on your video content:"
echo "  - Use Veo 3.1 Fast for cost-effective B-roll (~\$0.40/video)"
echo "  - Or Veo 3.1 Quality for premium cinematic B-roll (~\$2.00/video)"
echo ""
echo "Example KIE.AI prompts:"
echo "  'Professional office setting, modern workspace, natural lighting'"
echo "  'Abstract technology background, flowing data visualization'"
echo "  'Urban cityscape, dynamic movement, business district'"
echo ""

# Create placeholder files for B-roll
for i in $(seq 1 $NUM_BROLL); do
  touch "$TEMP_DIR/broll_$i.mp4"
done

echo "Place your KIE.AI-generated B-roll files here:"
for i in $(seq 1 $NUM_BROLL); do
  echo "  - $TEMP_DIR/broll_$i.mp4"
done
echo ""

if [[ "$AUTO_INSERT" == true ]]; then
  echo "Step 5: Once you have B-roll files, run the merge:"
  echo ""
  
  # Get insertion times from analysis
  INSERT_TIMES=$(python3 -c "import json; data=json.load(open('$ANALYSIS')); points=[str(p['timestamp']) for p in data.get('suggested_broll_insertion_points', [])[:$NUM_BROLL]]; print(','.join(points))")
  
  BROLL_FILES=$(for i in $(seq 1 $NUM_BROLL); do echo -n "$TEMP_DIR/broll_$i.mp4,"; done | sed 's/,$//')
  
  echo "  $SCRIPT_DIR/merge-broll.sh \\"
  echo "    --main \"$INPUT\" \\"
  echo "    --broll \"$BROLL_FILES\" \\"
  echo "    --insert-at \"$INSERT_TIMES\" \\"
  echo "    --output \"$OUTPUT\""
else
  echo "Step 5: Once you have B-roll files, specify insertion points manually"
fi

echo ""
echo "=========================================="
echo "Workflow staged in: $TEMP_DIR"
echo "=========================================="