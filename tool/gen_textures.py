#!/usr/bin/env python3
"""Generates the tileable overlay textures in assets/textures/.

Each texture is white-or-black with varying alpha, so it can be drawn over
any base colour (light or dark theme) and only lightens/darkens it.
Seeded, so the output is reproducible: python3 tool/gen_textures.py
"""
import os
import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), '..', 'assets', 'textures')
rng = np.random.default_rng(7)


def blur_wrap(a, sx, sy):
    """Box-ish blur that wraps, so the result tiles."""
    out = a.copy()
    for ax, s in ((1, sx), (0, sy)):
        if s <= 0:
            continue
        acc = np.zeros_like(out)
        for k in range(-s, s + 1):
            acc += np.roll(out, k, axis=ax)
        out = acc / (2 * s + 1)
    return out


def norm(a):
    a = a - a.mean()
    return a / (np.abs(a).max() + 1e-9)


def save(name, signal, strength):
    """signal in [-1, 1]; positive lightens (white), negative darkens."""
    alpha = np.clip(np.abs(signal) * strength, 0, 255).astype(np.uint8)
    rgb = np.where(signal[..., None] >= 0, 255, 0).astype(np.uint8)
    rgb = np.repeat(rgb[..., :1], 3, axis=2)
    img = np.dstack([rgb, alpha])
    Image.fromarray(img, 'RGBA').save(
        os.path.join(OUT, name), optimize=True)


def paper(n=192):
    fine = norm(rng.standard_normal((n, n)))
    fibre = norm(blur_wrap(rng.standard_normal((n, n)), 2, 2))
    save('paper.png', norm(0.7 * fine + 0.6 * fibre), 11)


for f in (paper,):
    f()
for name in sorted(os.listdir(OUT)):
    print(name, os.path.getsize(os.path.join(OUT, name)) // 1024, 'KB')
