#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SOURCE_URL = "https://github.com/Flowseal/zapret-discord-youtube/archive/refs/heads/main.zip"

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

ARCHIVE_ROOT = "zapret-discord-youtube-main/"

def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return ""

def download(url: str, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=60) as response:
        dest.write_bytes(response.read())

def open_source_zip(source_zip: str, source_url: str) -> tuple[zipfile.ZipFile, tempfile.TemporaryDirectory | None, Path]:
    if source_zip:
        path = Path(source_zip).expanduser().resolve()
        if path.exists():
            return zipfile.ZipFile(path), None, path

    tempdir = tempfile.TemporaryDirectory()
    temp_path = Path(tempdir.name) / "zapret-discord-youtube-main.zip"
    download(source_url, temp_path)
    return zipfile.ZipFile(temp_path), tempdir, temp_path

def zip_rel_name(entry: str) -> str | None:
    if entry.endswith("/"):
        return None
    if not entry.startswith(ARCHIVE_ROOT):
        return None
    return entry[len(ARCHIVE_ROOT):]

def copy_zip_member(zf: zipfile.ZipFile, entry: zipfile.ZipInfo, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with zf.open(entry) as source:
        dest.write_bytes(source.read())

def strategy_name_from_bat_name(bat_name: str) -> str | None:
    stem = Path(bat_name).stem.strip()
    if not stem:
        return None
    if stem.lower() == "service":
        return None

    stem = re.sub(r"(?i)^general\s*", "", stem).strip()
    stem = stem.replace("(", "").replace(")", "")
    stem = re.sub(r"\s+", "-", stem)
    stem = re.sub(r"-{2,}", "-", stem).strip("-")
    if not stem:
        stem = "general"
    return f"{stem}.sh"

def normalize_paths(text: str) -> str:
    text = text.replace('^!', '!')
    text = text.replace('%~dp0', '$MODPATH/')
    text = re.sub(r'\s*--wf-tcp=[^\s"]+', '', text, flags=re.IGNORECASE)
    text = re.sub(r'\s*--wf-udp=[^\s"]+', '', text, flags=re.IGNORECASE)
    text = text.replace('"%BIN%winws.exe"', '$MODPATH/bin/winws.exe')
    text = text.replace('%BIN%winws.exe', '$MODPATH/bin/winws.exe')
    text = re.sub(
        r'%BIN%([^"\s]+)',
        lambda m: '$MODPATH/fake/' + m.group(1),
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r'%LISTS%([^"\s]+)',
        lambda m: '$MODPATH/lists/' + m.group(1),
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(r'"(\$MODPATH/(?:bin|fake|lists)/[^"]+)"', r'\1', text)
    return text

def convert_bat_to_sh(content: str) -> str:
    lines: list[str] = []
    current = ""
    started = False

    for raw in content.splitlines():
        line = raw.strip()
        if not line:
            continue
        lower = line.lower()
        if lower.startswith("call service.bat"):
            continue
        if lower.startswith("set "):
            continue
        if lower.startswith("start "):
            started = True
            line = re.sub(r'^start\s+"[^"]*"\s+/min\s+"[^"]*winws\.exe"\s*', "", line, flags=re.IGNORECASE)
            if not line:
                continue
        elif not started and not line.startswith("--"):
            continue

        line = line.rstrip("^").strip()
        if current:
            current += " " + line
        else:
            current = line

        if raw.rstrip().endswith("^"):
            continue

        if current:
            lines.append(current)
        current = ""

    if current:
        lines.append(current)

    config_segments: list[str] = []
    joined = " ".join(lines)
    for segment in joined.split("--new"):
        segment = segment.strip()
        if segment:
            normalized = normalize_paths(segment)
            if "--filter-tcp=%GameFilterTCP%" in normalized:
                continue
            if "--filter-udp=%GameFilterUDP%" in normalized:
                continue
            normalized = normalized.replace(",,", ",")
            normalized = normalized.replace(",%", "%")
            normalized = normalized.replace(" ,", " ")
            config_segments.append(normalized)

    output = ['# Zapret Configuration', '# >.<', '']
    if not config_segments:
        return "\n".join(output) + "\n"

    for index, segment in enumerate(config_segments):
        if index == 0:
            output.append(f'config="{segment} --new"')
        elif index == len(config_segments) - 1 and not segment.endswith("--new"):
            output.append(f'config="$config {segment}"')
        else:
            output.append(f'config="$config {segment} --new"')

    return "\n".join(output) + "\n"

def sync_from_zip(root: Path, archive: zipfile.ZipFile) -> tuple[list[str], list[str], list[str]]:
    copied: list[str] = []
    generated: list[str] = []
    missing: list[str] = []

    archive_entries = {entry.filename: entry for entry in archive.infolist()}

    for entry_name, entry in archive_entries.items():
        rel = zip_rel_name(entry_name)
        if not rel:
            continue

        path = Path(rel)
        if path.parts and path.parts[0] == ".service":
            dest = root / rel
            if not dest.exists():
                copy_zip_member(archive, entry, dest)
                copied.append(rel)
            continue

        if path.parts and path.parts[0] == "lists":
            dest = root / rel
            if not dest.exists():
                copy_zip_member(archive, entry, dest)
                copied.append(rel)
            continue

        if path.parts and path.parts[0] == "bin":
            if path.suffix.lower() == ".bin":
                dest = root / "fake" / path.name
            else:
                dest = root / "bin" / path.name
            if not dest.exists():
                copy_zip_member(archive, entry, dest)
                copied.append(str(dest.relative_to(root)).replace("\\", "/"))

    bat_entries = sorted(
        (
            entry_name,
            entry,
        )
        for entry_name, entry in archive_entries.items()
        if entry_name.startswith(ARCHIVE_ROOT) and entry_name.lower().endswith(".bat")
    )

    (root / "strategy").mkdir(parents=True, exist_ok=True)
    for entry_name, entry in bat_entries:
        bat_name = Path(entry_name).name
        target_name = strategy_name_from_bat_name(bat_name)
        if target_name is None:
            continue

        dest = root / "strategy" / target_name
        content = archive.read(entry).decode("utf-8", errors="ignore")
        dest.write_text(convert_bat_to_sh(content), encoding="utf-8")
        generated.append(str(dest.relative_to(root)).replace("\\", "/"))

    return copied, generated, missing

def package_zip(root: Path, output: Path) -> None:
    if output.exists():
        output.unlink()

    include = [
        "action.sh",
        "customize.sh",
        "general.sh",
        "make-unkillable.sh",
        "module.prop",
        "service.sh",
        "uninstall.sh",
        "update.sh",
        "zapret.sh",
        "bin",
        "dnscrypt",
        "fake",
        "ipset",
        "list",
        "lists",
        "strategy",
        "strategies",
        ".service",
        "system",
        "META-INF",
    ]

    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for rel in include:
            path = root / rel
            if path.is_dir():
                for file in sorted(path.rglob("*")):
                    if file.is_file():
                        archive.write(file, file.relative_to(root).as_posix())
            elif path.is_file():
                archive.write(path, path.relative_to(root).as_posix())
        for file in sorted(root.glob("nfqws-*")):
            if file.is_file():
                archive.write(file, file.relative_to(root).as_posix())

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=str(ROOT))
    parser.add_argument("--source-zip", default="")
    parser.add_argument("--source-url", default=DEFAULT_SOURCE_URL)
    parser.add_argument("--manifest", default="")
    parser.add_argument("--zip-out", default="")
    args = parser.parse_args()

    root = Path(args.root).resolve()
    archive, tempdir, source_path = open_source_zip(args.source_zip, args.source_url)
    try:
        copied, generated, missing = sync_from_zip(root, archive)
    finally:
        archive.close()
        if tempdir is not None:
            tempdir.cleanup()

    result = {
        "root": str(root),
        "source": str(source_path),
        "copied": copied,
        "generated": generated,
        "missing": missing,
        "manifest": [
            "action.sh",
            "customize.sh",
            "general.sh",
            "make-unkillable.sh",
            "module.prop",
            "service.sh",
            "uninstall.sh",
            "update.sh",
            "zapret.sh",
            "bin",
            "dnscrypt",
            "fake",
            "ipset",
            "list",
            "lists",
            "strategy",
            "strategies",
            ".service",
            "system",
            "META-INF",
        ],
    }

    if args.manifest:
        Path(args.manifest).write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding="utf-8")
    else:
        json.dump(result, sys.stdout, indent=2, ensure_ascii=False)
        sys.stdout.write("\n")

    if args.zip_out:
        package_zip(root, Path(args.zip_out))

    return 0 if not missing else 2

if __name__ == "__main__":
    raise SystemExit(main())
