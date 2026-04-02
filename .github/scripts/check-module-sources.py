#!/usr/bin/env python3
from __future__ import annotations

import subprocess
import sys
from pathlib import Path


BLOCKED_NAMES = {
    "curl-arm",
    "curl-aarch64",
    "curl-x86",
    "curl-x86_64",
    "dnscrypt-proxy-arm",
    "dnscrypt-proxy-arm64",
    "dnscrypt-proxy-i386",
    "dnscrypt-proxy-x86_64",
    "nfqws-arm",
    "nfqws-aarch64",
    "nfqws-x86",
    "nfqws-x86_x64",
}
BLOCKED_EXTENSIONS = {".apk", ".bin", ".dll", ".exe", ".so", ".sys"}
BLOCKED_SIGNATURES = {
    b"\x7fELF": "ELF executable",
    b"PK\x03\x04": "ZIP/APK archive",
    b"MZ": "PE executable",
}


def tracked_module_files() -> list[str]:
    result = subprocess.run(
        ["git", "ls-files", "module"],
        check=True,
        capture_output=True,
        text=True,
    )
    return [line.strip() for line in result.stdout.splitlines() if line.strip()]


def read_git_blob(path: str) -> bytes:
    return subprocess.run(
        ["git", "show", f"HEAD:{path}"],
        check=True,
        capture_output=True,
    ).stdout


def main() -> int:
    violations: list[tuple[str, str]] = []

    for rel in tracked_module_files():
        path = Path(rel)

        if path.name in BLOCKED_NAMES:
            violations.append((rel, "blocked filename"))
            continue

        if path.suffix.lower() in BLOCKED_EXTENSIONS:
            violations.append((rel, f"blocked extension {path.suffix.lower()}"))
            continue

        blob = read_git_blob(rel)

        for signature, description in BLOCKED_SIGNATURES.items():
            if blob.startswith(signature):
                violations.append((rel, description))
                break
        else:
            if b"\x00" in blob:
                violations.append((rel, "contains NUL bytes"))
                continue

            try:
                blob.decode("utf-8")
            except UnicodeDecodeError:
                violations.append((rel, "not valid UTF-8 text"))

    if violations:
        print("Blocked files found in tracked module sources:", file=sys.stderr)
        for rel, reason in violations:
            print(f" - {rel}: {reason}", file=sys.stderr)
        return 1

    print("Module source tree contains no tracked binaries.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
