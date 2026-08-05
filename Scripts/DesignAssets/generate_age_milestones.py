#!/usr/bin/env python3
"""Generate the category cover + all 13 style previews for the "age-milestones" category
(One Week -> One Year monthly growth journey).

Unlike every other category (rotating synthetic-baby identity per image, pure text-to-image —
see baby_identities.py), this category needs ONE consistent baby across the whole set so the
grid reads as a real growth journey. The trick:

  1. Generate a single base reference photo (pure text-to-image, fixed identity) for the
     youngest milestone ("One Week"). Upload it — this doubles as that style's own preview.
  2. Generate every other image (the category cover + the remaining 12 style previews) as
     image-to-image edits of that same base photo (Wiro's `inputImage` param), instructing the
     model to keep the same facial identity while aging the baby up to each milestone's age.

Resumable: writes a JSON progress log and skips entries already marked done.
"""
import base64
import json
import os
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
from baby_identities import IDENTITIES  # noqa: E402

CATALOG_PATH = PROJECT_ROOT / "Design" / "Content" / "theme_catalog.json"
PROGRESS_PATH = PROJECT_ROOT / "Scripts" / "DesignAssets" / "age_milestones_progress.json"
GEN_DIR = PROJECT_ROOT / "Design" / "Generated" / "AgeMilestones"

CATEGORY_ID = "age-milestones"
BASE_STYLE_ID = "age-one-week"

SEED_CATEGORY_URL = "https://us-central1-newborn-studio.cloudfunctions.net/seedCategoryPreviews"
SEED_STYLE_URL = "https://us-central1-newborn-studio.cloudfunctions.net/seedThemePreviews"

MAX_DIMENSION = 640
JPEG_QUALITY = 87

# Fixed identity for the whole category — deliberately NOT rotated (see module docstring).
FIXED_IDENTITY = IDENTITIES[2]  # "a baby girl with a light-brown skin tone and soft black hair"
FIXED_EYES_STATE = "eyes open, calm and alert, looking softly toward the camera"


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
        img = img.resize((round(img.width * ratio), round(img.height * ratio)), Image.LANCZOS)
    buffer = BytesIO()
    img.save(buffer, format="JPEG", quality=JPEG_QUALITY, optimize=True)
    return buffer.getvalue()


def build_base_prompt(style_name: str, descriptor: str, mood: str) -> str:
    return (
        f"A professional AI-generated documentary-style portrait of {FIXED_IDENTITY}, {FIXED_EYES_STATE}. "
        f"This baby is {style_name.lower()} old. {descriptor}. Mood: {mood}. "
        f"Soft, warm, professional lighting, photorealistic, high detail, natural newborn proportions, "
        f"no text overlays, no watermark, no logos, safe and wholesome, no adult content."
    )


def build_reference_style_prompt(style_name: str, descriptor: str, mood: str) -> str:
    return (
        f"Using the exact same baby shown in the reference image — keep the identical facial identity, "
        f"eye color, skin tone and hair color unchanged — now depict this baby aged up to {style_name.lower()} old. "
        f"{descriptor}. {FIXED_EYES_STATE}. Mood: {mood}. "
        f"Soft, warm, professional documentary-style lighting, photorealistic, high detail, natural baby "
        f"proportions appropriate for this age, no text overlays, no watermark, no logos, safe and wholesome, "
        f"no adult content."
    )


def build_reference_category_prompt(category_name: str, mood: str) -> str:
    return (
        f"Using the exact same baby shown in the reference image — keep the identical facial identity, "
        f"eye color, skin tone and hair color unchanged — representing the \"{category_name}\" theme collection, "
        f"which documents this baby's growth journey from one week old to one year old. {FIXED_EYES_STATE}. "
        f"Mood: {mood}. Soft, warm, professional studio-portrait lighting, photorealistic, high detail, "
        f"no text overlays, no watermark, no logos, safe and wholesome, no adult content."
    )


