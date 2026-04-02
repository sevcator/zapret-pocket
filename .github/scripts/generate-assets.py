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
DISCORD_MARKERS = (
    "--filter-l7=discord",
    "--hostlist-domains=discord.media",
)
DISCORD_FLAG_CHECK = 'if [ "$(cat "$MODPATH/config/bypass-calls" 2>/dev/null || echo 0)" = "1" ]; then'
IPSET_BASE_TOKEN = "--ipset-exclude=$MODPATH/list/ipset-exclude.txt"
IPSET_USER_TOKEN = "--ipset-exclude=$MODPATH/list/ipset-exclude-user.txt"
REMOVED_LIST_FILENAMES = {"custom.txt", "exclude.txt"}
CLOAKING_HEADER = """################################
#        Cloaking rules        #
################################

# Generated from upstream hosts file during packaging
"""


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
    text = text.replace("$MODPATH/fake/", "$MODPATH/zapret/")
    text = text.replace("%LISTS%ipset-exclude.txt", "$MODPATH/list/ipset-exclude.txt")
    text = text.replace("%LISTS%ipset-exclude-user.txt", "$MODPATH/list/ipset-exclude-user.txt")
    text = text.replace('--ipset-exclude="/ipset-exclude.txt"', IPSET_BASE_TOKEN)
    text = text.replace('--ipset-exclude="/ipset-exclude-user.txt"', IPSET_USER_TOKEN)
    text = text.replace("--ipset-exclude=/ipset-exclude.txt", IPSET_BASE_TOKEN)
    text = text.replace("--ipset-exclude=/ipset-exclude-user.txt", IPSET_USER_TOKEN)
    text = text.replace("--ipset-exclude=$MODPATH/list/ipset-exclude.txt", IPSET_BASE_TOKEN)
    text = text.replace("--ipset-exclude=$MODPATH/list/ipset-exclude-user.txt", IPSET_USER_TOKEN)
    text = text.replace(IPSET_BASE_TOKEN, f"{IPSET_BASE_TOKEN} {IPSET_USER_TOKEN}")
    text = dedupe_exact_token(text, IPSET_BASE_TOKEN)
    text = dedupe_exact_token(text, IPSET_USER_TOKEN)
    text = re.sub(r'(?m)^config="\s+', 'config="', text)
    text = re.sub(
        r'(--[A-Za-z0-9_-]+)="(\$MODPATH/[^"]+)"',
        lambda m: f'{m.group(1)}={m.group(2)}',
        text,
    )
    text = enable_any_protocol_for_quic(text)
    return text


def enable_any_protocol_for_quic(text: str) -> str:
    lines: list[str] = []
    for line in text.splitlines():
        if "--dpi-desync-fake-quic=" in line and "--dpi-desync-any-protocol" not in line:
            marker = " --dpi-desync-fake-quic="
            idx = line.find(marker)
            if idx != -1:
                line = f"{line[:idx]} --dpi-desync-any-protocol=1{line[idx:]}"
        lines.append(line)
    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


def dedupe_exact_token(text: str, token: str) -> str:
    if token not in text:
        return text

    lines: list[str] = []
    for line in text.splitlines():
        if token not in line:
            lines.append(line)
            continue

        pieces = re.findall(r"\s+|\S+", line)
        seen = False
        rebuilt: list[str] = []
        for piece in pieces:
            if not piece.isspace() and piece == token:
                if seen:
                    continue
                seen = True
            rebuilt.append(piece)
        lines.append("".join(rebuilt).rstrip())

    return "\n".join(lines) + ("\n" if text.endswith("\n") else "")


def segment_has_discord_markers(segment: str) -> bool:
    return any(marker in segment for marker in DISCORD_MARKERS)


