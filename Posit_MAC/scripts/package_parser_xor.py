"""Copy only this session's reviewable changes into the existing Git backup."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
BACKUP = ROOT / "scratch/github_week9_backup"
OUT = ROOT / "results/parser_xor_20261016"


def git(*args):
    return subprocess.run(["git", *args], cwd=BACKUP, check=True, capture_output=True).stdout


def main():
    assert Path(git("rev-parse", "--show-toplevel").decode().strip()).resolve() == BACKUP.resolve()
    assert git("branch", "--show-current").decode().strip() == "main"
    assert git("remote", "get-url", "origin").decode().strip() == "https://github.com/huytruong2k5t/Project.git"
    assert not git("status", "--porcelain"), "Preserve existing changes/staging; stop"
    assert json.loads((OUT / "summary.json").read_text())["status"] == "PASS"
    archive = json.loads((OUT / "archive_manifest.json").read_text())
    assert hashlib.sha256((OUT / "evidence.zip").read_bytes()).hexdigest() == archive["archive_sha256"]
    paths = {".gitattributes", "SPEC_Posit_MAC_IP.md", "l1/PLAN.md", "rtl/README.md", "scripts/README.md",
             "docs/TIEN_DO_DO_AN.md", "docs/HUONG_DAN_CHAY_WSL_MODELSIM.md",
             "rtl/parser/posit_parser.sv", "rtl/parser/posit_parser_comb.sv"}
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT / "scripts").glob("*parser_xor*") if p.is_file())
    paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT / "tb").glob("*parser_xor*.sv"))
    paths.update(p.relative_to(ROOT).as_posix() for p in OUT.iterdir() if p.is_file() and p.suffix in {".json", ".sha256", ".zip"})
    paths.update(p.relative_to(ROOT).as_posix() for p in (OUT / "source").rglob("*") if p.is_file())
    staged = []
    for relative in sorted(paths):
        src = ROOT / relative
        assert src.is_file() and src.resolve().is_relative_to(ROOT.resolve())
        if src.suffix == ".md":
            old = subprocess.run(["git", "show", "HEAD:Posit_MAC/"+relative], cwd=BACKUP, capture_output=True).stdout
            raw = src.read_bytes().replace(b"\r\n", b"\n")
            if old.count(b"\r\n") > old.count(b"\n") // 2:
                raw = raw.replace(b"\n", b"\r\n")
            src.write_bytes(raw)
        dst = BACKUP / "Posit_MAC" / relative
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dst)
        staged.append(dst.relative_to(BACKUP).as_posix())
    text = (ROOT / "docs/TIEN_DO_DO_AN.md").read_text(encoding="utf-8")
    for name in ("SPEC_Posit_MAC_IP.md", "l1/PLAN.md", "l1/README.md"):
        text = text.replace(f"(../{name})", f"(../Posit_MAC/{name})")
    text = text.replace("(HUONG_DAN_CHAY_WSL_MODELSIM.md)", "(../Posit_MAC/docs/HUONG_DAN_CHAY_WSL_MODELSIM.md)")
    (BACKUP / "doc/TIEN_DO_DO_AN.md").write_text(text, encoding="utf-8")
    staged.append("doc/TIEN_DO_DO_AN.md")
    (ROOT / "scratch/parser_xor_git_paths.txt").write_text("\n".join(staged)+"\n")
    print(f"Prepared {len(staged)} explicit paths; no unrelated user files or build binaries")


if __name__ == "__main__":
    main()