def seed_style(style_id: str, jpeg_bytes: bytes, seed_token: str) -> str:
    resp = requests.post(
        SEED_STYLE_URL,
        params={"token": seed_token},
        json={"styleId": style_id, "imageBase64": base64.b64encode(jpeg_bytes).decode("ascii")},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["previewImageUrl"]


def seed_category(category_id: str, jpeg_bytes: bytes, seed_token: str) -> str:
    resp = requests.post(
        SEED_CATEGORY_URL,
        params={"token": seed_token},
        json={"categoryId": category_id, "imageBase64": base64.b64encode(jpeg_bytes).decode("ascii")},
        timeout=60,
    )
    resp.raise_for_status()
    return resp.json()["coverImageUrl"]


def generate(prompt: str, aspect_ratio: str, input_image: str | None, out_path: Path) -> bytes:
    task_id = submit_task(prompt, aspect_ratio, input_image, 1.0, "BLOCK_ONLY_HIGH")
    task = poll_task(task_id, timeout_s=90)
    download_output(task, out_path)
    png_bytes = out_path.read_bytes()
    jpeg_bytes = resize_and_compress(png_bytes)
    out_path.unlink()
    return jpeg_bytes


def main() -> None:
    seed_token = Path("/tmp/seed_token.txt").read_text().strip()
    catalog = json.loads(CATALOG_PATH.read_text())
    category = next(c for c in catalog["categories"] if c["id"] == CATEGORY_ID)
    styles = category["styles"]
    base_style = next(s for s in styles if s["id"] == BASE_STYLE_ID)

    GEN_DIR.mkdir(parents=True, exist_ok=True)
    progress = load_progress()

    # Step 1: base reference image (One Week), pure text-to-image with the fixed identity.
    base_url = progress.get(BASE_STYLE_ID, {}).get("previewImageUrl")
    if not base_url:
        print(f"[base] {base_style['name']} ({BASE_STYLE_ID}) — text-to-image", file=sys.stderr)
        prompt = build_base_prompt(base_style["name"], base_style["descriptor"], category["mood"])
        try:
            jpeg_bytes = generate(prompt, "3:4", None, GEN_DIR / f"{BASE_STYLE_ID}.png")
            base_url = seed_style(BASE_STYLE_ID, jpeg_bytes, seed_token)
            print(f"  -> {base_url}", file=sys.stderr)
            progress[BASE_STYLE_ID] = {"status": "done", "previewImageUrl": base_url}
        except Exception as exc:  # noqa: BLE001
            print(f"  FAILED: {exc}", file=sys.stderr)
            progress[BASE_STYLE_ID] = {"status": "failed", "error": str(exc)}
            save_progress(progress)
            sys.exit(1)
        save_progress(progress)
    else:
        print(f"[base] {BASE_STYLE_ID} already done -> {base_url}", file=sys.stderr)

    # Step 2: category cover, image-to-image from the base reference.
    cover_key = f"category:{CATEGORY_ID}"
    if progress.get(cover_key, {}).get("status") != "done":
        print(f"[cover] {category['name']} ({CATEGORY_ID}) — image-to-image from base", file=sys.stderr)
        prompt = build_reference_category_prompt(category["name"], category["mood"])
        try:
            jpeg_bytes = generate(prompt, "4:3", base_url, GEN_DIR / f"{CATEGORY_ID}-cover.png")
            cover_url = seed_category(CATEGORY_ID, jpeg_bytes, seed_token)
            print(f"  -> {cover_url}", file=sys.stderr)
            progress[cover_key] = {"status": "done", "coverImageUrl": cover_url}
        except Exception as exc:  # noqa: BLE001
            print(f"  FAILED: {exc}", file=sys.stderr)
            progress[cover_key] = {"status": "failed", "error": str(exc)}
        save_progress(progress)
    else:
        print(f"[cover] already done -> {progress[cover_key]['coverImageUrl']}", file=sys.stderr)

    # Step 3: remaining 12 style previews, image-to-image from the base reference.
    remaining = [s for s in styles if s["id"] != BASE_STYLE_ID]
    for index, style in enumerate(remaining):
        style_id = style["id"]
        if progress.get(style_id, {}).get("status") == "done":
            continue
        print(f"[{index + 1}/{len(remaining)}] {style['name']} ({style_id}) — image-to-image from base", file=sys.stderr)
        prompt = build_reference_style_prompt(style["name"], style["descriptor"], category["mood"])
        try:
            jpeg_bytes = generate(prompt, "3:4", base_url, GEN_DIR / f"{style_id}.png")
            preview_url = seed_style(style_id, jpeg_bytes, seed_token)
            print(f"  -> {preview_url}", file=sys.stderr)
            progress[style_id] = {"status": "done", "previewImageUrl": preview_url}
        except Exception as exc:  # noqa: BLE001 — batch job: log and keep going
            print(f"  FAILED: {exc}", file=sys.stderr)
            progress[style_id] = {"status": "failed", "error": str(exc)}
        save_progress(progress)

    done = sum(1 for k, s in progress.items() if s.get("status") == "done" and (k in [st["id"] for st in styles] or k == cover_key))
    total = len(styles) + 1
    print(f"Done: {done}/{total}", file=sys.stderr)


if __name__ == "__main__":
    main()
