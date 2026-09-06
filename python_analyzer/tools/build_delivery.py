#!/usr/bin/env python3
"""Build a reproducible, allowlisted offline delivery; never include personal input."""
from __future__ import annotations

import argparse
import hashlib
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TREES = ("gsm_analyzer", "tools", "tests", "docs", "mql5", "examples", "sample_reports")
FILES = ("README_CN.md", "requirements.txt", "pyproject.toml", "run.py", ".gitignore", ".gitattributes",
         "START_WINDOWS.bat", "RUN_ANALYZER.bat", "_WINDOWS_RUN.bat",
         "input/README_CN.md", "input/manifest.template.json")


def delivery_files(root=ROOT):
    paths = [root / name for name in FILES if (root / name).is_file()]
    for name in TREES:
        for path in (root / name).rglob("*"):
            if path.is_file() and "__pycache__" not in path.parts and path.suffix != ".pyc" and not path.is_symlink():
                paths.append(path)
    return sorted(paths, key=lambda path: path.relative_to(root).as_posix())


def main():
    parser = argparse.ArgumentParser(description="打包代码、公开示例与示例报告；不包含个人 input/output。")
    parser.add_argument("--output", type=Path, default=ROOT / "dist/GSM_Gold_Python_Analyzer_v1.0.0.zip")
    args = parser.parse_args()
    paths = delivery_files()
    sums = "".join(f"{hashlib.sha256(path.read_bytes()).hexdigest()}  {path.relative_to(ROOT).as_posix()}\n" for path in paths)
    checksums = ROOT / "SHA256SUMS.txt"
    checksums.write_text(sums, encoding="utf-8", newline="\n")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in [*paths, checksums]:
            info = zipfile.ZipInfo("GSM_Gold_Python_Analyzer_v1.0.0/" + path.relative_to(ROOT).as_posix(), (2026, 9, 6, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
    digest = hashlib.sha256(args.output.read_bytes()).hexdigest()
    args.output.with_suffix(".zip.sha256").write_text(f"{digest}  {args.output.name}\n", encoding="utf-8")
    print(f"交付包：{args.output.resolve()}\n文件数：{len(paths)+1}\nSHA256：{digest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
