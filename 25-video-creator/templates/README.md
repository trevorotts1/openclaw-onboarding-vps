# Video Templates

Pre-built templates for common video types. Use with `template_video.py`.

## Usage

```bash
python scripts/template_video.py TEMPLATE_NAME --data template.json
```

## Available Templates

### product_showcase
Highlight reel for products. Perfect for e-commerce and marketing.

```bash
python scripts/template_video.py product_showcase --data templates/product_showcase.json
```

**Required fields:**
- `product_name` - Product name
- `images` - Array of image paths
- `features` - Array of feature strings

**Optional fields:**
- `tagline` - Product tagline
- `price` - Price string
- `call_to_action` - CTA text
- `music` - Background music genre
- `duration` - Total duration in seconds

---

### social_post
Optimized for social media platforms.

```bash
python scripts/template_video.py social_post --data templates/social_post.json
```

**Required fields:**
- `headline` - Main headline

**Optional fields:**
- `subheadline` - Secondary text
- `platform` - instagram, tiktok, youtube, twitter, linkedin
- `background` - Background image or video
- `duration` - Length in seconds
- `music` - Background music
- `cta` - Call to action text

---

### tutorial
Educational/instructional video format.

```bash
python scripts/template_video.py tutorial --data templates/tutorial.json
```

**Required fields:**
- `title` - Tutorial title
- `sections` - Array of section objects with:
  - `heading` - Section title
  - `content` - Section content
  - `duration` - Section length

**Optional fields:**
- `instructor` - Instructor name
- `music` - Background music
- `outro` - Outro text

---

### testimonial
Customer testimonial/review video.

```bash
python scripts/template_video.py testimonial --data templates/testimonial.json
```

**Required fields:**
- `quote` - Testimonial text
- `author` - Person's name

**Optional fields:**
- `title` - Author's title
- `company` - Company name
- `rating` - Star rating (1-5)
- `duration` - Length in seconds
- `background` - Background style

---

### podcast_clip
Audiogram for podcast promotion.

```bash
python scripts/template_video.py podcast_clip --data templates/podcast_clip.json
```

**Required fields:**
- `audio_file` - Path to audio clip

**Optional fields:**
- `quote_text` - Quote to display
- `speaker` - Speaker name
- `podcast_name` - Podcast title
- `episode` - Episode number
- `visualizer_style` - Audio visualization type
- `logo` - Podcast logo image

---

## Creating Custom Templates

1. Copy an existing template JSON
2. Modify fields as needed
3. Run with your custom template file

## Template Data Format

All templates use JSON format:

```json
{
  "field_name": "value",
  "array_field": ["item1", "item2"],
  "nested_object": {
    "key": "value"
  }
}
```

## Tips

- Use absolute paths or paths relative to execution directory
- Test with short durations first
- All templates support the `music` field for background audio
