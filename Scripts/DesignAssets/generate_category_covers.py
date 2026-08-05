#!/usr/bin/env python3
"""Generate one cover image per category (20 total) via Wiro, resize/compress, upload to
Storage via seedCategoryPreviews, matching the pattern in generate_theme_previews.py.

Pure text-to-image (no reference photo) with a rotating synthetic-baby identity per category —
see baby_identities.py — so covers don't all show the same baby with the same closed eyes."""
import base64
import json
import sys
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
SEED_FN_URL = "https://us-central1-newborn-studio.cloudfunctions.net/seedCategoryPreviews"
MAX_DIMENSION = 640
JPEG_QUALITY = 87


def build_category_prompt(category_name: str, mood: str, identity: str, eyes_state: str) -> str:
    return (
        f"A professional AI-generated studio portrait of {identity}, {eyes_state}, "
        f'representing the "{category_name}" theme collection. '
        f"Mood: {mood}. "
        f"Soft, warm, professional studio-portrait lighting, photorealistic, high detail, "
        f"natural newborn/baby proportions, no text, no watermark, no logos, safe and wholesome, "
        f"no adult content."
    )


def resize_and_compress(png_bytes: bytes) -> bytes:
    img = Image.open(BytesIO(png_bytes)).convert("RGB")
    ratio = MAX_DIMENSION / max(img.size)
    if ratio < 1:
        img = img.resize((round(img.width * ratio), round(img.height * ratio)), Image.LANCZOS)
    buffer = BytesIO()
    img.save(buffer, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return buffer.getvalue()


PROGRESS_PATH = PROJECT_ROOT / "Scripts" / "DesignAssets" / "category_cover_progress.json"


def load_progress() -> dict:
    if PROGRESS_PATH.exists():
        return json.loads(PROGRESS_PATH.read_text())
    return {}


def save_progress(progress: dict) -> None:
    PROGRESS_PATH.write_text(json.dumps(progress, indent=2))


def main() -> None:
    import os

    api_key = os.environ["WIRO_API_KEY"]
    api_secret = os.environ["WIRO_API_SECRET"]
    seed_token = Path("/tmp/seed_token.txt").read_text().strip()

    catalog = json.loads(CATALOG_PATH.read_text())
    categories = catalog["categories"]
    out_dir = PROJECT_ROOT / "Design" / "Generated" / "CategoryCovers"
    out_dir.mkdir(parents=True, exist_ok=True)
    progress = load_progress()

    for index, category in enumerate(categories):
        category_id = category["id"]
        if progress.get(category_id, {}).get("status") == "done":
            continue
        eyes_state = eyes_state_for(category["mood"])
        prompt = build_category_prompt(category["name"], category["mood"], identity_for(index), eyes_state)
        print(f"[{index + 1}/{len(categories)}] {category['name']} ({category_id})", file=sys.stderr)
        try:
            task_id = submit_task(prompt, "4:3", None, 1.0, "BLOCK_ONLY_HIGH")
            task = poll_task(task_id, timeout_s=90)
            out_path = out_dir / f"{category_id}.png"
            download_output(task, out_path)
            jpeg_bytes = resize_and_compress(out_path.read_bytes())
            out_path.unlink()
            resp = requests.post(
                SEED_FN_URL,
                params={"token": seed_token},
                json={"categoryId": category_id, "imageBase64": base64.b64encode(jpeg_bytes).decode("ascii")},
                timeout=60,
            )
            resp.raise_for_status()
            cover_url = resp.json()["coverImageUrl"]
            print(f"  -> {cover_url}", file=sys.stderr)
            progress[category_id] = {"status": "done", "coverImageUrl": cover_url}
        except Exception as exc:  # noqa: BLE001 — batch job: log and keep going
            print(f"  FAILED: {exc}", file=sys.stderr)
            progress[category_id] = {"status": "failed", "error": str(exc)}
        save_progress(progress)

    done = sum(1 for s in progress.values() if s.get("status") == "done")
    failed = sum(1 for s in progress.values() if s.get("status") == "failed")
    print(f"Done: {done}/{len(categories)}, failed: {failed}", file=sys.stderr)


if __name__ == "__main__":
    main()
