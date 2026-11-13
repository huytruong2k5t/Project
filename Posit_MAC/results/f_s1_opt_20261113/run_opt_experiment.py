#!/usr/bin/env python3
"""Stage, lint, ModelSim-verify, and Vivado synth+route MAC-F S1 timing optimization candidates."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time

REPO_ROOT = Path(__file__).resolve().parents[2]
EXP_ROOT = Path(__file__).resolve().parent
MSIM_BIN = Path(r"C:\altera\13.0sp1\modelsim_ase\win32aloem")
VIVADO_BAT = Path(r"C:\AMDDesignTools\2026.1\Vivado\bin\vivado.bat")
VECTORS_F = REPO_ROOT / "results" / "nf_f_lock_20261105" / "modelsim" / "vectors" / "f.txt"
VECTORS_NF = REPO_ROOT / "results" / "nf_f_lock_20261105" / "modelsim" / "vectors" / "nf.txt"

CANDIDATES = ("c1a_split_only", "c1b_key_split", "c2_prenorm0", "c2a_prenorm_split", "c3_pipe1")


def win_to_wsl(p: Path) -> str:
    s = str(p.resolve())
    drive = s[0].lower()
    rest = s[2:].replace("\\", "/")
    return f"/mnt/{drive}{rest}"


def run_cmd(cmd, cwd, logfile, env=None, timeout=600):
    t0 = time.perf_counter()
    p = subprocess.run(cmd, cwd=str(cwd), env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=timeout)
    dt = time.perf_counter() - t0
    logfile.write_text(f"CMD: {cmd}\nRC: {p.returncode}\nELAPSED_S: {dt:.2f}\n\n{p.stdout}", encoding="utf-8", errors="replace")
    return p.returncode, dt, p.stdout


def patch_c1a_prepare(src_text: str) -> str:
    old = """    wire choose_a = !a_is_zero
                  && (b_is_zero || (!sf_a_lt_b && (!sf_equal || frac_a_ge_b)));

    assign both_nonzero = !a_is_zero && !b_is_zero;
    assign x_frac       = choose_a ? a_frac : b_frac;
    assign y_frac       = choose_a ? b_frac : a_frac;
    assign shift_amount = sf_a_lt_b ? diff_ba[4:0] : diff_ab[4:0];
    assign clamped      = sf_a_lt_b ? clamp_ba : clamp_ab;
    assign subtract     = both_nonzero && (a_sign != b_sign);
    assign sign_base    = choose_a ? a_sign : b_sign;
    assign sf_base      = choose_a ? a_sf   : b_sf;"""
    assert old in src_text, "Expected pattern missing in posit_add_prepare_comb.sv"
    new = """    wire choose_a_cond = !a_is_zero
                       && (b_is_zero || (!sf_a_lt_b && (!sf_equal || frac_a_ge_b)));

    (* dont_touch = "true" *) wire choose_a_frac0 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_frac1 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_frac2 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_meta  = choose_a_cond;

    assign both_nonzero       = !a_is_zero && !b_is_zero;
    assign x_frac[8:0]        = choose_a_frac0 ? a_frac[8:0]   : b_frac[8:0];
    assign y_frac[8:0]        = choose_a_frac0 ? b_frac[8:0]   : a_frac[8:0];
    assign x_frac[17:9]       = choose_a_frac1 ? a_frac[17:9]  : b_frac[17:9];
    assign y_frac[17:9]       = choose_a_frac1 ? b_frac[17:9]  : a_frac[17:9];
    assign x_frac[25:18]      = choose_a_frac2 ? a_frac[25:18] : b_frac[25:18];
    assign y_frac[25:18]      = choose_a_frac2 ? b_frac[25:18] : a_frac[25:18];
    assign shift_amount       = sf_a_lt_b ? diff_ba[4:0] : diff_ab[4:0];
    assign clamped            = sf_a_lt_b ? clamp_ba : clamp_ab;
    assign subtract           = both_nonzero && (a_sign != b_sign);
    assign sign_base          = choose_a_meta ? a_sign : b_sign;
    assign sf_base            = choose_a_meta ? a_sf   : b_sf;"""
    return src_text.replace(old, new, 1)


def patch_c1b_prepare(src_text: str) -> str:
    old = """    wire sf_a_lt_b   = diff_ab[11];
    wire sf_equal    = (a_sf == b_sf);
    wire frac_a_ge_b = (a_frac >= b_frac);

    // Effective non-clamped shift is <= F + 2 = 28; delta >= 29 saturates to jam=1.
    wire clamp_ab = !diff_ab[11] && ((|diff_ab[10:5]) || (diff_ab[4:0] > 5'd28));
    wire clamp_ba = !diff_ba[11] && ((|diff_ba[10:5]) || (diff_ba[4:0] > 5'd28));

    wire choose_a = !a_is_zero
                  && (b_is_zero || (!sf_a_lt_b && (!sf_equal || frac_a_ge_b)));

    assign both_nonzero = !a_is_zero && !b_is_zero;
    assign x_frac       = choose_a ? a_frac : b_frac;
    assign y_frac       = choose_a ? b_frac : a_frac;
    assign shift_amount = sf_a_lt_b ? diff_ba[4:0] : diff_ab[4:0];
    assign clamped      = sf_a_lt_b ? clamp_ba : clamp_ab;
    assign subtract     = both_nonzero && (a_sign != b_sign);
    assign sign_base    = choose_a ? a_sign : b_sign;
    assign sf_base      = choose_a ? a_sf   : b_sf;"""
    assert old in src_text, "Expected pattern missing in posit_add_prepare_comb.sv"
    new = """    wire sf_a_lt_b = diff_ab[11];

    // Unified signed-scale + fraction magnitude comparison (offset binary on sf[10]).
    wire [36:0] mag_key_a  = {~a_sf[10], a_sf[9:0], a_frac};
    wire [36:0] mag_key_b  = {~b_sf[10], b_sf[9:0], b_frac};
    wire        mag_a_ge_b = (mag_key_a >= mag_key_b);

    // Effective non-clamped shift is <= F + 2 = 28; delta >= 29 saturates to jam=1.
    wire clamp_ab = !diff_ab[11] && ((|diff_ab[10:5]) || (diff_ab[4:0] > 5'd28));
    wire clamp_ba = !diff_ba[11] && ((|diff_ba[10:5]) || (diff_ba[4:0] > 5'd28));

    wire choose_a_cond = !a_is_zero && (b_is_zero || mag_a_ge_b);

    (* dont_touch = "true" *) wire choose_a_frac0 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_frac1 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_frac2 = choose_a_cond;
    (* dont_touch = "true" *) wire choose_a_meta  = choose_a_cond;

    assign both_nonzero       = !a_is_zero && !b_is_zero;
    assign x_frac[8:0]        = choose_a_frac0 ? a_frac[8:0]   : b_frac[8:0];
    assign y_frac[8:0]        = choose_a_frac0 ? b_frac[8:0]   : a_frac[8:0];
    assign x_frac[17:9]       = choose_a_frac1 ? a_frac[17:9]  : b_frac[17:9];
    assign y_frac[17:9]       = choose_a_frac1 ? b_frac[17:9]  : a_frac[17:9];
    assign x_frac[25:18]      = choose_a_frac2 ? a_frac[25:18] : b_frac[25:18];
    assign y_frac[25:18]      = choose_a_frac2 ? b_frac[25:18] : a_frac[25:18];
    assign shift_amount       = sf_a_lt_b ? diff_ba[4:0] : diff_ab[4:0];
    assign clamped            = sf_a_lt_b ? clamp_ba : clamp_ab;
    assign subtract           = both_nonzero && (a_sign != b_sign);
    assign sign_base          = choose_a_meta ? a_sign : b_sign;
    assign sf_base            = choose_a_meta ? a_sf   : b_sf;"""
    return src_text.replace(old, new, 1)


def patch_c2_mul_core(src_text: str) -> str:
    old_ports = """    output wire [25:0]        acc,
    output wire [3:0]         iterations_done,"""
    new_ports = """    output wire [25:0]        acc,
    output wire [25:0]        acc_next_o,
    output wire               acc_done_next_o,
    output wire [3:0]         iterations_done,"""
    assert old_ports in src_text
    src_text = src_text.replace(old_ports, new_ports, 1)

    old_assign = "    assign acc             = acc_q;"
    new_assign = """    assign acc             = acc_q;
    assign acc_next_o      = acc_next;
    assign acc_done_next_o = t2_valid && t2_last;"""
    assert old_assign in src_text
    return src_text.replace(old_assign, new_assign, 1)


def patch_c2_mac_nf(src_text: str) -> str:
    old_wires = """    wire [ACC_W-1:0] acc;"""
    new_wires = """    wire [ACC_W-1:0] acc;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [ACC_W-1:0] core_acc_next_discarded;
    wire core_done_next_discarded;
    /* verilator lint_on UNUSEDSIGNAL */"""
    assert old_wires in src_text
    src_text = src_text.replace(old_wires, new_wires, 1)

    old_inst = """        .acc (acc),
        .iterations_done (iterations_done),"""
    new_inst = """        .acc (acc),
        .acc_next_o (core_acc_next_discarded),
        .acc_done_next_o (core_done_next_discarded),
        .iterations_done (iterations_done),"""
    assert old_inst in src_text
    return src_text.replace(old_inst, new_inst, 1)


def patch_c2_mac_quire(src_text: str) -> str:
    old_wires = "    wire [25:0] acc;"
    new_wires = """    wire [25:0] acc;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [25:0] core_acc_next_discarded;
    wire core_done_next_discarded;
    /* verilator lint_on UNUSEDSIGNAL */"""
    assert old_wires in src_text
    src_text = src_text.replace(old_wires, new_wires, 1)

    old_inst = """        .acc (acc),
        .iterations_done (iterations_done),"""
    new_inst = """        .acc (acc),
        .acc_next_o (core_acc_next_discarded),
        .acc_done_next_o (core_done_next_discarded),
        .iterations_done (iterations_done),"""
    assert old_inst in src_text
    return src_text.replace(old_inst, new_inst, 1)


def patch_c2_mac_f(src_text: str) -> str:
    old_decls = """    wire [ACC_W-1:0] acc;
    wire approx_cut;"""
    new_decls = """    /* verilator lint_off UNUSEDSIGNAL */
    wire [ACC_W-1:0] acc;
    /* verilator lint_on UNUSEDSIGNAL */
    wire [ACC_W-1:0] core_acc_next;
    wire core_done_next;
    wire approx_cut;"""
    assert old_decls in src_text
    src_text = src_text.replace(old_decls, new_decls, 1)

    old_prod = """    wire signed [10:0] product_sf;
    wire [25:0] product_frac;
    wire [4:0] product_flags;

    mul_prepack_norm_comb u_norm (
        .acc (acc),
        .sf (core_sf),
        .sf_inc (core_sf_inc_q),
        .sf_norm (product_sf),
        .frac_norm (product_frac)
    );"""
    new_prod = """    wire signed [10:0] norm_sf_d;
    wire [25:0] norm_frac_d;
    logic signed [10:0] product_sf_q;
    logic [25:0] product_frac_q;
    wire [4:0] product_flags;

    // Normalize L3 accumulator lookahead before the done_q register edge (zero extra cycles).
    mul_prepack_norm_comb u_norm (
        .acc (core_acc_next),
        .sf (core_sf),
        .sf_inc (core_sf_inc_q),
        .sf_norm (norm_sf_d),
        .frac_norm (norm_frac_d)
    );"""
    assert old_prod in src_text
    src_text = src_text.replace(old_prod, new_prod, 1)

    old_core_inst = """        .acc (acc),
        .iterations_done (iterations_done),"""
    new_core_inst = """        .acc (acc),
        .acc_next_o (core_acc_next),
        .acc_done_next_o (core_done_next),
        .iterations_done (iterations_done),"""
    assert old_core_inst in src_text
    src_text = src_text.replace(old_core_inst, new_core_inst, 1)

    old_add_inst = """        .a_sf (product_sf),
        .a_frac (product_frac),"""
    new_add_inst = """        .a_sf (product_sf_q),
        .a_frac (product_frac_q),"""
    assert old_add_inst in src_text
    src_text = src_text.replace(old_add_inst, new_add_inst, 1)

    old_rst = "            core_sf_inc_q <= '0;"
    new_rst = """            core_sf_inc_q <= '0;
            product_sf_q <= '0;
            product_frac_q <= '0;"""
    assert old_rst in src_text
    src_text = src_text.replace(old_rst, new_rst, 1)

    old_end_ff = """            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b || nar_c);
                c_nar_q <= `CK2Q nar_c;
                core_sf_inc_q <= `CK2Q (ops_sf + 11'sd1);
                c_sign_q <= `CK2Q s_c;
                c_zero_q <= `CK2Q z_c;
                c_sf_q <= `CK2Q sf_c;
                c_frac_q <= `CK2Q frac_c;
            end
        end"""
    new_end_ff = """            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b || nar_c);
                c_nar_q <= `CK2Q nar_c;
                core_sf_inc_q <= `CK2Q (ops_sf + 11'sd1);
                c_sign_q <= `CK2Q s_c;
                c_zero_q <= `CK2Q z_c;
                c_sf_q <= `CK2Q sf_c;
                c_frac_q <= `CK2Q frac_c;
            end
            if (core_done_next) begin
                product_sf_q <= `CK2Q norm_sf_d;
                product_frac_q <= `CK2Q norm_frac_d;
            end
        end"""
    assert old_end_ff in src_text
    return src_text.replace(old_end_ff, new_end_ff, 1)


def patch_c3_mac_f(src_text: str) -> str:
    old_wires = """    wire [4:0] product_flags;"""
    new_wires = """    wire [4:0] product_flags;
    logic norm_valid_q;
    logic norm_sign_q;
    logic norm_zero_q;
    logic norm_nar_q;
    logic signed [SF_W-1:0] norm_sf_q;
    logic [F-1:0] norm_frac_q;
    logic [4:0] norm_flags_q;"""
    assert old_wires in src_text
    src_text = src_text.replace(old_wires, new_wires, 1)

    old_add_inst = """    posit_add  u_add (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (core_done),
        .in_ready (add_ready),
        .out_valid (add_valid),
        .out_ready (pack_ready),
        .a_sign (core_sign),
        .a_is_zero (zero_q),
        .a_is_nar (nar_q),
        .a_sf (product_sf),
        .a_frac (product_frac),
        .b_sign (c_sign_q),
        .b_is_zero (c_zero_q),
        .b_is_nar (c_nar_q),
        .b_sf (c_sf_q),
        .b_frac (c_frac_q),
        .flags_in (product_flags),"""
    new_add_inst = """    posit_add  u_add (
        .clk (clk),
        .reset_n (reset_n),
        .in_valid (norm_valid_q),
        .in_ready (add_ready),
        .out_valid (add_valid),
        .out_ready (pack_ready),
        .a_sign (norm_sign_q),
        .a_is_zero (norm_zero_q),
        .a_is_nar (norm_nar_q),
        .a_sf (norm_sf_q),
        .a_frac (norm_frac_q),
        .b_sign (c_sign_q),
        .b_is_zero (c_zero_q),
        .b_is_nar (c_nar_q),
        .b_sf (c_sf_q),
        .b_frac (c_frac_q),
        .flags_in (norm_flags_q),"""
    assert old_add_inst in src_text
    src_text = src_text.replace(old_add_inst, new_add_inst, 1)

    old_rst = "            core_sf_inc_q <= '0;"
    new_rst = """            core_sf_inc_q <= '0;
            norm_valid_q <= 1'b0;
            norm_sign_q <= 1'b0;
            norm_zero_q <= 1'b0;
            norm_nar_q <= 1'b0;
            norm_sf_q <= '0;
            norm_frac_q <= '0;
            norm_flags_q <= '0;"""
    assert old_rst in src_text
    src_text = src_text.replace(old_rst, new_rst, 1)

    old_end_ff = """            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b || nar_c);
                c_nar_q <= `CK2Q nar_c;
                core_sf_inc_q <= `CK2Q (ops_sf + 11'sd1);
                c_sign_q <= `CK2Q s_c;
                c_zero_q <= `CK2Q z_c;
                c_sf_q <= `CK2Q sf_c;
                c_frac_q <= `CK2Q frac_c;
            end
        end"""
    new_end_ff = """            if (pair_retire) begin
                zero_q <= `CK2Q (z_a || z_b);
                nar_q <= `CK2Q (nar_a || nar_b || nar_c);
                c_nar_q <= `CK2Q nar_c;
                core_sf_inc_q <= `CK2Q (ops_sf + 11'sd1);
                c_sign_q <= `CK2Q s_c;
                c_zero_q <= `CK2Q z_c;
                c_sf_q <= `CK2Q sf_c;
                c_frac_q <= `CK2Q frac_c;
            end
            if (norm_valid_q && add_ready) norm_valid_q <= `CK2Q 1'b0;
            if (core_done) begin
                norm_valid_q <= `CK2Q 1'b1;
                norm_sign_q <= `CK2Q core_sign;
                norm_zero_q <= `CK2Q zero_q;
                norm_nar_q <= `CK2Q nar_q;
                norm_sf_q <= `CK2Q product_sf;
                norm_frac_q <= `CK2Q product_frac;
                norm_flags_q <= `CK2Q product_flags;
            end
        end"""
    assert old_end_ff in src_text
    return src_text.replace(old_end_ff, new_end_ff, 1)


def copy_base_source(src_dir: Path):
    if src_dir.exists():
        shutil.rmtree(src_dir)
    shutil.copytree(REPO_ROOT / "rtl", src_dir / "rtl")
    (src_dir / "tb").mkdir()
    for p in (
        "tb/week13_fused_ppa_top.sv",
        "tb/prepack_nf_ppa_top.sv",
        "tb/tb_refactored_mac.sv",
        "tb/tb_posit_add_5stage_equiv.sv",
        "tb/tb_report_mac_f_trace.sv",
    ):
        shutil.copyfile(REPO_ROOT / p, src_dir / p)
    shutil.copytree(REPO_ROOT / "tb" / "reference", src_dir / "tb" / "reference")
    shutil.copytree(REPO_ROOT / "syn", src_dir / "syn")


def stage_candidate(cand: str) -> Path:
    cdir = EXP_ROOT / cand
    cdir.mkdir(parents=True, exist_ok=True)
    src = cdir / "source"
    copy_base_source(src)

    prep_p = src / "rtl" / "adder" / "posit_add_prepare_comb.sv"
    prep_txt = prep_p.read_text(encoding="utf-8")
    if cand in ("c1a_split_only", "c2a_prenorm_split"):
        prep_p.write_text(patch_c1a_prepare(prep_txt), encoding="utf-8")
    elif cand in ("c1b_key_split", "c2_prenorm0", "c3_pipe1"):
        prep_p.write_text(patch_c1b_prepare(prep_txt), encoding="utf-8")

    if cand in ("c2_prenorm0", "c2a_prenorm_split"):
        core_p = src / "rtl" / "multiplier" / "mul_iter_core.sv"
        core_p.write_text(patch_c2_mul_core(core_p.read_text(encoding="utf-8")), encoding="utf-8")
        nf_p = src / "rtl" / "mac_nf" / "mac_nf_wrapper.sv"
        nf_p.write_text(patch_c2_mac_nf(nf_p.read_text(encoding="utf-8")), encoding="utf-8")
        q_p = src / "rtl" / "mac_quire" / "mac_quire_wrapper.sv"
        q_p.write_text(patch_c2_mac_quire(q_p.read_text(encoding="utf-8")), encoding="utf-8")
        f_p = src / "rtl" / "mac_f" / "mac_f_wrapper.sv"
        f_p.write_text(patch_c2_mac_f(f_p.read_text(encoding="utf-8")), encoding="utf-8")
    elif cand == "c3_pipe1":
        f_p = src / "rtl" / "mac_f" / "mac_f_wrapper.sv"
        f_p.write_text(patch_c3_mac_f(f_p.read_text(encoding="utf-8")), encoding="utf-8")
    return cdir


def verify_candidate(cand: str, cdir: Path, ref_trace: Path):
    src = cdir / "source"
    vdir = cdir / "verify"
    if vdir.exists():
        shutil.rmtree(vdir)
    vdir.mkdir()
    logs = vdir / "logs"
    logs.mkdir()

    # 1. WSL Verilator strict lint on active hierarchy (posit_mac_f, posit_mac_nf, posit_add_prepare_comb, posit_mac_quire)
    wsl_src = win_to_wsl(src)
    lint_results = {}
    lint_targets = [
        ("posit_mac_f", "rtl/mac_active.f"),
        ("posit_mac_nf", "rtl/mac_active.f"),
        ("posit_add_prepare_comb", "rtl/mac_active.f"),
        ("posit_mac_quire", "rtl/quire_active.f"),
    ]
    for top, flist in lint_targets:
        rc, _, out = run_cmd(
            ["wsl", "bash", "-lc", f"cd '{wsl_src}' && verilator --lint-only --timing --assert -Wall -Irtl --top-module {top} -f {flist}"],
            vdir, logs / f"lint_{top}.log"
        )
        if rc != 0:
            raise RuntimeError(f"{cand} verilator lint failed for {top}:\n{out}")
        lint_results[top] = "PASS"

    # 2. Generate bit-exact S1 prepare equivalence TB vs locked 07/11 posit_add_prepare_comb
    ref_prep_src = (REPO_ROOT / "rtl" / "adder" / "posit_add_prepare_comb.sv").read_text(encoding="utf-8")
    (vdir / "posit_add_prepare_comb_ref.sv").write_text(
        ref_prep_src.replace("module posit_add_prepare_comb", "module posit_add_prepare_comb_ref", 1),
        encoding="utf-8"
    )
    (vdir / "tb_s1_prepare_equiv.sv").write_text(r'''`timescale 1ns/1ps
module tb_s1_prepare_equiv;
    logic a_sign, a_is_zero, a_is_nar, b_sign, b_is_zero, b_is_nar;
    logic signed [10:0] a_sf, b_sf;
    logic [25:0] a_frac, b_frac;
    logic [4:0] flags_in;

    wire [25:0] dut_x, dut_y, ref_x, ref_y;
    wire [4:0] dut_sh, ref_sh;
    wire dut_cl, dut_bnz, dut_sub, dut_sg, dut_bz, dut_nar;
    wire ref_cl, ref_bnz, ref_sub, ref_sg, ref_bz, ref_nar;
    wire signed [10:0] dut_sfb, ref_sfb;
    wire [3:0] dut_fl, ref_fl;

    posit_add_prepare_comb u_dut (
        .a_sign(a_sign), .a_is_zero(a_is_zero), .a_is_nar(a_is_nar), .a_sf(a_sf), .a_frac(a_frac),
        .b_sign(b_sign), .b_is_zero(b_is_zero), .b_is_nar(b_is_nar), .b_sf(b_sf), .b_frac(b_frac),
        .flags_in(flags_in),
        .x_frac(dut_x), .y_frac(dut_y), .shift_amount(dut_sh), .clamped(dut_cl),
        .both_nonzero(dut_bnz), .subtract(dut_sub), .sign_base(dut_sg), .sf_base(dut_sfb),
        .both_zero(dut_bz), .is_nar(dut_nar), .flags_lo(dut_fl)
    );
    posit_add_prepare_comb_ref u_ref (
        .a_sign(a_sign), .a_is_zero(a_is_zero), .a_is_nar(a_is_nar), .a_sf(a_sf), .a_frac(a_frac),
        .b_sign(b_sign), .b_is_zero(b_is_zero), .b_is_nar(b_is_nar), .b_sf(b_sf), .b_frac(b_frac),
        .flags_in(flags_in),
        .x_frac(ref_x), .y_frac(ref_y), .shift_amount(ref_sh), .clamped(ref_cl),
        .both_nonzero(ref_bnz), .subtract(ref_sub), .sign_base(ref_sg), .sf_base(ref_sfb),
        .both_zero(ref_bz), .is_nar(ref_nar), .flags_lo(ref_fl)
    );

    int checks = 0;
    logic [63:0] rng = 64'h9E37_79B9_7F4A_7C15;
    function automatic void step_rng();
        rng = rng ^ (rng << 13);
        rng = rng ^ (rng >> 7);
        rng = rng ^ (rng << 17);
    endfunction

    task automatic check_one();
        #1;
        checks++;
        if ({dut_x, dut_y, dut_sh, dut_cl, dut_bnz, dut_sub, dut_sg, dut_sfb, dut_bz, dut_nar, dut_fl} !==
            {ref_x, ref_y, ref_sh, ref_cl, ref_bnz, ref_sub, ref_sg, ref_sfb, ref_bz, ref_nar, ref_fl}) begin
            $display("S1_MISMATCH #%0d a=(%b,%b,%b,%0d,%h) b=(%b,%b,%b,%0d,%h)", checks,
                     a_sign, a_is_zero, a_is_nar, a_sf, a_frac,
                     b_sign, b_is_zero, b_is_nar, b_sf, b_frac);
            $fatal(1, "S1 prepare mismatch");
        end
    endtask

    initial begin
        // Boundary & tie cases including extreme signed sf (-1024, +1023)
        logic signed [10:0] sf_vals [0:6] = '{-11'sd1024, -11'sd1023, -11'sd1, 11'sd0, 11'sd1, 11'sd1022, 11'sd1023};
        for (int ia = 0; ia < 7; ia++) begin
            for (int ib = 0; ib < 7; ib++) begin
                for (int za = 0; za < 2; za++) begin
                    for (int zb = 0; zb < 2; zb++) begin
                        for (int fa = 0; fa < 3; fa++) begin
                            for (int fb = 0; fb < 3; fb++) begin
                                a_sign = za[0]; b_sign = zb[0];
                                a_is_zero = (fa == 2); b_is_zero = (fb == 2);
                                a_is_nar = 1'b0; b_is_nar = 1'b0;
                                a_sf = sf_vals[ia]; b_sf = sf_vals[ib];
                                a_frac = (fa == 0) ? 26'h0 : (fa == 1 ? 26'h3FF_FFFF : 26'h200_0001);
                                b_frac = (fb == 0) ? 26'h0 : (fb == 1 ? 26'h3FF_FFFF : 26'h200_0001);
                                flags_in = {za[0], zb[0], ia[1:0], ib[0]};
                                check_one();
                            end
                        end
                    end
                end
            end
        end
        // 200,000 random stress + tied-sf vectors
        for (int i = 0; i < 200000; i++) begin
            step_rng(); a_sign = rng[0]; a_is_zero = (rng[4:1] == 0); a_is_nar = (rng[8:5] == 0);
            a_sf = $signed(rng[19:9]); a_frac = rng[45:20]; flags_in = rng[50:46];
            step_rng(); b_sign = rng[0]; b_is_zero = (rng[4:1] == 0); b_is_nar = (rng[8:5] == 0);
            b_sf = (i[1:0] == 2'b00) ? a_sf : $signed(rng[19:9]);
            b_frac = (i[2:0] == 3'b000) ? a_frac : rng[45:20];
            check_one();
        end
        $display("S1_PREPARE_EQUIV_PASS checks=%0d mismatches=0", checks);
        $finish;
    end
endmodule
''', encoding="utf-8")

    # 3. ModelSim compile + sims
    rtl_files = [str(src / ln.strip()) for ln in (src / "rtl" / "mac_active.f").read_text(encoding="ascii").splitlines() if ln.strip()]
    inc = f"+incdir+{src / 'rtl'}"

    rc, _, out = run_cmd([str(MSIM_BIN / "vlib.exe"), "work"], vdir, logs / "vlib.log")
    assert rc == 0, out

    all_srcs = rtl_files + [
        str(vdir / "posit_add_prepare_comb_ref.sv"),
        str(vdir / "tb_s1_prepare_equiv.sv"),
        str(src / "tb" / "tb_refactored_mac.sv"),
        str(src / "tb" / "tb_report_mac_f_trace.sv"),
    ]
    rc, _, out = run_cmd([str(MSIM_BIN / "vlog.exe"), "-sv", "-timescale", "1ns/1ps", inc, "-work", "work"] + all_srcs, vdir, logs / "vlog.log")
    if rc != 0:
        raise RuntimeError(f"{cand} vlog failed:\n{out}")

    # Run S1 prepare bit-exact equivalence (200k+ vectors)
    rc, _, out = run_cmd([str(MSIM_BIN / "vsim.exe"), "-c", "-lib", "work", "work.tb_s1_prepare_equiv", "-do", "run -all; quit -f"], vdir, logs / "sim_s1.log")
    if rc != 0 or "S1_PREPARE_EQUIV_PASS" not in out:
        raise RuntimeError(f"{cand} tb_s1_prepare_equiv failed:\n{out}")

    # Run full 10,000-row F regression
    rc, _, out = run_cmd([str(MSIM_BIN / "vsim.exe"), "-c", "-lib", "work", "work.tb_refactored_mac", "-GFUSED=1", f"+VECTORS={VECTORS_F}", "-do", "run -all; quit -f"], vdir, logs / "sim_mac_f.log")
    if rc != 0 or "MAC_REFACTOR_PASS F=1" not in out:
        raise RuntimeError(f"{cand} tb_refactored_mac F failed:\n{out}")

    # Run full 10,000-row NF regression
    rc, _, out = run_cmd([str(MSIM_BIN / "vsim.exe"), "-c", "-lib", "work", "work.tb_refactored_mac", "-GFUSED=0", f"+VECTORS={VECTORS_NF}", "-do", "run -all; quit -f"], vdir, logs / "sim_mac_nf.log")
    if rc != 0 or "MAC_REFACTOR_PASS F=0" not in out:
        raise RuntimeError(f"{cand} tb_refactored_mac NF failed:\n{out}")

    # Run trace check
    rc, _, out = run_cmd([str(MSIM_BIN / "vsim.exe"), "-c", "-lib", "work", "work.tb_report_mac_f_trace", "-do", "run -all; quit -f"], vdir, logs / "sim_trace.log")
    if rc != 0 or "REPORT_TRACE_PASS" not in out:
        raise RuntimeError(f"{cand} tb_report_mac_f_trace failed:\n{out}")

    trace_match = (vdir / "trace.csv").read_text(encoding="utf-8") == ref_trace.read_text(encoding="utf-8")
    m_line = [ln for ln in out.splitlines() if "REPORT_TRACE_PASS" in ln][-1]
    mac_f_line = [ln for ln in (logs / "sim_mac_f.log").read_text(encoding="utf-8").splitlines() if "MAC_REFACTOR_PASS" in ln][-1]
    mac_nf_line = [ln for ln in (logs / "sim_mac_nf.log").read_text(encoding="utf-8").splitlines() if "MAC_REFACTOR_PASS" in ln][-1]
    s1_line = [ln for ln in (logs / "sim_s1.log").read_text(encoding="utf-8").splitlines() if "S1_PREPARE_EQUIV_PASS" in ln][-1]

    res = {
        "lint": lint_results,
        "s1_equiv": s1_line.strip(),
        "mac_f_10k": mac_f_line.strip(),
        "mac_nf_10k": mac_nf_line.strip(),
        "trace": m_line.strip(),
        "cycle_exact_trace_match_vs_baseline": trace_match,
    }
    print(f"[VERIFY PASS] {cand}: trace_exact={trace_match} | F={mac_f_line.strip()} | NF={mac_nf_line.strip()}", flush=True)
    return res


def vivado_run_candidate(cand: str, cdir: Path, top: str = "week13_fused_ppa_top", out_sub: str = "vivado_f"):
    src = cdir / "source"
    vrun = cdir / out_sub
    if vrun.exists():
        shutil.rmtree(vrun)
    vrun.mkdir()
    for d in ("tmp", "appdata", "localappdata"):
        (vrun / d).mkdir()

    tcl = vrun / "run.tcl"
    tcl.write_text(f"""# Exact 100 MHz OOC Synth + Place + Route recipe matching route_mac_100mhz.tcl plus reg2reg setup reports
set root {{{src.as_posix()}}}
set part xc7a35tcpg236-1
set_param general.maxThreads 4
create_project -in_memory -part $part
set_property include_dirs [list [file join $root rtl]] [current_fileset]
set list_file [open [file join $root rtl mac_active.f] r]
set rtl [split [read $list_file] \\n]
close $list_file
foreach path $rtl {{
    set path [string trim $path]
    if {{$path ne {{}}}} {{read_verilog -sv [list [file join $root $path]]}}
}}
set top {top}
read_verilog -sv [list [file join $root tb ${{top}}.sv]]
read_xdc [list [file join $root syn constraints a35t_clock.xdc]]
read_xdc [list [file join $root syn constraints a35t_benchmark_100mhz.xdc]]
synth_design -top $top -part $part -mode out_of_context -flatten_hierarchy rebuilt -max_dsp 0 -max_bram 0
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file synthesis_timing.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 10 -file synthesis_reg2reg.rpt
report_utilization -file synthesis_utilization.rpt
write_checkpoint synthesis.dcp
opt_design
place_design -directive Default
route_design -directive Default
write_checkpoint routed.dcp
report_timing_summary -delay_type min_max -report_unconstrained -check_timing_verbose -file route_timing.rpt
report_timing -from [all_registers -clock_pins] -to [all_registers -data_pins] -group clk -delay_type max -nworst 1 -max_paths 15 -file route_reg2reg.rpt
report_route_status -file route_status.rpt
report_utilization -file route_utilization.rpt
report_drc -file route_drc.rpt
puts "OPT_ROUTE_COMPLETE cand={cand} top={top}"
close_project
exit
""", encoding="ascii")

    env = dict(os.environ, TEMP=str(vrun / "tmp"), TMP=str(vrun / "tmp"),
               APPDATA=str(vrun / "appdata"), LOCALAPPDATA=str(vrun / "localappdata"),
               XILINX_LOCAL_USER_DATA="no")
    rc, dt, out = run_cmd(
        [str(VIVADO_BAT), "-mode", "batch", "-notrace", "-source", "run.tcl", "-log", "vivado.log", "-journal", "vivado.jou"],
        vrun, vrun / "console.log", env=env, timeout=600
    )
    if rc != 0 or f"OPT_ROUTE_COMPLETE cand={cand} top={top}" not in out:
        raise RuntimeError(f"Vivado failed on {cand} ({top}). See {vrun / 'console.log'}")
    print(f"[VIVADO COMPLETE] {cand} ({top}) in {dt:.1f}s", flush=True)


def parse_timing_summary(rpt: Path):
    txt = rpt.read_text(encoding="utf-8", errors="replace")
    m = re.search(r"Design Timing Summary[\s\S]*?\n\s*([-0-9.]+)\s+([-0-9.]+)\s+(\d+)\s+(\d+)\s+([-0-9.]+)\s+([-0-9.]+)\s+(\d+)", txt)
    if not m:
        return {}
    return {
        "wns": float(m.group(1)), "tns": float(m.group(2)), "setup_fail": int(m.group(3)),
        "whs": float(m.group(5)), "ths": float(m.group(6)), "hold_fail": int(m.group(7)),
    }


def parse_worst_reg2reg(rpt: Path):
    txt = rpt.read_text(encoding="utf-8", errors="replace")
    sl = re.search(r"Slack.*?:\s+([\d.-]+)ns", txt)
    src = re.search(r"Source:\s+(\S+)", txt)
    dst = re.search(r"Destination:\s+(\S+)", txt)
    dp = re.search(r"Data Path Delay:\s+([\d.]+)ns\s+\(logic\s+([\d.]+)ns.*?route\s+([\d.]+)ns", txt)
    lv = re.search(r"Logic Levels:\s+(\d+[^\r\n]*)", txt)
    skew = re.search(r"Clock Path Skew:\s+([\d.-]+)ns", txt)
    wns = float(sl.group(1))
    return {
        "reg2reg_wns": wns,
        "fmax_mhz": round(1000.0 / (10.0 - wns), 2),
        "dp_ns": float(dp.group(1)),
        "logic_ns": float(dp.group(2)),
        "route_ns": float(dp.group(3)),
        "skew_ns": float(skew.group(1)) if skew else 0.0,
        "levels": lv.group(1).strip(),
        "source": src.group(1),
        "dest": dst.group(1),
    }


def parse_util(rpt: Path):
    txt = rpt.read_text(encoding="utf-8", errors="replace")
    lut = re.search(r"Slice LUTs\*?\s*\|\s*(\d+)", txt)
    ff = re.search(r"Slice Registers\s*\|\s*(\d+)", txt)
    return {"lut": int(lut.group(1)), "ff": int(ff.group(1))}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify-only", action="store_true")
    ap.add_argument("--vivado-only", action="store_true")
    ap.add_argument("--reparse", action="store_true")
    ap.add_argument("--with-nf", action="store_true")
    ap.add_argument("--cands", nargs="*", default=list(CANDIDATES))
    args = ap.parse_args()

    # Ensure baseline reference trace exists
    ref_trace = REPO_ROOT / "results" / "report_trace_20261113" / "trace.csv"
    assert ref_trace.is_file(), f"Missing baseline trace {ref_trace}"

    summary = {}
    summary_file = EXP_ROOT / "experiment_summary.json"
    if summary_file.is_file():
        summary = json.loads(summary_file.read_text(encoding="utf-8"))

    for cand in args.cands:
        entry = summary.get(cand, {})
        if not args.vivado_only and not args.reparse:
            cdir = stage_candidate(cand)
            entry["verify"] = verify_candidate(cand, cdir, ref_trace)
        else:
            cdir = EXP_ROOT / cand

        if not args.verify_only:
            if not args.reparse:
                if not args.with_nf:
                    vivado_run_candidate(cand, cdir, "week13_fused_ppa_top", "vivado_f")
            vrun = cdir / "vivado_f"
            if (vrun / "route_timing.rpt").is_file():
                entry["synth"] = {
                    **parse_timing_summary(vrun / "synthesis_timing.rpt"),
                    **parse_reg_or_util(vrun / "synthesis_reg2reg.rpt", vrun / "synthesis_utilization.rpt"),
                }
                entry["route"] = {
                    **parse_timing_summary(vrun / "route_timing.rpt"),
                    **parse_reg_or_util(vrun / "route_reg2reg.rpt", vrun / "route_utilization.rpt"),
                }
            if args.with_nf and not args.reparse:
                vivado_run_candidate(cand, cdir, "prepack_nf_ppa_top", "vivado_nf")
            nfrun = cdir / "vivado_nf"
            if (nfrun / "route_timing.rpt").is_file():
                entry["nf_synth"] = {
                    **parse_timing_summary(nfrun / "synthesis_timing.rpt"),
                    **parse_reg_or_util(nfrun / "synthesis_reg2reg.rpt", nfrun / "synthesis_utilization.rpt"),
                }
                entry["nf_route"] = {
                    **parse_timing_summary(nfrun / "route_timing.rpt"),
                    **parse_reg_or_util(nfrun / "route_reg2reg.rpt", nfrun / "route_utilization.rpt"),
                }
        summary[cand] = entry
        summary_file.write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")


def parse_reg_or_util(reg_rpt: Path, util_rpt: Path):
    d = parse_worst_reg2reg(reg_rpt)
    d.update(parse_util(util_rpt))
    return d


if __name__ == "__main__":
    main()
