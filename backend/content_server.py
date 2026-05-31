#!/usr/bin/env python3
"""
Afeedi Local Content API Server
================================
Local MCP/API environment for the Afeedi mobile app.

Endpoints:
  GET /api/v1/health                     - Health check
  GET /api/v1/content/feed               - Paginated feed (page, limit, platform)
  GET /api/v1/content/trending           - Trending content (limit)
  GET /api/v1/content/search?q=...       - Search videos (q, limit)
  GET /api/v1/content/<id>               - Single item by ID

Run: python3 backend/content_server.py
Default port: 8888  (set PORT env var to override)
"""

import json
import os
import time
import threading
import urllib.request
import urllib.parse
import http.server
import socket
from datetime import datetime, timezone
from typing import Optional

PORT = int(os.environ.get("PORT", 8888))

# ---------------------------------------------------------------------------
# Seed video IDs — real YouTube videos that will be enriched via oEmbed
# ---------------------------------------------------------------------------
_SEED_VIDEOS = [
    {"id": "1ukSR1GRtMU", "tags": ["flutter", "mobile", "development"]},
    {"id": "X8ipUgXH6jw", "tags": ["react-native", "flutter", "comparison"]},
    {"id": "NCwa_xi0Uuc", "tags": ["javascript", "es6", "programming"]},
    {"id": "vmEHCJofslg", "tags": ["python", "data-science", "pandas"]},
    {"id": "ysEN5RaKOlA", "tags": ["web-development", "roadmap"]},
    {"id": "ukzFI9rgwfU", "tags": ["machine-learning", "ai", "algorithms"]},
    {"id": "aircAruvnKk", "tags": ["ai", "neural-networks", "math"]},
    {"id": "DHjqpvDnNGE", "tags": ["javascript", "100seconds"]},
    {"id": "x7X9w_GIm1s", "tags": ["python", "100seconds"]},
    {"id": "Tn6-PIqc4UM", "tags": ["react", "frontend", "100seconds"]},
    {"id": "vIRkjTMhFvs", "tags": ["science", "aviation", "education"]},
    {"id": "e-P5IFTqB98", "tags": ["science", "genetics", "biology"]},
    {"id": "wjZofJX0v4M", "tags": ["science", "space", "history"]},
    {"id": "ZHwVBirqD2s", "tags": ["flutter", "state-management", "riverpod"]},
    {"id": "rdSJBd4YhA4", "tags": ["engineering", "comedy", "viral"]},
    {"id": "dQw4w9WgXcQ", "tags": ["music", "pop", "classic"]},
    {"id": "jNQXAC9IVRw", "tags": ["youtube", "history", "classic"]},
    {"id": "9bZkp7q19f0", "tags": ["music", "kpop", "dance"]},
    {"id": "JGwWNGJdvx8", "tags": ["music", "pop"]},
    {"id": "kJQP7kiw5Fk", "tags": ["music", "latin", "pop"]},
]

# In-memory cache: video_id -> {data, fetched_at}
_cache: dict = {}
_cache_lock = threading.Lock()
CACHE_TTL = 1800  # 30 minutes


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _fetch_oembed(video_id: str, tags: list) -> dict:
    """Fetch real metadata from YouTube oEmbed API."""
    url = (
        "https://www.youtube.com/oembed"
        f"?url=https://www.youtube.com/watch?v={video_id}&format=json"
    )
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "AfeediServer/1.0"})
        with urllib.request.urlopen(req, timeout=8) as resp:
            raw = json.loads(resp.read().decode())
            title = raw.get("title", f"Video {video_id}")
            creator = raw.get("author_name", "Unknown")
            thumb = raw.get("thumbnail_url", f"https://img.youtube.com/vi/{video_id}/mqdefault.jpg")
    except Exception:
        title = f"Video {video_id}"
        creator = "YouTube Creator"
        thumb = f"https://img.youtube.com/vi/{video_id}/mqdefault.jpg"

    creator_id = creator.lower().replace(" ", "_").replace("-", "_")
    return {
        "id": f"api_{video_id}",
        "platform": "youtube",
        "platform_content_id": video_id,
        "content_type": "video",
        "title": title,
        "description": f"Video by {creator} on YouTube.",
        "thumbnail_url": thumb,
        "video_url": f"https://www.youtube.com/watch?v={video_id}",
        "embed_url": f"https://www.youtube.com/embed/{video_id}",
        "duration_seconds": None,
        "view_count": 0,
        "like_count": 0,
        "creator_name": creator,
        "creator_id": creator_id,
        "creator_avatar_url": None,
        "tags": tags,
        "categories": [],
        "language": "en",
        "published_at": None,
        "is_active": True,
        "content_rating": None,
        "metadata": {"source": "oembed"},
        "created_at": _now_iso(),
        "updated_at": _now_iso(),
    }


