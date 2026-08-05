"""Rotating pool of synthetic baby descriptions for catalog art (category covers + style
previews) so consecutive images in the grid don't show the same baby. Pure text-to-image —
no reference photo — so there's no real child's likeness involved.

Round-robin an index through IDENTITIES to assign one per generation; adjacent indices always
differ, and with 10 identities a 2-column grid never repeats one on the same row.
"""
import re

IDENTITIES = [
    "a baby girl with wispy light-blonde hair and bright blue eyes",
    "a baby boy with a full head of dark curly hair and warm brown eyes",
    "a baby girl with a light-brown skin tone and soft black hair",
    "a baby boy with fair skin, red-blonde hair and green eyes",
    "a baby girl with a deep brown skin tone and a small tuft of black hair",
    "a baby boy with an olive skin tone and short dark hair",
    "a baby girl with pale skin and fine light-brown hair",
    "a baby boy with a medium-brown skin tone and dark hair",
    "a baby girl with red hair and freckled fair skin",
    "a baby boy with black hair and East Asian features",
]

_SLEEP_KEYWORDS = re.compile(r"sleep|nap|dozing|slumber|resting|curled", re.I)


def identity_for(index: int) -> str:
    return IDENTITIES[index % len(IDENTITIES)]


def eyes_state_for(descriptor: str) -> str:
    if _SLEEP_KEYWORDS.search(descriptor or ""):
        return "eyes gently closed in a peaceful sleeping expression"
    return "eyes open, calm and alert, looking softly toward the camera"
