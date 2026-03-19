# Migration Guide: Gemini Engine to Gemini Embedding 2

**For:** Existing users with Gemini Engine indexes (Corey, Trevor, and others)  
**When:** After updating to the new onboarding package  
**What:** Transition from local SQLite Gemini Engine to Google Gemini API

---

## What Changed

| Before | After |
|--------|-------|
| Local SQLite database (`~/.cache/qmd/index.sqlite`) | Google Gemini Embedding 2 API |
| `python3 ~/clawd/scripts/gemini-indexer.py` commands | `gai-search` CLI or direct Gemini API |
| `Gemini Engine Index` in persona blueprints | `Gemini Index` |
| `./qmd-index/` folder references | `./gemini-index/` |
| `GEMINI-RETRIEVAL-GUIDE.md` | `GAI-SEARCH-GUIDE.md` |

---

## Do I Need to Migrate?

### If you're a NEW user installing fresh:
**No action needed.** The new install scripts handle everything automatically.

### If you're an EXISTING user with personas already built:
**Yes, you need to migrate your indexes.** Your persona blueprints are fine, but the retrieval mechanism changed.

---

## Migration Steps

### Step 1: Get a Google AI Studio API Key

1. Go to [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. Create a new API key
3. Copy the key (starts with `AIza...`)

### Step 2: Set the Environment Variable

**Add to your shell profile** (`~/.zshrc` or `~/.bashrc`):
```bash
export GOOGLE_AI_STUDIO_API_KEY="your-key-here"
```

**Or set temporarily** for current session:
```bash
export GOOGLE_AI_STUDIO_API_KEY="your-key-here"
```

### Step 3: Install the Gemini SDK

```bash
pip install google-genai
```

### Step 4: Re-index Your Personas

**Option A: Using gai-search CLI (if available)**
```bash
# Navigate to your personas
cd ~/.openclaw/skills/22-book-to-persona-coaching-leadership-system/personas

# Index all personas
gai-search index add */persona-blueprint.md -c coaching-personas
```

**Option B: Using Python script**
```bash
cd ~/.openclaw/skills/22-book-to-persona-coaching-leadership-system
python3 -c "
from google import genai
from google.genai import types
import os

client = genai.Client(api_key=os.environ['GOOGLE_AI_STUDIO_API_KEY'])

persona_dir = 'personas'
for root, dirs, files in os.walk(persona_dir):
    for file in files:
        if file == 'persona-blueprint.md':
            filepath = os.path.join(root, file)
            with open(filepath, 'r') as f:
                content = f.read()
            
            response = client.models.embed_content(
                model='models/gemini-embedding-2-preview',
                contents=[types.Content(parts=[types.Part(text=content)])]
            )
            print(f'Indexed: {filepath}')
"
```

### Step 5: Verify the Migration

```bash
# Check that Gemini is working
python3 -c "
from google import genai
import os
client = genai.Client(api_key=os.environ['GOOGLE_AI_STUDIO_API_KEY'])
response = client.models.embed_content(
    model='models/gemini-embedding-2-preview',
    contents=['test']
)
print('✅ Gemini API is working')
"
```

---

## What About My Old Gemini Engine Data?

Your old Gemini Engine index at `~/.cache/qmd/index.sqlite` is **not deleted** during migration. It remains in place but is no longer used.

**To reclaim disk space** (optional):
```bash
rm ~/.cache/qmd/index.sqlite
# Or remove entire qmd cache:
# rm -rf ~/.cache/qmd/
```

**To keep as backup** (recommended for 30 days):
```bash
mv ~/.cache/qmd/index.sqlite ~/.cache/qmd/index.sqlite.backup
```

---

## Troubleshooting

### "Gemini API key not found"
```bash
# Check if it's set
echo $GOOGLE_AI_STUDIO_API_KEY

# If empty, set it:
export GOOGLE_AI_STUDIO_API_KEY="your-key"
```

### "google-genai module not found"
```bash
pip install google-genai
```

### "Permission denied on API key"
- Verify the key is valid at [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
- Check that billing is enabled on your Google Cloud project

### "Persona blueprints still say Gemini Engine Index"
The blueprints were updated during the package update. If you see old references:
```bash
# Force refresh the skill
cd ~/.openclaw/skills/22-book-to-persona-coaching-leadership-system
git pull origin main  # or re-run install script
```

---

## Rollback (If Needed)

If you need to revert to Gemini Engine temporarily:

1. **Restore Gemini Engine index** (if you backed it up):
   ```bash
   mv ~/.cache/qmd/index.sqlite.backup ~/.cache/qmd/index.sqlite
   ```

2. **Reinstall qmd** (if removed):
   ```bash
   # Follow original Gemini Engine installation steps
   ```

3. **Use older version** of onboarding package:
   ```bash
   # Check out previous commit before migration
   cd /path/to/onboarding-vps
   git checkout <commit-hash-before-migration>
   ```

---

## FAQ

**Q: Why did we move from Gemini Engine to Gemini?**  
A: Gemini Embedding 2 is a managed API with better performance, no local database maintenance, and automatic scaling. It also integrates directly with Google's AI ecosystem.

**Q: Will this cost money?**  
A: Google AI Studio has a free tier. Check [https://ai.google.dev/pricing](https://ai.google.dev/pricing) for current rates. Typical usage (indexing 40 personas, occasional queries) is well within free limits.

**Q: Do I need to rebuild all my personas?**  
A: No. The persona blueprints are unchanged. Only the indexing mechanism changed. Your content is preserved.

**Q: Can I use both Gemini Engine and Gemini simultaneously?**  
A: Not recommended. The codebase now expects Gemini. Using both would cause confusion.

**Q: What about other skills that used Gemini Engine?**  
A: All 30 skills have been updated. The `build-workforce.py` script now uses Gemini API directly.

---

## Support

If you encounter issues during migration:

1. Check this guide first
2. Verify your API key at [https://aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
3. Re-read `GAI-SEARCH-GUIDE.md` in the book-to-persona skill folder
4. Contact Trevor for help

---

## Summary

| Task | Command | Status |
|------|---------|--------|
| Get API key | [Google AI Studio](https://aistudio.google.com/app/apikey) | Required |
| Set environment | `export GOOGLE_AI_STUDIO_API_KEY="..."` | Required |
| Install SDK | `pip install google-genai` | Required |
| Re-index personas | Use Option A or B above | Required |
| Clean up old Gemini Engine | `rm ~/.cache/qmd/index.sqlite` | Optional |
| Verify | Python test script above | Recommended |

**Migration complete when:** You can run `build-workforce.py` without Gemini Engine errors.
