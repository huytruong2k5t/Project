import csv
import gzip
import hashlib
import json
import sys
from collections import Counter, defaultdict
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 100

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import gen_refactored_mac_vectors as g

PAIRED_DIR = ROOT / "results" / "paired_mac_20261112"
SAMPLES_PATH = PAIRED_DIR / "samples.csv.gz"
MANIFEST_PATH = PAIRED_DIR / "manifest.json"
OUT_DIR = Path(__file__).resolve().parent


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def prod_value(a_hex: str, b_hex: str):
    a_raw = int(a_hex, 16)
    b_raw = int(b_hex, 16)
    if a_raw == g.NAR or b_raw == g.NAR:
        return None
    if a_raw == 0 or b_raw == 0:
        return 0
    sa, ma, ea = g.decode(a_raw)
    sb, mb, eb = g.decode(b_raw)
    sign = -1 if (sa != sb) else 1
    shift = g.BASE + ea + eb - 52
    assert shift >= 0, f"negative shift {shift}"
    return sign * ((ma * mb) << shift)


def signed_code(raw: int) -> int:
    return raw - (1 << 32) if (raw & 0x80000000) else raw


def quantiles_dec(vals):
    if not vals:
        return None
    s = sorted(vals)
    n = len(s)
    # nearest-rank percentile + standard median for even/odd if needed
    p50_rank = s[(50 * n + 99) // 100 - 1]
    p50_std = s[n // 2] if (n % 2 == 1) else (s[n // 2 - 1] + s[n // 2]) / Decimal(2)
    p95_rank = s[(95 * n + 99) // 100 - 1]
    p99_rank = s[(99 * n + 99) // 100 - 1]
    mean_v = sum(s) / Decimal(n)
    return {
        "n": n,
        "min": str(s[0]),
        "zero_count": sum(1 for x in s if x == 0),
        "p50_std": f"{p50_std:.6e}",
        "p50_rank": f"{p50_rank:.6e}",
        "p95_rank": f"{p95_rank:.6e}",
        "p99_rank": f"{p99_rank:.6e}",
        "max": f"{s[-1]:.6e}",
        "mean": f"{mean_v:.6e}",
    }


def quantiles_int(vals):
    if not vals:
        return None
    s = sorted(vals)
    n = len(s)
    p50_rank = s[(50 * n + 99) // 100 - 1]
    p50_std = s[n // 2] if (n % 2 == 1) else (s[n // 2 - 1] + s[n // 2]) / 2.0
    p95_rank = s[(95 * n + 99) // 100 - 1]
    p99_rank = s[(99 * n + 99) // 100 - 1]
    mean_v = sum(s) / n
    return {
        "n": n,
        "min": int(s[0]),
        "eq0": sum(1 for x in s if x == 0),
        "le1": sum(1 for x in s if x <= 1),
        "le4": sum(1 for x in s if x <= 4),
        "p50_std": p50_std,
        "p50_rank": int(p50_rank),
        "p95_rank": int(p95_rank),
        "p99_rank": int(p99_rank),
        "max": int(s[-1]),
        "mean": round(mean_v, 4),
    }


def main():
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    actual_sha = sha256_file(SAMPLES_PATH)
    expected_sha = manifest["evidence_sha256"]["samples.csv.gz"]
    assert actual_sha == expected_sha, f"SHA mismatch: {actual_sha} != {expected_sha}"

    total_rows = 0
    abs_max_rel_diff = 0.0
    sum_class_vs_exact_r = Counter()
    cancel_groups = defaultdict(list)

    with gzip.open(SAMPLES_PATH, "rt", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        for row in reader:
            total_rows += 1
            if row["c_case"] != "cancel_target":
                continue

            p_val = prod_value(row["a_hex"], row["b_hex"])
            c_raw = int(row["c_hex"], 16)
            c_val = g.value(c_raw)
            d_nf = int(row["d_nf"], 16)
            d_f = int(row["d_f"], 16)
            assert p_val is not None and c_val is not None
            r = p_val + c_val

            v_nf = g.value(d_nf)
            v_f = g.value(d_f)
            err_nf_int = abs(v_nf - r)
            err_f_int = abs(v_f - r)

            # Sanity check against CSV's abs_nf / abs_f
            abs_nf_calc = float(Decimal(err_nf_int) / Decimal(1 << g.BASE))
            abs_f_calc = float(Decimal(err_f_int) / Decimal(1 << g.BASE))
            abs_nf_csv = float(row["abs_nf"])
            abs_f_csv = float(row["abs_f"])
            if abs_nf_csv > 0:
                abs_max_rel_diff = max(abs_max_rel_diff, abs(abs_nf_calc - abs_nf_csv) / abs_nf_csv)
            if abs_f_csv > 0:
                abs_max_rel_diff = max(abs_max_rel_diff, abs(abs_f_calc - abs_f_csv) / abs_f_csv)

            r_pos_raw, _ = g.encode(r)
            sum_class = row["sum_class"]
            sum_class_vs_exact_r[(sum_class, r == 0, r_pos_raw == 0, p_val == 0, row["c_clamp"] != "")] += 1

            cd_nf = abs(signed_code(d_nf) - signed_code(r_pos_raw))
            cd_f = abs(signed_code(d_f) - signed_code(r_pos_raw))

            if p_val != 0:
                abs_p_dec = Decimal(abs(p_val))
                rel_p_nf = Decimal(err_nf_int) / abs_p_dec
                rel_p_f = Decimal(err_f_int) / abs_p_dec
            else:
                rel_p_nf = None
                rel_p_f = None

            rec = {
                "ab_group": row["ab_group"],
                "sum_class": sum_class,
                "r_eq_0": (r == 0),
                "p_eq_0": (p_val == 0),
                "c_clamp": row["c_clamp"],
                "cd_nf": cd_nf,
                "cd_f": cd_f,
                "rel_p_nf": rel_p_nf,
                "rel_p_f": rel_p_f,
                "err_nf_int": err_nf_int,
                "err_f_int": err_f_int,
                "r_pos_raw": r_pos_raw,
                "d_nf": d_nf,
                "d_f": d_f,
                "accuracy": row["accuracy"],
            }
            cancel_groups[("all", sum_class)].append(rec)
            cancel_groups[(row["ab_group"], sum_class)].append(rec)
            cancel_groups[("all", "ALL_CANCEL")].append(rec)
            if row["ab_group"] == "uniform_raw":
                cancel_groups[("uniform_raw", "ALL_CANCEL")].append(rec)
            if r == 0:
                cancel_groups[("all", "EXACT_R_EQ_0")].append(rec)
            else:
                cancel_groups[("all", "EXACT_R_NE_0")].append(rec)

    summary_out = {
        "samples_sha256": actual_sha,
        "total_rows": total_rows,
        "cancel_target_rows": len(cancel_groups[("all", "ALL_CANCEL")]),
        "abs_err_cross_check_max_rel_diff": abs_max_rel_diff,
        "sum_class_vs_exact_r": {str(k): v for k, v in sorted(sum_class_vs_exact_r.items())},
        "groups": {},
    }

    for (ab_grp, sc), recs in sorted(cancel_groups.items()):
        cds_nf = [x["cd_nf"] for x in recs]
        cds_f = [x["cd_f"] for x in recs]
        cd_comp = Counter()
        rel_comp = Counter()
        exact_zero_out = Counter()
        for x in recs:
            if x["cd_f"] < x["cd_nf"]:
                cd_comp["f_better"] += 1
            elif x["cd_f"] > x["cd_nf"]:
                cd_comp["f_worse"] += 1
            else:
                cd_comp["tie"] += 1

            if x["rel_p_nf"] is not None:
                if x["rel_p_f"] < x["rel_p_nf"]:
                    rel_comp["f_better"] += 1
                elif x["rel_p_f"] > x["rel_p_nf"]:
                    rel_comp["f_worse"] += 1
                else:
                    rel_comp["tie"] += 1
            exact_zero_out[(x["d_nf"] == 0, x["d_f"] == 0, x["d_nf"] == x["d_f"])] += 1

        rel_nf_vals = [x["rel_p_nf"] for x in recs if x["rel_p_nf"] is not None]
        rel_f_vals = [x["rel_p_f"] for x in recs if x["rel_p_f"] is not None]

        summary_out["groups"][f"{ab_grp}__{sc}"] = {
            "n": len(recs),
            "p_eq_0": sum(1 for x in recs if x["p_eq_0"]),
            "r_eq_0": sum(1 for x in recs if x["r_eq_0"]),
            "r_pos_eq_0": sum(1 for x in recs if x["r_pos_raw"] == 0),
            "code_distance_nf": quantiles_int(cds_nf),
            "code_distance_f": quantiles_int(cds_f),
            "code_distance_cmp": dict(cd_comp),
            "err_over_P_nf": quantiles_dec(rel_nf_vals),
            "err_over_P_f": quantiles_dec(rel_f_vals),
            "err_over_P_cmp": dict(rel_comp),
            "zero_output_breakdown": {str(k): v for k, v in sorted(exact_zero_out.items())},
        }

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_json = OUT_DIR / "cancel_target_metrics.json"
    out_json.write_text(json.dumps(summary_out, indent=2), encoding="utf-8")
    print(f"Wrote {out_json}")
    print("sum_class_vs_exact_r:", summary_out["sum_class_vs_exact_r"])
    print("max_rel_diff_vs_csv:", abs_max_rel_diff)
    for k in ["all__near_zero", "all__regular", "all__zero", "all__EXACT_R_EQ_0", "all__ALL_CANCEL", "uniform_raw__near_zero", "uniform_raw__regular"]:
        if k in summary_out["groups"]:
            gstats = summary_out["groups"][k]
            print(f"\n[{k}] n={gstats['n']} r_eq_0={gstats['r_eq_0']} r_pos_eq_0={gstats['r_pos_eq_0']}")
            print("  CD NF:", gstats["code_distance_nf"])
            print("  CD F :", gstats["code_distance_f"])
            print("  CD cmp:", gstats["code_distance_cmp"])
            print("  |err|/|P| NF:", gstats["err_over_P_nf"])
            print("  |err|/|P| F :", gstats["err_over_P_f"])
            print("  |err|/|P| cmp:", gstats["err_over_P_cmp"])


if __name__ == "__main__":
    main()
