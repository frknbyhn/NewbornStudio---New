#!/usr/bin/env python3
"""Generate an image via Wiro's google/nano-banana (Gemini 2.5 Flash Image) API.

Usage:
    venv/bin/python generate_nano_banana.py --prompt "..." --aspect-ratio 1:1 --out ../../Design/Generated/app_icon.png
    venv/bin/python generate_nano_banana.py --prompt "..." --input-image https://example.com/photo.jpg --out result.png

Credentials are read from WIRO_API_KEY / WIRO_API_SECRET in the project root .env (never hardcoded).
"""
import argparse
import hashlib
import hmac
import os
import sys
import time
from pathlib import Path

import requests
from dotenv import load_dotenv

PROJECT_ROOT = Path(__file__).resolve().parents[2]
load_dotenv(PROJECT_ROOT / ".env")

API_BASE = "https://api.wiro.ai/v1"
RUN_URL = f"{API_BASE}/Run/google/nano-banana"
DETAIL_URL = f"{API_BASE}/Task/Detail"

TERMINAL_SUCCESS = "task_postprocess_end"
TERMINAL_FAILURE = "task_cancel"


def auth_headers() -> dict:
    api_key = os.environ["WIRO_API_KEY"]
    api_secret = os.environ["WIRO_API_SECRET"]
    nonce = str(int(time.time()))
    signature = hmac.new(
        api_key.encode("utf-8"),
        (api_secret + nonce).encode("utf-8"),
        hashlib.sha256,
    ).hexdigest()
    return {"x-api-key": api_key, "x-nonce": nonce, "x-signature": signature}


def submit_task(prompt: str, aspect_ratio: str, input_image: str | None, temperature: float, safety_setting: str) -> str:
    data = {
        "prompt": prompt,
        "aspectRatio": aspect_ratio,
        "temperature": str(temperature),
        "safetySetting": safety_setting,
    }
    if input_image:
        data["inputImage"] = input_image
    resp = requests.post(RUN_URL, headers=auth_headers(), data=data, timeout=60)
    resp.raise_for_status()
    payload = resp.json()
    taskid = payload.get("taskid")
    if not taskid:
        raise RuntimeError(f"No taskid in response: {payload}")
    return taskid


def poll_task(taskid: str, timeout_s: int = 120, interval_s: float = 2.0) -> dict:
    deadline = time.time() + timeout_s
    while time.time() < deadline:
        resp = requests.post(DETAIL_URL, headers=auth_headers(), data={"taskid": taskid}, timeout=30)
        resp.raise_for_status()
        payload = resp.json()
        tasklist = payload.get("tasklist") or []
        if not tasklist:
            raise RuntimeError(f"No tasklist in response: {payload}")
        task = tasklist[0]
        status = task.get("status")
        if status == TERMINAL_SUCCESS:
            return task
        if status == TERMINAL_FAILURE:
            raise RuntimeError(f"Task {taskid} was cancelled/failed: {payload}")
        time.sleep(interval_s)
    raise TimeoutError(f"Task {taskid} did not finish within {timeout_s}s")


def download_output(task: dict, out_path: Path) -> None:
    outputs = task.get("outputs") or []
    if not outputs:
        raise RuntimeError(f"Task has no outputs: {task}")
    output = outputs[0]
    url = output["url"]
    accesskey = output.get("accesskey")
    if accesskey:
        url = f"{url}?accesskey={accesskey}"
    # Wiro's CDN 403s urllib-based clients; requests works.
    resp = requests.get(url, timeout=60)
    resp.raise_for_status()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(resp.content)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--aspect-ratio", default="1:1")
    parser.add_argument("--input-image", default=None, help="URL of an image to edit (image-to-image)")
    parser.add_argument("--temperature", type=float, default=1.0)
    parser.add_argument("--safety-setting", default="BLOCK_ONLY_HIGH")
    parser.add_argument("--out", required=True, type=Path)
    parser.add_argument("--timeout", type=int, default=120)
    args = parser.parse_args()

    print(f"Submitting: {args.prompt[:80]}...", file=sys.stderr)
    taskid = submit_task(args.prompt, args.aspect_ratio, args.input_image, args.temperature, args.safety_setting)
    print(f"Task {taskid} submitted, polling...", file=sys.stderr)
    task = poll_task(taskid, timeout_s=args.timeout)
    out_path = args.out if args.out.is_absolute() else PROJECT_ROOT / args.out
    download_output(task, out_path)
    print(f"Saved: {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
