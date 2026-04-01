#!/usr/bin/env python3
import sys
import os
import sqlite3
import argparse
import time
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'shared-utils'))
from key_resolver import resolve_key

try:
    from google import genai
    from google.genai import types
    import numpy as np
except ImportError:
    print("CRITICAL ERROR: Missing dependencies.")
    sys.exit(1)

def _get_google_api_key():
    return get_google_key()



def _load_openclaw_env():
    import json
    for path in ['/data/.openclaw/openclaw.json', str(Path.home()/'.openclaw'/'openclaw.json')]:
        try:
            cfg = json.load(open(path))
            for k,v in cfg.get('env',{}).get('vars',{}).items():
                os.environ.setdefault(k, v)
        except:
            pass

DB_PATH = os.path.expanduser("~/clawd/data/coaching-personas/gemini-index.sqlite")
GEMINI_MODEL = "gemini-embedding-2-preview"
TOP_K = 3

def get_client():
    _load_openclaw_env()
    api_key = _get_google_api_key()
    if not api_key:
        env_paths = [
            os.path.expanduser("~/clawd/secrets/.env"),
            os.path.expanduser("~/.openclaw/.env"),
            os.path.expanduser("~/.openclaw/secrets/.env"),
            "/data/clawd/secrets/.env",
            "/data/.openclaw/.env",
        ]
        for env_path in env_paths:
            if os.path.exists(env_path):
                with open(env_path, "r") as f:
                    for line in f:
                        if line.startswith("GOOGLE_API_KEY=") or line.startswith("GOOGLE_AI_STUDIO_API_KEY=") or line.startswith("GOOGLE_GEMINI_API_KEY=") or line.startswith("GEMINI_API_KEY="):
                            api_key = line.strip().split("=", 1)[1].strip('"\'')
                            break
                if api_key:
                    break
    if not api_key:
        print("WARNING: Google API key not found in any supported env location. Using keyword fallback.")
        sys.exit(2)
    return genai.Client(api_key=api_key)

def embed_query(client, query):
    for attempt in range(3):
        try:
            response = client.models.embed_content(
                model=GEMINI_MODEL,
                contents=query,
                config=types.EmbedContentConfig(task_type="RETRIEVAL_QUERY")
            )
            return np.array(response.embeddings[0].values, dtype=np.float32)
        except Exception as e:
            if "429" in str(e).lower() or "quota" in str(e).lower():
                time.sleep(2)
            else: raise e
    raise RuntimeError("Query embedding failed.")

def cosine_similarity(v1, v2):
    dot_product = np.dot(v1, v2)
    norm_v1 = np.linalg.norm(v1)
    norm_v2 = np.linalg.norm(v2)
    if norm_v1 == 0 or norm_v2 == 0: return 0.0
    return dot_product / (norm_v1 * norm_v2)

def main():
    _load_openclaw_env()
    parser = argparse.ArgumentParser()
    parser.add_argument("query", type=str, help="Search keyword")
    parser.add_argument("--limit", type=int, default=TOP_K)
    args = parser.parse_args()
    
    if not os.path.exists(DB_PATH):
        print(f"ERROR: Database not found at {DB_PATH}")
        sys.exit(1)
        
    client = get_client()
    query_vector = embed_query(client, args.query)
    
    conn = sqlite3.connect(DB_PATH, timeout=30.0)
    cursor = conn.cursor()
    cursor.execute("SELECT id, file_path, content, vector FROM embeddings")
    rows = cursor.fetchall()
    conn.close()
    
    if not rows:
        print("No documents found in the index.")
        sys.exit(0)
        
    results = []
    for row in rows:
        chunk_id, file_path, content, vector_bytes = row
        stored_vector = np.frombuffer(vector_bytes, dtype=np.float32)
        sim = cosine_similarity(query_vector, stored_vector)
        results.append((sim, file_path, content))
        
    results.sort(key=lambda x: x[0], reverse=True)
    top_results = results[:args.limit]
    
    for i, (sim, path, content) in enumerate(top_results, 1):
        print(f"[{i}] SCORE: {sim:.4f} | FILE: {os.path.basename(path)}")
        print("-" * 60)
        print(f"{content.strip()[:800]}...\\n")

if __name__ == "__main__":
    main()
