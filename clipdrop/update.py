"""Checks GitHub Releases for a newer Clipmunk and installs it."""
import json
import os
import subprocess
import sys
import tempfile
import urllib.request

from . import __version__

# owner/repo on GitHub that hosts the releases (set up by tools/release.py).
REPO = "gilby95/Clipmunk"
ASSET = "Clipmunk-Setup.exe"
OLD_ASSETS = ("ClipDrop-Setup.exe",)     # name before the 1.6 rename
API = os.environ.get("CLIPDROP_UPDATE_API", "https://api.github.com")   # override for testing


def _ver(tag):
    parts = []
    for p in tag.lstrip("vV").split("."):
        digits = "".join(ch for ch in p if ch.isdigit())
        parts.append(int(digits or 0))
    return tuple(parts + [0] * (3 - len(parts)))


def can_update():
    return bool(REPO) and getattr(sys, "frozen", False) and os.name == "nt"


def latest():
    """Returns {'version', 'notes', 'url', 'size'} if GitHub has a newer release, else None."""
    if not REPO:
        return None
    req = urllib.request.Request(f"{API}/repos/{REPO}/releases/latest",
                                 headers={"Accept": "application/vnd.github+json",
                                          "User-Agent": f"Clipmunk/{__version__}"})
    with urllib.request.urlopen(req, timeout=15) as r:
        rel = json.load(r)
    tag = rel.get("tag_name", "")
    if _ver(tag) <= _ver(__version__):
        return None
    assets = {a.get("name"): a for a in rel.get("assets", [])}
    asset = next((assets[n] for n in (ASSET, *OLD_ASSETS) if n in assets), None)
    if not asset:
        return None
    return {"version": tag.lstrip("vV"), "notes": (rel.get("body") or "").strip(),
            "url": asset["browser_download_url"], "size": asset.get("size", 0)}


def download(info, on_progress=lambda f: None, cancel=None):
    path = os.path.join(tempfile.gettempdir(), f"Clipmunk-Setup-{info['version']}.exe")
    req = urllib.request.Request(info["url"], headers={"User-Agent": f"Clipmunk/{__version__}"})
    tmp = path + ".part"
    with urllib.request.urlopen(req, timeout=60) as r, open(tmp, "wb") as f:
        total = int(r.headers.get("Content-Length") or info.get("size") or 0)
        got = 0
        while True:
            if cancel is not None and cancel.is_set():
                raise InterruptedError()
            chunk = r.read(256 * 1024)
            if not chunk:
                break
            f.write(chunk)
            got += len(chunk)
            if total:
                on_progress(got / total)
    os.replace(tmp, path)
    return path


def run_installer(path):
    """Runs the new installer quietly; it closes this copy and reopens Clipmunk when done."""
    subprocess.Popen([path, "/SILENT", "/SUPPRESSMSGBOXES", "/NORESTART", "/CLOSEAPPLICATIONS"],
                     close_fds=True, creationflags=0x00000008)   # DETACHED_PROCESS
