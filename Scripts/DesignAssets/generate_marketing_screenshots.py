#!/usr/bin/env python3
"""Generate the App Store marketing screenshot source images (one consistent synthetic baby,
carried through a baseline "before" photo and 7 image-to-image themed portraits) via Wiro
nano-banana.

Reuses submit/poll/download from generate_nano_banana.py but adds local-file inputImage
support (real multipart attachment — verified working, undocumented — see
wiro-nano-banana-api memory) instead of requiring a hosted URL.

Resumable: skips any output file that already exists.
"""
import sys
import time
from pathlib import Path

import requests

sys.path.insert(0, str(Path(__file__).resolve().parent))
from generate_nano_banana import auth_headers, poll_task, download_output, RUN_URL, PROJECT_ROOT  # noqa: E402

OUT_DIR = PROJECT_ROOT / "Design" / "Generated" / "MarketingScreenshots"

BASE_PROMPT = (
    "A candid, ordinary smartphone snapshot of a baby boy, around 6 months old, "
    "fair skin, blond hair and blue eyes, sitting on a plain living room couch, "
    "wearing a simple cream onesie, natural indoor daylight, slightly casual framing, "
    "realistic amateur phone-photo quality, no studio lighting, no props, no text, "
    "no watermark, safe and wholesome, no adult content."
)

THEME_TEMPLATE = (
    "Transform the baby in the reference photo into a professional AI-generated studio "
    "portrait. Theme: {name} — {descriptor}. Mood: {mood}. Soft, warm, professional "
    "studio-portrait lighting, photorealistic, high detail, preserve the baby's real face "
    "and likeness from the reference photo, natural baby proportions, no text, no "
    "watermark, no logos, safe and wholesome, no adult content."
)

THEMES = [
    ("hero_wizard", "Wizard Apprentice", "dressed in an oversized wizard robe and star-covered hat",
     "dreamy, magical, enchanted fairytale atmosphere"),
    ("mosaic_astronaut", "Little Astronaut", "in a plush astronaut suit with a helmet prop",
     "playful, cosmic, wonder-filled space adventure"),
    ("mosaic_firefighter", "Little Firefighter", "wearing a mini firefighter helmet and coat",
     "cheerful, playful, pretend-career charm"),
    ("mosaic_lion_cub", "Lion Cub", "wearing a lion-mane hood against a golden savanna backdrop",
     "warm, earthy, gentle wildlife charm"),
    ("mosaic_bubble_diver", "Bubble Diver", "wearing a diving-mask prop against a bubble backdrop",
     "shimmering, aquatic, dreamy underwater glow"),
    ("mosaic_batman", "Tiny Batman", "wearing a bat-eared cowl and cape",
     "bold, energetic, heroic comic-book fun"),
    ("mosaic_snow_angel", "Snow Angel", "wrapped in white fur against a snowflake backdrop",
     "cozy, festive, warm holiday glow"),
]


def submit_task_with_file(prompt: str, aspect_ratio: str, input_image_path: Path | None,
                           temperature: float = 1.0, safety_setting: str = "BLOCK_ONLY_HIGH") -> str:
    data = {"prompt": prompt, "aspectRatio": aspect_ratio, "temperature": str(temperature),
            "safetySetting": safety_setting}
    files = None
    if input_image_path:
        files = {"inputImage": (input_image_path.name, open(input_image_path, "rb"), "image/png")}
    resp = requests.post(RUN_URL, headers=auth_headers(), data=data, files=files, timeout=60)
    resp.raise_for_status()
    payload = resp.json()
    taskid = payload.get("taskid")
    if not taskid:
        raise RuntimeError(f"No taskid in response: {payload}")
    return taskid


def generate(prompt: str, aspect_ratio: str, input_image_path: Path | None, out_path: Path,
             max_retries: int = 2) -> None:
    if out_path.exists():
        print(f"Skipping (exists): {out_path.name}", file=sys.stderr)
        return
    for attempt in range(1, max_retries + 2):
        print(f"[{out_path.stem}] submitting (attempt {attempt}): {prompt[:70]}...", file=sys.stderr)
        taskid = submit_task_with_file(prompt, aspect_ratio, input_image_path)
        task = poll_task(taskid, timeout_s=120)
        if task.get("outputs"):
            download_output(task, out_path)
            print(f"[{out_path.stem}] saved: {out_path}", file=sys.stderr)
            return
        print(f"[{out_path.stem}] empty outputs (likely content-safety flake), retrying...", file=sys.stderr)
        time.sleep(2)
    raise RuntimeError(f"[{out_path.stem}] failed after {max_retries + 1} attempts (empty outputs each time)")


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    base_path = OUT_DIR / "00_base_before.png"
    generate(BASE_PROMPT, "3:4", None, base_path)

    for slug, name, descriptor, mood in THEMES:
        prompt = THEME_TEMPLATE.format(name=name, descriptor=descriptor, mood=mood)
        aspect = "3:4" if slug.startswith("hero") else "1:1"
        out_path = OUT_DIR / f"{slug}.png"
        generate(prompt, aspect, base_path, out_path)

    print("All marketing screenshot source images generated.", file=sys.stderr)


if __name__ == "__main__":
    main()
