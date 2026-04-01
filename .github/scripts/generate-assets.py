#!/usr/bin/env python3
from __future__ import annotations

import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SOURCE_ZIP = ROOT / "flowseal-upstream.zip"
ARCHIVE_ROOT = "zapret-discord-youtube-main/"
MODULE_ROOT = ROOT / "module"


def copy_tree(src: Path, dest: Path) -> None:
    if src.is_dir():
        shutil.copytree(src, dest, dirs_exist_ok=True)
    elif src.is_file():
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dest)


def copy_glob(src_dir: Path, dest_dir: Path, patterns: tuple[str, ...]) -> None:
    for pattern in patterns:
        for path in src_dir.glob(pattern):
            if path.is_file():
                copy_tree(path, dest_dir / path.name)


def normalize_strategy_script(text: str) -> str:
    text = text.replace("ipset-exclude-user.txt", "ipset-exclude.txt")
    text = re.sub(r'(?m)^config="\s+', 'config="', text)
    text = re.sub(
        r'(--[A-Za-z0-9_-]+)="(\$MODPATH/[^"]+)"',
        lambda m: f'{m.group(1)}={m.group(2)}',
        text,
    )
    return text


def prune_legacy_paths(root: Path) -> None:
    legacy_paths = [
        root / "ipset",
        root / "strategy",
        root / "strategies",
        root / "lists",
        root / "list" / "custom.txt",
        root / "list" / "exclude.txt",
        root / "list" / "ipset-exclude-user.txt",
        root / ".service" / "hosts",
        root / ".service" / "version.txt",
        root / "dnscrypt" / "custom-files.sh",
        root / "dnscrypt" / "custom-blocked-names.txt",
        root / "dnscrypt" / "custom-blocked-ips.txt",
        root / "dnscrypt" / "custom-cloaking-rules.txt",
    ]
    for path in legacy_paths:
        if path.is_dir():
            shutil.rmtree(path, ignore_errors=True)
        elif path.exists():
            path.unlink()


def zip_rel_name(entry: str) -> str | None:
    if entry.endswith("/"):
        return None
    if not entry.startswith(ARCHIVE_ROOT):
        return None
    return entry[len(ARCHIVE_ROOT):]


def strategy_name_from_bat_name(bat_name: str) -> str | None:
    stem = Path(bat_name).stem.strip()
    if not stem or stem.lower() == "service":
        return None

    stem = re.sub(r"(?i)^general\s*", "", stem).strip()
    stem = stem.replace("(", "").replace(")", "")
    stem = re.sub(r"\s+", "-", stem)
    stem = re.sub(r"-{2,}", "-", stem).strip("-")
    return f"{stem or 'general'}.sh"


def normalize_paths(text: str) -> str:
    text = text.replace("^!", "!")
    text = text.replace("%~dp0", "$MODPATH/")
    text = re.sub(r'\s*--wf-tcp=[^\s"]+', "", text, flags=re.IGNORECASE)
    text = re.sub(r'\s*--wf-udp=[^\s"]+', "", text, flags=re.IGNORECASE)
    text = text.replace('"%BIN%winws.exe"', "")
    text = text.replace("%BIN%winws.exe", "")
    text = re.sub(
        r'%BIN%([^"\s]+)',
        lambda m: "$MODPATH/fake/" + m.group(1),
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r'%LISTS%([^"\s]+)',
        lambda m: "$MODPATH/list/" + m.group(1),
        text,
        flags=re.IGNORECASE,
    )
    text = text.replace("$MODPATH/lists/", "$MODPATH/list/")
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
        if lower.startswith("call service.bat") or lower.startswith("set "):
            continue
        if lower.startswith("start "):
            started = True
            line = re.sub(r'^start\s+"[^"]*"\s+/min\s+"[^"]*winws\.exe"\s*', "", line, flags=re.IGNORECASE)
            if not line:
                continue
        elif not started and not line.startswith("--"):
            continue

        line = line.rstrip("^").strip()
        current = f"{current} {line}".strip() if current else line

        if raw.rstrip().endswith("^"):
            continue

        lines.append(current)
        current = ""

    if current:
        lines.append(current)

    config_segments: list[str] = []
    for segment in " ".join(lines).split("--new"):
        segment = segment.strip()
        if not segment:
            continue
        normalized = normalize_paths(segment)
        if "--filter-tcp=%GameFilterTCP%" in normalized:
            continue
        if "--filter-udp=%GameFilterUDP%" in normalized:
            continue
        normalized = normalized.replace(",,", ",").replace(",%", "%").replace(" ,", " ")
        config_segments.append(normalized)

    output = ["# Zapret Configuration", "# >.<", ""]
    for index, segment in enumerate(config_segments):
        segment = re.sub(
            r'(--[A-Za-z0-9_-]+)="(\$MODPATH/[^"]+)"',
            lambda m: f'{m.group(1)}={m.group(2)}',
            segment,
        )
        if index == 0:
            output.append(f'config="{segment} --new"')
        elif index == len(config_segments) - 1 and not segment.endswith("--new"):
            output.append(f'config="$config {segment}"')
        else:
            output.append(f'config="$config {segment} --new"')

    return "\n".join(output) + "\n"