def _get_cached(video_id: str, tags: list) -> dict:
    with _cache_lock:
        entry = _cache.get(video_id)
        if entry and time.time() - entry["fetched_at"] < CACHE_TTL:
            return entry["data"]
    data = _fetch_oembed(video_id, tags)
    with _cache_lock:
        _cache[video_id] = {"data": data, "fetched_at": time.time()}
    return data


def _get_all_content() -> list:
    """Return enriched list of all seed content (threaded fetch)."""
    results = [None] * len(_SEED_VIDEOS)
    threads = []

    def fetch(idx, vid):
        results[idx] = _get_cached(vid["id"], vid["tags"])

    for i, v in enumerate(_SEED_VIDEOS):
        t = threading.Thread(target=fetch, args=(i, v), daemon=True)
        threads.append(t)
        t.start()
    for t in threads:
        t.join(timeout=12)

    return [r for r in results if r is not None]


# Pre-warm cache on startup in background
def _prewarm():
    print("[server] Pre-warming content cache …")
    _get_all_content()
    print(f"[server] Cache warm: {len(_cache)} items ready")


threading.Thread(target=_prewarm, daemon=True).start()


# ---------------------------------------------------------------------------
# HTTP Request Handler
# ---------------------------------------------------------------------------
class AfeediHandler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        print(f"[{self.address_string()}] {fmt % args}")

    def _send_json(self, data, status=200):
        body = json.dumps(data, ensure_ascii=False).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()
        self.wfile.write(body)

    def _send_error(self, code, message):
        self._send_json({"error": message, "status": code}, status=code)

    def do_OPTIONS(self):
        self.send_response(204)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, Authorization")
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        path = parsed.path.rstrip("/")
        params = urllib.parse.parse_qs(parsed.query)

        if path == "/api/v1/health":
            self._handle_health()
        elif path == "/api/v1/content/feed":
            self._handle_feed(params)
        elif path == "/api/v1/content/trending":
            self._handle_trending(params)
        elif path == "/api/v1/content/search":
            self._handle_search(params)
        elif path.startswith("/api/v1/content/"):
            self._handle_single(path.split("/")[-1])
        else:
            self._send_error(404, f"Unknown endpoint: {path}")

    def _handle_health(self):
        self._send_json({
            "status": "ok",
            "service": "Afeedi Content API",
            "version": "1.0.0",
            "cached_items": len(_cache),
            "timestamp": _now_iso(),
        })

    def _handle_feed(self, params):
        all_content = _get_all_content()
        page = int(params.get("page", ["1"])[0])
        limit = min(int(params.get("limit", ["10"])[0]), 50)
        platform = params.get("platform", [None])[0]

        if platform:
            all_content = [c for c in all_content if c.get("platform") == platform]

        start = (page - 1) * limit
        items = all_content[start: start + limit]

        self._send_json({
            "items": items,
            "page": page,
            "limit": limit,
            "total": len(all_content),
            "has_more": start + limit < len(all_content),
        })

    def _handle_trending(self, params):
        all_content = _get_all_content()
        limit = min(int(params.get("limit", ["10"])[0]), 50)
        # Sort by view_count + like_count descending
        sorted_content = sorted(
            all_content,
            key=lambda c: c.get("view_count", 0) + c.get("like_count", 0),
            reverse=True,
        )
        self._send_json({"items": sorted_content[:limit], "total": len(all_content)})

    def _handle_search(self, params):
        query = params.get("q", [""])[0].lower().strip()
        limit = min(int(params.get("limit", ["10"])[0]), 50)

        if not query:
            self._send_json({"items": [], "total": 0, "query": ""})
            return

        all_content = _get_all_content()
        results = [
            c for c in all_content
            if query in (c.get("title") or "").lower()
            or query in (c.get("description") or "").lower()
            or query in (c.get("creator_name") or "").lower()
            or any(query in t.lower() for t in c.get("tags", []))
        ]

        self._send_json({
            "items": results[:limit],
            "total": len(results),
            "query": query,
        })

    def _handle_single(self, item_id: str):
        all_content = _get_all_content()
        for item in all_content:
            if item.get("id") == item_id or item.get("platform_content_id") == item_id:
                self._send_json(item)
                return
        self._send_error(404, f"Content not found: {item_id}")


# ---------------------------------------------------------------------------
# Server startup
# ---------------------------------------------------------------------------
def run():
    # Allow port reuse so rapid restarts don't get "address already in use"
    http.server.HTTPServer.allow_reuse_address = True
    server = http.server.HTTPServer(("0.0.0.0", PORT), AfeediHandler)
    print(f"[server] Afeedi Content API running on http://localhost:{PORT}")
    print(f"[server] Endpoints:")
    print(f"  GET /api/v1/health")
    print(f"  GET /api/v1/content/feed?page=1&limit=10")
    print(f"  GET /api/v1/content/trending?limit=5")
    print(f"  GET /api/v1/content/search?q=flutter")
    print(f"  GET /api/v1/content/<id>")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[server] Shutting down.")
        server.shutdown()


if __name__ == "__main__":
    run()
