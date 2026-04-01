#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
MODULE_DIR = ROOT / "module"
BLOCKED_NAMES = {
    "dnscrypt-proxy-arm",
    "dnscrypt-proxy-arm64",
    "dnscrypt-proxy-i386",
    "dnscrypt-proxy-x86_64",
}
BLOCKED_EXTENSIONS = {".apk", ".bin", ".dll", ".exe", ".so", ".sys"}


def tracked_module_files() -> list[Path]:
    result = subprocess.run(
        ["git", "ls-files", "module"],
        cwd=ROOT,
        check=True,
        capture_output=True,
        text=True,
    )
    return [ROOT / line for line in result.stdout.splitlines() if line.strip()]


def is_binary(path: Path) -> bool:
    data = path.read_bytes()
    if b"\x00" in data:
        return True
    try:
        data.decode("utf-8")
    except UnicodeDecodeError:
        return True
    return False


def main() -> int:
    violations: list[str] = []

    for path in tracked_module_files():
        rel = path.relative_to(ROOT)
        if rel.name in BLOCKED_NAMES or rel.suffix.lower() in BLOCKED_EXTENSIONS:
            violations.append(str(rel))
            continue
        if path.is_file() and is_binary(path):
            violations.append(str(rel))

    if violations:
        print("Blocked binary files found in tracked module sources:", file=sys.stderr)
        for violation in violations:
            print(f" - {violation}", file=sys.stderr)
        return 1

    print("Module source tree contains no tracked binaries.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