def stage_repo(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    prune_legacy_paths(root)

    for path in ROOT.glob("*.sh"):
        copy_tree(path, root / path.name)

    module_prop = ROOT / "module.prop"
    if module_prop.exists():
        copy_tree(module_prop, root / "module.prop")

    for name in ("system", "fake", "list"):
        src = ROOT / name
        if src.exists():
            copy_tree(src, root / name)

    zapret_src = ROOT / "zapret"
    if zapret_src.exists():
        for path in zapret_src.glob("*.sh"):
            if path.is_file():
                dest = root / "zapret" / path.name
                dest.parent.mkdir(parents=True, exist_ok=True)
                dest.write_text(normalize_strategy_script(path.read_text(encoding="utf-8", errors="ignore")), encoding="utf-8")

    dnscrypt_src = ROOT / "dnscrypt"
    if dnscrypt_src.exists():
        copy_glob(dnscrypt_src, root / "dnscrypt", ("*.sh", "*.txt", "*.toml"))

    service_src = ROOT / ".service" / "ipset-service.txt"
    if service_src.exists():
        copy_tree(service_src, root / ".service" / "ipset-service.txt")


def sync_from_zip(root: Path, archive: zipfile.ZipFile) -> None:
    archive_entries = {entry.filename: entry for entry in archive.infolist()}

    for entry_name, entry in archive_entries.items():
        rel = zip_rel_name(entry_name)
        if not rel:
            continue

        path = Path(rel)
        if path.parts and path.parts[0] == ".service" and path.name == "ipset-service.txt":
            copy_zip_member(archive, entry, root / rel)
        elif path.parts and path.parts[0] in {"lists", "list"}:
            copy_zip_member(archive, entry, root / "list" / Path(*path.parts[1:]))
        elif path.parts and path.parts[0] == "fake":
            copy_zip_member(archive, entry, root / "fake" / Path(*path.parts[1:]))

    root.joinpath("zapret").mkdir(parents=True, exist_ok=True)
    for entry_name, entry in sorted(archive_entries.items()):
        if not entry_name.startswith(ARCHIVE_ROOT) or not entry_name.lower().endswith(".bat"):
            continue

        target_name = strategy_name_from_bat_name(Path(entry_name).name)
        if target_name is None:
            continue

        dest = root / "zapret" / target_name
        content = archive.read(entry).decode("utf-8", errors="ignore")
        dest.write_text(normalize_strategy_script(convert_bat_to_sh(content)), encoding="utf-8")


def copy_zip_member(zf: zipfile.ZipFile, entry: zipfile.ZipInfo, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    with zf.open(entry) as source:
        dest.write_bytes(source.read())


def main() -> int:
    if not SOURCE_ZIP.exists():
        raise FileNotFoundError(SOURCE_ZIP)

    stage_repo(MODULE_ROOT)
    with zipfile.ZipFile(SOURCE_ZIP) as archive:
        sync_from_zip(MODULE_ROOT, archive)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
