#!/usr/bin/env python3
from __future__ import annotations

import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE_ZIP = ROOT / "flowseal-upstream.zip"

ARCHIVE_ROOT = "zapret-discord-youtube-main/"

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
    text = text.replace('"%BIN%winws.exe"', '')
    text = text.replace('%BIN%winws.exe', '')
    text = re.sub(
        r'%BIN%([^"\s]+)',
        lambda m: '$MODPATH/fake/' + m.group(1),
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r'%LISTS%([^"\s]+)',
        lambda m: '$MODPATH/list/' + m.group(1),
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(r'"(\$MODPATH/(?:bin|fake|list)/[^"]+)"', r'\1', text)
    text = text.replace('$MODPATH/lists/', '$MODPATH/list/')
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

def sync_from_zip(root: Path, archive: zipfile.ZipFile) -> None:
    archive_entries = {entry.filename: entry for entry in archive.infolist()}

    for entry_name, entry in archive_entries.items():
        rel = zip_rel_name(entry_name)
        if not rel:
            continue

        path = Path(rel)
        if path.parts and path.parts[0] == ".service":
            dest = root / rel
            copy_zip_member(archive, entry, dest)
            continue

        if path.parts and path.parts[0] in {"lists", "list"}:
            dest = root / "list" / Path(*path.parts[1:])
            copy_zip_member(archive, entry, dest)
            continue

        if path.parts and path.parts[0] == "fake":
            dest = root / "fake" / Path(*path.parts[1:])
            copy_zip_member(archive, entry, dest)
            continue

        if path.parts and path.parts[0] == "bin":
            if path.suffix.lower() == ".bin":
                dest = root / "fake" / path.name
            else:
                continue
            copy_zip_member(archive, entry, dest)

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

def main() -> int:
    if not SOURCE_ZIP.exists():
        raise FileNotFoundError(SOURCE_ZIP)

    root = ROOT / "module"
    with zipfile.ZipFile(SOURCE_ZIP) as archive:
        sync_from_zip(root, archive)

    return 0

if __name__ == "__main__":
    raise SystemExit(main())
