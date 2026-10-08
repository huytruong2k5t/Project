"""Copy a source/evidence snapshot into an existing isolated Git checkout.

Never deletes files, copies repositories/build products or alters Git config.
Git staging, diff review, commit and push remain explicit separate steps.
"""
import hashlib
import json
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
checkout = root / "scratch/github_week9_backup"
if not (checkout / ".git").is_dir() or not (checkout / "Posit_MAC").is_dir():
    raise RuntimeError("expected an existing Project checkout with Posit_MAC layout")
suffixes = {".sv", ".vh", ".v", ".cpp", ".c", ".h", ".hpp", ".py", ".ps1", ".sh",
            ".md", ".tcl", ".sdc", ".json", ".csv", ".sha256", ".log", ".rpt", ".pdf", ".pptx"}
excluded = {"work", "db", "incremental_db", "output_files", "obj_dir", "tmp", "__pycache__",
            ".git", "xsim.dir", ".Xil", "node_modules"}
copied = []
def copy(source, destination):
    if not destination.resolve().is_relative_to(checkout.resolve()):
        raise RuntimeError("destination escaped checkout")
    destination.parent.mkdir(parents=True, exist_ok=True)
    data = source.read_bytes()
    if destination.exists() and destination.read_bytes() == data:
        return
    shutil.copyfile(source, destination)
    copied.append({"path": destination.relative_to(checkout).as_posix(),
                   "sha256": hashlib.sha256(data).hexdigest(), "bytes": len(data)})

directories = ("rtl", "tb", "scripts", "docs", "l1", "l0", "tests", "syn", "asic", "results")
for directory in directories:
    for source in (root / directory).rglob("*"):
        if not source.is_file() or not source.resolve().is_relative_to(root.resolve()):
            continue
        relative = source.relative_to(root)
        if any(part in excluded for part in relative.parts):
            continue
        if source.suffix.lower() not in suffixes and source.name not in {"Makefile", "CMakeLists.txt"}:
            continue
        if source.stat().st_size > 5*1024*1024 and source.suffix.lower() not in {".pdf", ".pptx"}:
            continue
        copy(source, checkout / "Posit_MAC" / relative)
for source in root.iterdir():
    if source.is_file() and (source.suffix.lower() in {".md", ".pdf"} or source.name == "Makefile"):
        copy(source, checkout / "Posit_MAC" / source.name)

# Preserve publication rules already present on GitHub, append only new rules.
ignore_path = checkout / "Posit_MAC/.gitignore"
existing = ignore_path.read_text(encoding="utf-8-sig")
local = (root / ".gitignore").read_text(encoding="utf-8-sig")
rules = local[local.index("# Week9 reproducible fixtures/build products:"):]
for line in rules.splitlines():
    if line and line not in existing.splitlines():
        existing += "\n" + line
ignore_path.write_text(existing.rstrip()+"\n", encoding="utf-8")
copy(root.parent / "doc/TIEN_DO_DO_AN.md", checkout / "doc/TIEN_DO_DO_AN.md")
manifest_path = root / "results/week9_implementation/backup_snapshot_manifest.json"
manifest_path.write_text(json.dumps({"checkout": checkout.as_posix(), "files_updated": copied,
                                  "scope": "source and small verification evidence; no fixtures/binaries/secrets/config"},
                                 indent=2, ensure_ascii=False)+"\n", encoding="utf-8")
print(f"Prepared isolated Git snapshot: {len(copied)} files updated, no deletion")
