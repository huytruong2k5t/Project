"""Review Note.docx identities without compiling or changing any RTL.

This checks binary arithmetic models, not HDL elaboration, X/Z equivalence,
formal equivalence, synthesis or timing. Candidate equations follow the note;
independent oracles use a linear scan and per-bit source indexing.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import platform
import random
from xml.etree import ElementTree as ET
from zipfile import ZipFile


ROOT = Path(__file__).resolve().parents[1]
SEED = 20261015
W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
M_NS = "http://schemas.openxmlformats.org/officeDocument/2006/math"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def note_metadata(path: Path) -> dict:
    with ZipFile(path) as archive:
        root = ET.fromstring(archive.read("word/document.xml"))
        paragraphs = root.findall(f".//{{{W_NS}}}p")
        modules: dict[str, str] = {}
        active: list[str] = []
        for paragraph in paragraphs:
            line = "".join(t.text or "" for t in paragraph.findall(f".//{{{W_NS}}}t"))
            line = line.strip()
            if line.startswith("module "):
                active = [line]
            elif active:
                active.append(line)
            if active and line == "endmodule":
                name = active[0].split()[1].split("#")[0]
                modules[name] = hashlib.sha256("\n".join(active).encode()).hexdigest()
                active = []
        if set(modules) != {"lod_lzd_core", "dyn_left_shifter"}:
            raise AssertionError(f"Unexpected reference modules: {sorted(modules)}")
        return {
            "file": path.name,
            "sha256": sha(path),
            "paragraphs": len(paragraphs),
            "native_equations": len(root.findall(f".//{{{M_NS}}}oMath")),
            "media": sum(n.startswith("word/media/") for n in archive.namelist()),
            "reference_module_text_sha256": modules,
        }


def patterns(n: int, exhaustive_limit: int, rng: random.Random) -> list[int]:
    if n <= exhaustive_limit:
        return list(range(1 << n))
    mask = (1 << n) - 1
    values = {0, mask, int("10" * n, 2) & mask, int("01" * n, 2) & mask}
    for bit in range(n):
        values.update((1 << bit, mask ^ (1 << bit)))
    values.update(rng.getrandbits(n) for _ in range(128))
    return sorted(values)


def detector_tree(value: int, n: int, s: int, mode: int, candidate: bool) -> tuple[int, bool]:
    norm = value ^ (((1 << n) - 1) if mode else 0)
    padded = norm << ((1 << s) - n)
    nodes = [((padded >> bit) & 1, 0) for bit in range(1 << s)]
    for level in range(s):
        merged = []
        for index in range(0, len(nodes), 2):
            vl, pl = nodes[index]
            vh, ph = nodes[index + 1]
            if candidate:
                pos = ((ph if vh else pl) & ((1 << level) - 1))
                pos |= int(not vh and vl) << level
            else:
                pos = ph if vh else pl | (1 << level)
            merged.append((vh | vl, pos))
        nodes = merged
    valid, pos = nodes[0]
    return (pos if candidate or valid else 0), bool(valid)


def detector_oracle(value: int, n: int, mode: int) -> tuple[int, bool]:
    for count in range(n):
        if ((value >> (n - 1 - count)) & 1) != mode:
            return count, True
    return 0, False


def check_lod(rng: random.Random) -> dict:
    cases = 0
    widths = list(range(2, 13)) + [13, 16, 26, 27, 29, 30, 31, 32, 33, 53, 54, 64]
    for n in widths:
        for value in patterns(n, 12, rng):
            for s in ((n - 1).bit_length(), (n - 1).bit_length() + 1):
                for mode in (0, 1):
                    expected = detector_oracle(value, n, mode)
                    old = detector_tree(value, n, s, mode, False)
                    new = detector_tree(value, n, s, mode, True)
                    if old != expected or new != expected:
                        raise AssertionError(("LOD", n, s, mode, value, old, new, expected))
                    cases += 1
    return {"cases": cases, "mismatches": 0, "N": widths,
            "exhaustive_input_N": "2..12, both MODEs, S=min and min+1",
            "larger_N": "directed and seeded samples; not exhaustive"}


def shift_cascade(value: int, n: int, width: int, amount: int,
                  right: bool, fill: int, candidate: bool, reverse: bool = False) -> int:
    if n == 1:
        return fill if amount else value
    s = (n - 1).bit_length()
    mask = (1 << n) - 1
    levels = min(s, width) if candidate else s
    for bit in (reversed(range(levels)) if reverse else range(levels)):
        if bit < width and (amount >> bit) & 1:
            distance = 1 << bit
            if right:
                value = (value >> distance) | (((1 << distance) - 1) << (n - distance) if fill else 0)
            else:
                value = (value << distance) & mask
    overflow = bool(amount >> s) if candidate else amount >= n
    return (mask if fill else 0) if overflow else value


def shift_oracle(value: int, n: int, amount: int, right: bool, fill: int) -> int:
    result = 0
    for bit in range(n):
        source = bit + amount if right else bit - amount
        digit = ((value >> source) & 1) if 0 <= source < n else fill
        result |= digit << bit
    return result


def check_shifters(rng: random.Random) -> dict:
    cases = 0
    widths = list(range(1, 13)) + [16, 26, 27, 29, 30, 31, 32, 33, 53, 54, 64]
    for n in widths:
        s = max(1, (n - 1).bit_length())
        for width in sorted({max(1, s - 1), s, s + 1}):
            for value in patterns(n, 8, rng):
                for amount in range(1 << width):
                    for right, fill in ((False, 0), (True, 0), (True, 1), (True, value >> (n - 1))):
                        expected = shift_oracle(value, n, amount, right, fill)
                        old = shift_cascade(value, n, width, amount, right, fill, False)
                        new = shift_cascade(value, n, width, amount, right, fill, True)
                        descending = shift_cascade(value, n, width, amount, right, fill, True, True)
                        if old != expected or new != expected or descending != expected:
                            raise AssertionError(("SHIFT", n, width, value, amount, right, fill))
                        cases += 1
    return {"cases": cases, "mismatches": 0, "N": widths,
            "SHIFT_W": "min-1 (at least1), min, min+1; every encoded shift",
            "data": "all data for N<=8, directed/seeded samples otherwise",
            "modes": ["left zero fill", "right zero fill", "right fill1", "right original-sign fill"],
            "stage_orders": ["ascending", "descending"],
            "right_shift_scope": "derived extension of the left-shift proposal; no right-shift reference RTL in the note"}


def parser_fields(raw: int, nb: int, es: int, style: str) -> tuple[int, bool, bool, int, int]:
    sign = raw >> (nb - 1)
    zero, nar = raw == 0, raw == 1 << (nb - 1)
    if zero or nar:
        return sign, zero, nar, 0, 0
    magnitude = ((-raw) if sign else raw) & ((1 << nb) - 1)
    rc = (magnitude >> (nb - 2)) & 1
    tail_width = nb - 2
    tail = magnitude & ((1 << tail_width) - 1)
    if style == "current_scan":
        count = 0
        for bit in reversed(range(tail_width)):
            if ((tail >> bit) & 1) != rc:
                break
            count += 1
    else:
        detect_width = nb - 1 if style == "naive_full_vector" else nb - 2
        normalized = (magnitude & ((1 << detect_width) - 1)) ^ (((1 << detect_width) - 1) if rc else 0)
        count, valid = detector_oracle(normalized, detect_width, 0)
        if not valid:
            count = nb - 2
    regime = count if rc else -(count + 1)
    payload = ((magnitude & ((1 << (nb - 3)) - 1)) << count) & ((1 << (nb - 3)) - 1)
    f = nb - 3 - es
    exponent = payload >> f
    fraction = payload & ((1 << f) - 1)
    return sign, False, False, regime * (1 << es) + exponent, fraction


def check_parser(rng: random.Random) -> dict:
    cases, naive_differences = 0, 0
    for nb, es in ((8, 0), (16, 1), (32, 2), (32, 3)):
        for raw in patterns(nb, 16, rng):
            expected = parser_fields(raw, nb, es, "current_scan")
            corrected = parser_fields(raw, nb, es, "corrected_tail_xor")
            if corrected != expected:
                raise AssertionError(("PARSER", nb, es, raw, corrected, expected))
            naive_differences += parser_fields(raw, nb, es, "naive_full_vector") != expected
            cases += 1
    example = {style: parser_fields(0x40, 8, 0, style) for style in
               ("current_scan", "corrected_tail_xor", "naive_full_vector")}
    return {"cases": cases, "corrected_tail_xor_mismatches": 0,
            "naive_full_vector_drop_in_differences": naive_differences,
            "scope": "all raw8/0 and16/1 words; directed/seeded32/2 and32/3 samples; arithmetic field models only",
            "example_posit8_0x40_tuple_sign_zero_nar_sf_frac": example}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--note", type=Path, default=ROOT.parent / "doc" / "Note.docx")
    parser.add_argument("--out", type=Path, default=ROOT / "results" / "note_review_20261015" / "summary.json")
    args = parser.parse_args()
    out = args.out.resolve()
    if not out.is_relative_to(ROOT):
        raise ValueError("Keep review output inside Posit_MAC")
    source_names = ["rtl/lod_lzd_core.sv", "rtl/dyn_left_shifter.sv", "rtl/dyn_right_shifter.sv",
                    "rtl/posit_parser_comb.sv", "rtl/posit_parser.sv", "SPEC_Posit_MAC_IP.md",
                    "Digital_Design_Guidelines.md"]
    sources = {name: sha(ROOT / name) for name in source_names}
    note = note_metadata(args.note)
    rng = random.Random(SEED)
    result = {"status": "PASS_ARITHMETIC_REVIEW_ONLY", "date": "2026-10-15", "seed": SEED,
              "python": platform.python_version(), "note": note,
              "source_sha256": sources, "script_sha256": sha(Path(__file__)),
              "lod": check_lod(rng), "shifters": check_shifters(rng), "parser": check_parser(rng),
              "limits": ["No production RTL or DOCX edits", "No HDL compile, RTL simulation or formal equivalence",
                         "Known binary inputs only; no X/Z equivalence claim", "No synthesis, LUT savings or timing measurement",
                         "Large-width inputs are sampled; small-domain exhaustive checks are explicitly labelled"]}
    if sources != {name: sha(ROOT / name) for name in source_names} or note["sha256"] != sha(args.note):
        raise AssertionError("A reviewed input changed during the review")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({key: result[key] for key in ("status", "lod", "shifters", "parser")}, ensure_ascii=False))


if __name__ == "__main__":
    main()
