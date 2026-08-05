#!/usr/bin/env python3
"""Generate a preview thumbnail for every style in theme_catalog.json via Wiro nano-banana,
resize/compress it, upload to Firebase Storage, and set ai_models/{styleId}.previewImageUrl
via the seedThemePreviews Cloud Function.

Pure text-to-image (no reference photo) with a rotating synthetic-baby identity per style —
see baby_identities.py — so previews don't all show the same baby with the same closed eyes.

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
from baby_identities import identity_for, eyes_state_for  # noqa: E402

CATALOG_PATH = PROJECT_ROOT / "Design" / "Content" / "theme_catalog.json"
PROGRESS_PATH = PROJECT_ROOT / "Scripts" / "DesignAssets" / "theme_preview_progress.json"

SEED_FN_URL = "https://us-central1-newborn-studio.cloudfunctions.net/seedThemePreviews"
MAX_DIMENSION = 640
JPEG_QUALITY = 87


def build_prompt(style_name: str, descriptor: str, mood: str, identity: str, eyes_state: str) -> str:
    return (
        f"A professional AI-generated studio portrait of {identity}, {eyes_state}. "
        f"Theme: {style_name} — {descriptor}. "
        f"Mood: {mood}. "
        f"Soft, warm, professional studio-portrait lighting, photorealistic, high detail, "
        f"natural newborn/baby proportions, no text, no watermark, no logos, safe and wholesome, "
        f"no adult content."
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

    catalog = json.loads(CATALOG_PATH.read_text())
    progress = load_progress()

    all_styles = []
    for category in catalog["categories"]:
        for style in category["styles"]:
            all_styles.append((category, style))

    total = len(all_styles)
    done_count = sum(1 for s in progress.values() if s.get("status") == "done")
    print(f"{done_count}/{total} already done, resuming...", file=sys.stderr)

    for index, (category, style) in enumerate(all_styles):
        style_id = style["id"]
        if progress.get(style_id, {}).get("status") == "done":
            continue

        eyes_state = eyes_state_for(style["descriptor"])
        prompt = build_prompt(style["name"], style["descriptor"], category["mood"], identity_for(index), eyes_state)
        print(f"[{index + 1}/{total}] {category['name']} / {style['name']} ({style_id})", file=sys.stderr)

        try:
            task_id = submit_task(prompt, "3:4", None, 1.0, "BLOCK_ONLY_HIGH")
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
