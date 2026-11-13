import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
CHAIN_MANIFEST = ROOT / "results" / "mac_chains_20261112" / "manifest.json"
ROUTE_MANIFEST = ROOT / "results" / "route_nf_f_20261112" / "manifest.json"
OUT_DIR = Path(__file__).resolve().parent
SRC_OUT = OUT_DIR / "source"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def main():
    m_chain = json.loads(CHAIN_MANIFEST.read_text(encoding="utf-8"))
    quire_f = (ROOT / "rtl" / "quire_active.f").read_text(encoding="utf-8").splitlines()
    rel_files = [ln.strip() for ln in quire_f if ln.strip() and not ln.strip().startswith("#")]
    extra_files = [
        "rtl/quire_active.f",
        "rtl/posit_mac.vh",
        "tb/quire_ppa_top.sv",
        "syn/constraints/a35t_clock.xdc",
        "syn/constraints/a35t_benchmark_100mhz.xdc",
    ]
    all_rel = sorted(set(rel_files + extra_files))

    sha_map = {}
    for rel in all_rel:
        src = ROOT / rel
        dst = SRC_OUT / rel
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        h_live = sha256_file(src)
        h_dst = sha256_file(dst)
        assert h_live == h_dst
        if rel in m_chain["source_sha256"]:
            assert h_live == m_chain["source_sha256"][rel], f"Chain snapshot mismatch on {rel}"
        sha_map[rel] = h_live

    (OUT_DIR / "source_sha256.json").write_text(json.dumps(sha_map, indent=2), encoding="utf-8")
    print(f"Snapshotted {len(sha_map)} files to {SRC_OUT}; all match mac_chains_20261112 SHA-256.")


if __name__ == "__main__":
    main()