def prune_legacy_paths(root: Path) -> None:
    legacy_paths = [
        root / "ipset",
        root / "strategy",
        root / "strategies",
        root / "lists",
        root / "fake",
        root / "config" / "bypass-discord",
        root / "config" / "custom-list-general-url",
        root / "config" / "custom-blocked-names-url",
        root / "config" / "custom-cloaking-rules-url",
        root / "list" / "custom.txt",
        root / "list" / "exclude.txt",
        root / ".service" / "hosts",
        root / ".service" / "version.txt",
        root / "dnscrypt" / "custom-files.sh",
        root / "dnscrypt" / "custom-blocked-names.txt",
        root / "dnscrypt" / "custom-blocked-ips.txt",
        root / "dnscrypt" / "custom-cloaking-rules.txt",
        root / "dnscrypt" / "custom-allowed-names.txt",
        root / "dnscrypt" / "custom-allowed-ips.txt",
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


def find_hosts_entry(archive: zipfile.ZipFile) -> zipfile.ZipInfo | None:
    for entry in archive.infolist():
        rel = zip_rel_name(entry.filename)
        if rel is None:
            continue
        path = Path(rel)
        if path.name == "hosts":
            return entry
    return None


def convert_hosts_to_cloaking_rules(content: str) -> str:
    seen: set[tuple[str, str]] = set()
    lines: list[str] = [line.rstrip() for line in CLOAKING_HEADER.strip().splitlines()]

    for raw in content.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue

        tokens = line.split()
        if len(tokens) < 2:
            continue

        ip = tokens[0]
        for domain in tokens[1:]:
            if domain.startswith("#"):
                break
            normalized_domain = domain[1:] if domain.startswith("=") else domain
            pair = (normalized_domain, ip)
            if pair in seen:
                continue
            seen.add(pair)
            lines.append(f"={normalized_domain} {ip}")

    return "\n".join(lines) + "\n"


def write_cloaking_rules_from_hosts(root: Path, archive: zipfile.ZipFile) -> None:
    entry = find_hosts_entry(archive)
    if entry is None:
        return

    content = archive.read(entry).decode("utf-8", errors="ignore")
    dest = root / "dnscrypt" / "cloaking-rules.txt"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(convert_hosts_to_cloaking_rules(content), encoding="utf-8")


def normalize_paths(text: str) -> str:
    text = text.replace("^!", "!")
    text = text.replace("%~dp0", "$MODPATH/")
    text = re.sub(r'\s*--wf-tcp=[^\s"]+', "", text, flags=re.IGNORECASE)
    text = re.sub(r'\s*--wf-udp=[^\s"]+', "", text, flags=re.IGNORECASE)
    text = text.replace('"%BIN%winws.exe"', "")
    text = text.replace("%BIN%winws.exe", "")
    text = re.sub(
        r'%BIN%([^"\s]+)',
        lambda m: "$MODPATH/zapret/" + m.group(1),
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


def convert_bat_to_sh(content: str) -> str | None:
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

    if not any(segment_has_discord_markers(segment) for segment in config_segments):
        return None

    output = ["# Zapret Configuration", "# >.<", ""]
    emitted_config = False
    discord_block_open = False

    for segment in config_segments:
        is_discord = segment_has_discord_markers(segment)

        if is_discord and not discord_block_open:
            output.append(DISCORD_FLAG_CHECK)
            discord_block_open = True
        elif not is_discord and discord_block_open:
            output.append("fi")
            discord_block_open = False

        prefix = 'config="' if not emitted_config else 'config="$config '
        indent = "    " if is_discord else ""
        segment = re.sub(
            r'(--[A-Za-z0-9_-]+)="(\$MODPATH/[^"]+)"',
            lambda m: f'{m.group(1)}={m.group(2)}',
            segment,
        )
        output.append(f'{indent}{prefix}{segment} --new"')
        emitted_config = True

    if discord_block_open:
        output.append("fi")

    return "\n".join(output) + "\n"


def stage_repo(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    prune_legacy_paths(root)

    for path in ROOT.glob("*.sh"):
        copy_tree(path, root / path.name)

    module_prop = ROOT / "module.prop"
    if module_prop.exists():
        copy_tree(module_prop, root / "module.prop")

    for name in ("system", "list"):
        src = ROOT / name
        if src.exists():
            copy_tree(src, root / name)

    fake_root = ROOT / "fake"
    if fake_root.exists():
        for path in fake_root.glob("*.bin"):
            copy_tree(path, root / "zapret" / path.name)

    ipset_root = root / "ipset"
    ipset_root.mkdir(parents=True, exist_ok=True)
    for name in ("ipset-exclude.txt", "ipset-exclude-user.txt"):
        src = ROOT / "list" / name
        if src.exists():
            copy_tree(src, ipset_root / name)

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
            if path.name in REMOVED_LIST_FILENAMES:
                continue
            copy_zip_member(archive, entry, root / "list" / Path(*path.parts[1:]))
        elif path.parts and path.parts[0] == "bin" and path.suffix.lower() == ".bin":
            copy_zip_member(archive, entry, root / "zapret" / Path(*path.parts[1:]))
        elif path.parts and path.parts[0] == "fake":
            copy_zip_member(archive, entry, root / "zapret" / Path(*path.parts[1:]))

    root.joinpath("zapret").mkdir(parents=True, exist_ok=True)
    for entry_name, entry in sorted(archive_entries.items()):
        if not entry_name.startswith(ARCHIVE_ROOT) or not entry_name.lower().endswith(".bat"):
            continue

        target_name = strategy_name_from_bat_name(Path(entry_name).name)
        if target_name is None:
            continue

        dest = root / "zapret" / target_name
        content = archive.read(entry).decode("utf-8", errors="ignore")
        converted = convert_bat_to_sh(content)
        if converted is None:
            if dest.exists():
                dest.unlink()
            continue
        dest.write_text(normalize_strategy_script(converted), encoding="utf-8")

    write_cloaking_rules_from_hosts(root, archive)


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
