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


def linen(n=192):
    # Woven cloth: horizontal and vertical threads with slub noise.
    y, x = np.mgrid[0:n, 0:n]
    warp = blur_wrap(rng.standard_normal((n, n)), 0, 0)
    h = blur_wrap(rng.standard_normal((n, n)), 6, 0)   # long horizontal fibres
    v = blur_wrap(rng.standard_normal((n, n)), 0, 6)   # long vertical fibres
    weave = np.sin(x * 2 * np.pi / 4) * np.sin(y * 2 * np.pi / 4)
    s = 0.55 * norm(h) + 0.55 * norm(v) + 0.35 * weave + 0.15 * norm(warp)
    save('linen.png', norm(s), 44)


def paper(n=192):
    fine = norm(rng.standard_normal((n, n)))
    fibre = norm(blur_wrap(rng.standard_normal((n, n)), 2, 2))
    save('paper.png', norm(0.7 * fine + 0.6 * fibre), 15)


def metal(w=256, h=96):
    # Brushed metal: very long horizontal streaks.
    base = rng.standard_normal((h, w))
    s = blur_wrap(base, 40, 0)
    s2 = blur_wrap(rng.standard_normal((h, w)), 12, 0)
    save('metal.png', norm(0.8 * norm(s) + 0.5 * norm(s2)), 60)


def leather(n=192):
    # Fine pebbled grain: small raised bumps with darker creases between.
    a = blur_wrap(rng.standard_normal((n, n)), 1, 1)
    b = blur_wrap(rng.standard_normal((n, n)), 3, 3)
    s = norm(a) - 0.5 * norm(b)
    bumps = np.tanh(2.2 * norm(s))
    save('leather.png', norm(bumps), 34)


for f in (linen, paper, metal, leather):
    f()
for name in sorted(os.listdir(OUT)):
    print(name, os.path.getsize(os.path.join(OUT, name)) // 1024, 'KB')
