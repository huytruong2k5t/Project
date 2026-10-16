"""Pack compact, source-bound parser proof; never archive build/runtime caches."""
from pathlib import Path
import hashlib
import json
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "results/parser_xor_20261016"
EXCLUDED = {"obj_dir", "obj_fast", "tmp", ".Xil", "appdata", "localappdata", "-p", "ppa_unbanked_rejected"}
SUFFIXES = {".sv", ".vh", ".hpp", ".h", ".cpp", ".sh", ".ps1", ".tcl", ".py", ".log", ".rpt", ".txt", ".json", ".sha256", ".csv", ".dat"}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    if sys.argv[1:] == ["restore"]:
        receipt = json.loads((OUT / "archive_manifest.json").read_text())
        assert sha((OUT / "evidence.zip").read_bytes()) == receipt["archive_sha256"]
        with zipfile.ZipFile(OUT / "evidence.zip") as z:
            assert set(z.namelist()) == set(receipt["files"])
            for name, digest in receipt["files"].items():
                target = OUT / name
                assert target.resolve().is_relative_to(OUT.resolve())
                data = z.read(name)
                assert sha(data) == digest
                if target.exists():
                    assert sha(target.read_bytes()) == digest, f"Preserve different existing file: {name}"
            restored = 0
            for name in receipt["files"]:
                target = OUT / name
                if not target.exists():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_bytes(z.read(name))
                    restored += 1
        print(f"RESTORE_PASS files={restored}")
        return
    assert not sys.argv[1:], "usage: archive_parser_xor.py [restore]"
    assert json.loads((OUT / "summary.json").read_text())["status"] == "PASS"
    assert not (OUT / "evidence.zip").exists(), "Preserve existing archive"
    paths = []
    for path in OUT.rglob("*"):
        if not path.is_file() or EXCLUDED.intersection(path.relative_to(OUT).parts):
            continue
        if path.suffix not in SUFFIXES or path.name in {"archive_manifest.json"}:
            continue
        if path.parent.name == "parser_comb" and path.name.startswith("parser_") and path.suffix == ".txt":
            continue  # Rebuild using generator, pinned seed and vectors.sha256.
        paths.append(path)
    digest = {}
    with zipfile.ZipFile(OUT / "evidence.zip", "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for path in sorted(paths):
            name = path.relative_to(OUT).as_posix()
            data = path.read_bytes()
            digest[name] = sha(data)
            z.writestr(name, data)
    with zipfile.ZipFile(OUT / "evidence.zip") as z:
        assert z.testzip() is None
        assert set(z.namelist()) == set(digest)
        assert all(sha(z.read(name)) == value for name, value in digest.items())
    receipt = dict(status="PASS", archive_sha256=sha((OUT / "evidence.zip").read_bytes()),
                   bytes=(OUT / "evidence.zip").stat().st_size, files=digest,
                   note="Extract under results/parser_xor_20261016 only after checking existing files; do not overwrite differing files. Binary/cache/fixtures omitted; fixtures regenerate deterministically using gen_parser_vectors.cpp and vectors.sha256. Rejected unbanked PPA stays local and is not used in conclusions.")
    (OUT / "archive_manifest.json").write_text(json.dumps(receipt, indent=2)+"\n")
    print(f"ARCHIVE_PASS files={len(digest)} bytes={receipt['bytes']}")


if __name__ == "__main__":
    main()
