"""Writes assets/clipmunk.ico from the logo drawn in code, with every size Windows asks for.

Each size is drawn separately (16 px uses the hand-placed pixel version), so the taskbar and
title-bar icons stay crisp instead of being shrunk down from 256 px.
"""
import os
import struct
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from PySide6.QtCore import QBuffer, QByteArray, QIODevice  # noqa: E402
from PySide6.QtGui import QGuiApplication  # noqa: E402

from clipdrop.ui.theme import draw_logo  # noqa: E402

SIZES = (16, 20, 24, 32, 40, 48, 64, 128, 256)

app = QGuiApplication([])
out = os.path.join(os.path.dirname(__file__), "..", "assets", "clipmunk.ico")
os.makedirs(os.path.dirname(out), exist_ok=True)

pngs = []
for size in SIZES:
    pm = draw_logo(size)
    if pm.width() != size:
        sys.exit(f"Logo came out {pm.width()} px instead of {size} px")
    data = QByteArray()
    buf = QBuffer(data)
    buf.open(QIODevice.WriteOnly)
    pm.save(buf, "PNG")
    pngs.append(bytes(data))

# ICO = 6-byte header, a 16-byte entry per image, then the PNG images themselves.
offset = 6 + 16 * len(SIZES)
header = struct.pack("<HHH", 0, 1, len(SIZES))
entries, blobs = b"", b""
for size, png in zip(SIZES, pngs):
    dim = 0 if size >= 256 else size            # 0 means 256 in the ICO format
    entries += struct.pack("<BBBBHHII", dim, dim, 0, 0, 1, 32, len(png), offset + len(blobs))
    blobs += png
with open(out, "wb") as f:
    f.write(header + entries + blobs)
print("wrote", os.path.normpath(out), f"({len(SIZES)} sizes)")
