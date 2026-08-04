#!/usr/bin/env python3
"""Generate a preview thumbnail for every style in theme_catalog.json via Wiro nano-banana,
resize/compress it, upload to Firebase Storage, and set ai_models/{styleId}.previewImageUrl
via the seedThemePreviews Cloud Function.

Resumable: writes a JSON progress log and skips styleIds already marked done.
"""
import base64
import json
import os
import sys
import time
from io import BytesIO
from pathlib import Path

import requests
from dotenv import load_dotenv
from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_nano_banana import submit_task, poll_task, download_output  # noqa: E402

CATALOG_PATH = PROJECT_ROOT / "Design" / "Content" / "theme_catalog.json"
PROGRESS_PATH = PROJECT_ROOT / "Scripts" / "DesignAssets" / "theme_preview_progress.json"
BASE_PHOTO_URL_PATH = Path("/tmp/base_photo_url.txt")

SEED_FN_URL = "https://us-central1-newborn-studio.cloudfunctions.net/seedThemePreviews"
MAX_DIMENSION = 640
JPEG_QUALITY = 87


def build_prompt(style_name: str, descriptor: str, mood: str) -> str:
    """Mirrors functions/helpers/prompt.js exactly — keep both in sync."""
    return (
        f"Transform the uploaded baby photo into a professional AI-generated studio portrait. "
        f"Theme: {style_name} — {descriptor}. "
        f"Mood: {mood}. "
        f"Preserve the baby's exact face, expression, proportions and skin tone from the original "
        f"photo; only change styling, outfit, props and background to match the theme. "
        f"Soft, warm, professional studio-portrait lighting, photorealistic, high detail, "
        f"no text, no watermark, no logos, safe and wholesome, no adult content."
    )


def load_progress() -> dict:
    if PROGRESS_PATH.exists():
        return json.loads(PROGRESS_PATH.read_text())
    return {}


def save_progress(progress: dict) -> None:
    PROGRESS_PATH.write_text(json.dumps(progress, indent=2))


def resize_and_compress(png_bytes: bytes) -> bytes:
    img = Image.open(BytesIO(png_bytes)).convert("RGB")
    ratio = MAX_DIMENSION / max(img.size)
    if ratio < 1:
        new_size = (round(img.width * ratio), round(img.height * ratio))
        img = img.resize(new_size, Image.LANCZOS)
    buffer = BytesIO()
    img.save(buffer, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return buffer.getvalue()


def seed_preview(style_id: str, jpeg_bytes: bytes, seed_token: str) -> str:
    resp = requests.post(
        SEED_FN_URL,
        params={"token": seed_token},
        json={"styleId": style_id, "imageBase64": base64.b64encode(jpeg_bytes).decode("ascii")},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["previewImageUrl"]


def main() -> None:
    api_key = os.environ["WIRO_API_KEY"]
    api_secret = os.environ["WIRO_API_SECRET"]
    seed_token = Path("/tmp/seed_token.txt").read_text().strip()
    base_photo_url = BASE_PHOTO_URL_PATH.read_text().strip()

    catalog = json.loads(CATALOG_PATH.read_text())
    progress = load_progress()

    all_styles = []
    for category in catalog["categories"]:
        for style in category["styles"]:
            all_styles.append((category, style))

    total = len(all_styles)
    done_count = sum(1 for s in progress.values() if s.get("status") == "done")
    print(f"{done_count}/{total} already done, resuming...", file=sys.stderr)

    for index, (category, style) in enumerate(all_styles, start=1):
        style_id = style["id"]
        if progress.get(style_id, {}).get("status") == "done":
            continue

        prompt = build_prompt(style["name"], style["descriptor"], category["mood"])
        print(f"[{index}/{total}] {category['name']} / {style['name']} ({style_id})", file=sys.stderr)

        try:
            task_id = submit_task(prompt, "3:4", base_photo_url, 1.0, "BLOCK_ONLY_HIGH")
            task = poll_task(task_id, timeout_s=90)
            output = download_output(task, PROJECT_ROOT / "Design" / "Generated" / "ThemePreviews" / f"{style_id}.png")
            png_bytes = (PROJECT_ROOT / "Design" / "Generated" / "ThemePreviews" / f"{style_id}.png").read_bytes()
            jpeg_bytes = resize_and_compress(png_bytes)
            (PROJECT_ROOT / "Design" / "Generated" / "ThemePreviews" / f"{style_id}.png").unlink()  # keep only the compressed jpeg locally
            preview_url = seed_preview(style_id, jpeg_bytes, seed_token)
            progress[style_id] = {"status": "done", "previewImageUrl": preview_url}
        except Exception as exc:  # noqa: BLE001 — batch job: log and keep going
            print(f"  FAILED: {exc}", file=sys.stderr)
            progress[style_id] = {"status": "failed", "error": str(exc)}

        save_progress(progress)

    done = sum(1 for s in progress.values() if s.get("status") == "done")
    failed = sum(1 for s in progress.values() if s.get("status") == "failed")
    print(f"Done: {done}/{total}, failed: {failed}", file=sys.stderr)


if __name__ == "__main__":
    main()
