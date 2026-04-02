#!/usr/bin/env python3
from __future__ import annotations

import argparse
import fnmatch
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ALWAYS_ALLOW = {
    Path("module/system/bin/zapret"),
}
BLOCKED_GLOBS = (
    "artifacts/**",
    "flowseal-upstream.zip",
    "module/bin/**",
    "module/curl-*",
    "module/dnscrypt/dnscrypt-proxy-*",
    "module/fake/**",
    "module/system/app/*.apk",
    "module/zapret/nfqws-*",
    "zapret-magisk.zip",
)
BLOCKED_SUFFIXES = {
    ".7z",
    ".a",
    ".apk",
    ".bin",
    ".bz2",
    ".dll",
    ".dylib",
    ".exe",
    ".gz",
    ".o",
    ".obj",
    ".pyc",
    ".pyo",
    ".so",
    ".tar",
    ".xz",
    ".zip",
}


def run_git(*args: str, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        check=check,
        text=True,
        capture_output=True,
    )


def parse_status_entries() -> list[tuple[str, Path]]:
    result = subprocess.run(
        ["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"],
        cwd=ROOT,
        check=True,
        capture_output=True,
    )
    items = result.stdout.split(b"\0")
    entries: list[tuple[str, Path]] = []
    index = 0

    while index < len(items):
        item = items[index]
        if not item:
            index += 1
            continue

        status = item[:2].decode("utf-8", errors="replace")
        path_text = item[3:].decode("utf-8", errors="surrogateescape")
        index += 1

        if "R" in status or "C" in status:
            if index >= len(items) or not items[index]:
                raise RuntimeError(f"Missing rename target for status entry {status} {path_text!r}")
            path_text = items[index].decode("utf-8", errors="surrogateescape")
            index += 1

        entries.append((status, Path(path_text)))

    return entries


def is_blocked_path(path: Path) -> bool:
    if path in ALWAYS_ALLOW:
        return False

    posix_path = path.as_posix()
    if any(fnmatch.fnmatch(posix_path, pattern) for pattern in BLOCKED_GLOBS):
        return True

    return path.suffix.lower() in BLOCKED_SUFFIXES


def is_text_file(path: Path) -> bool:
    if path in ALWAYS_ALLOW:
        return True
    if is_blocked_path(path):
        return False

    data = (ROOT / path).read_bytes()
    if b"\0" in data:
        return False

    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        return False

    return True


def stage_path(path: Path, deleted: bool, dry_run: bool) -> bool:
    if is_blocked_path(path):
        return False

    if deleted:
        if not dry_run:
            run_git("add", "-u", "--", path.as_posix())
        return True

    if not (ROOT / path).is_file() or not is_text_file(path):
        return False

    if not dry_run:
        run_git("add", "--", path.as_posix())
    return True


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Stage generated repository source changes while excluding binaries and package artifacts."
    )
    parser.add_argument("--dry-run", action="store_true", help="Print stageable paths without touching the index.")
    args = parser.parse_args()

    staged_paths: list[str] = []
    for status, path in parse_status_entries():
        deleted = "D" in status
        if stage_path(path, deleted=deleted, dry_run=args.dry_run):
            staged_paths.append(path.as_posix())

    if staged_paths:
        for path in staged_paths:
            print(path)
    else:
        print("No stageable generated source changes found.")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
