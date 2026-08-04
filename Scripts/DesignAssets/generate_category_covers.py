#!/usr/bin/env python3
"""Generate one cover image per category (20 total) via Wiro, resize/compress, upload to
Storage via seedCategoryPreviews, matching the pattern in generate_theme_previews.py."""
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

CATALOG_PATH = PROJECT_ROOT / "Design" / "Content" / "theme_catalog.json"
SEED_FN_URL = "https://us-central1-newborn-studio.cloudfunctions.net/seedCategoryPreviews"
BASE_PHOTO_URL_PATH = Path("/tmp/base_photo_url.txt")
MAX_DIMENSION = 640
JPEG_QUALITY = 87


def build_category_prompt(category_name: str, mood: str) -> str:
    """Mirrors functions/helpers/prompt.js buildCategoryPrompt exactly."""
    return (
        f'Transform the uploaded baby photo into a professional AI-generated studio portrait '
        f'representing the "{category_name}" theme collection. '
        f"Mood: {mood}. "
        f"Preserve the baby's exact face, expression, proportions and skin tone from the original "
        f"photo; only change styling, outfit, props and background to fit the theme. "
        f"Soft, warm, professional studio-portrait lighting, photorealistic, high detail, "
        f"no text, no watermark, no logos, safe and wholesome, no adult content."
    )


def resize_and_compress(png_bytes: bytes) -> bytes:
    img = Image.open(BytesIO(png_bytes)).convert("RGB")
    ratio = MAX_DIMENSION / max(img.size)
    if ratio < 1:
        img = img.resize((round(img.width * ratio), round(img.height * ratio)), Image.LANCZOS)
    buffer = BytesIO()
    img.save(buffer, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return buffer.getvalue()


def main() -> None:
    import os

    api_key = os.environ["WIRO_API_KEY"]
    api_secret = os.environ["WIRO_API_SECRET"]
    seed_token = Path("/tmp/seed_token.txt").read_text().strip()
    base_photo_url = BASE_PHOTO_URL_PATH.read_text().strip()

    catalog = json.loads(CATALOG_PATH.read_text())
    categories = catalog["categories"]
    out_dir = PROJECT_ROOT / "Design" / "Generated" / "CategoryCovers"
    out_dir.mkdir(parents=True, exist_ok=True)

    for index, category in enumerate(categories, start=1):
        category_id = category["id"]
        prompt = build_category_prompt(category["name"], category["mood"])
        print(f"[{index}/{len(categories)}] {category['name']} ({category_id})", file=sys.stderr)
        try:
            task_id = submit_task(prompt, "4:3", base_photo_url, 1.0, "BLOCK_ONLY_HIGH")
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
            print(f"  -> {resp.json()['coverImageUrl']}", file=sys.stderr)
        except Exception as exc:  # noqa: BLE001
            print(f"  FAILED: {exc}", file=sys.stderr)

    print("Done.", file=sys.stderr)


if __name__ == "__main__":
    main()
