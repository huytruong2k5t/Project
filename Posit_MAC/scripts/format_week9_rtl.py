"""Expand named associations; reject any change beyond whitespace."""
import hashlib
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
names = ("sbm_shift_comb", "sbm_accum_comb", "mul_norm_comb", "iter_ctrl",
         "sbm_accum", "mul_iter_core", "mul_iter_wrapper", "posit_mul_iter",
         "paper_ops_comb", "paper_step_comb")
proof = []
updates = []
for name in names:
    path = root / "rtl" / f"{name}.sv"
    old_raw = path.read_bytes()
    old = old_raw.decode("utf-8")
    lines = []
    for line in old.splitlines():
        indent = len(line) - len(line.lstrip())
        association_indent = " " * max(8, indent)
        line = re.sub(r",\s*(?=\.[A-Za-z_]\w*\s*\()", ",\n"+association_indent, line)
        line = re.sub(r"#\((?=\.[A-Za-z_]\w*\s*\()", "#(\n"+association_indent, line)
        line = re.sub(r"\s*<=\s*", " <= ", line)
        line = re.sub(r"\bif\(", "if (", line)
        lines.append(line)
    new = "\n".join(lines)+"\n"
    normalized_old = re.sub(r"\s", "", old)
    normalized_new = re.sub(r"\s", "", new)
    if normalized_old != normalized_new:
        raise RuntimeError(f"refuse non-whitespace edit: {name}")
    proof.append({"file": path.relative_to(root).as_posix(),
        "before_sha256": hashlib.sha256(old_raw).hexdigest(),
        "after_sha256": hashlib.sha256(new.encode()).hexdigest(),
        "whitespace_normalized_sha256": hashlib.sha256(normalized_old.encode()).hexdigest(),
        "comparison": "identical after whitespace removal"})
    updates.append((path, new))
for path, new in updates:
    # Consistent LF avoids compiler/patch noise in new RTL.
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        handle.write(new)
(root / "results/week9_implementation/formatting_equivalence.json").write_text(
    json.dumps({"scope": "named associations one per line and assignment spacing; no logic edits",
                "files": proof}, indent=2)+"\n", encoding="utf-8")
print("FORMAT PASS: ten RTL files, whitespace-only equivalence checked")
