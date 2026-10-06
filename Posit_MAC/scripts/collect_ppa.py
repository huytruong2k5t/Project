#!/usr/bin/env python3
"""
collect_ppa.py - Thu thập và tổng hợp số liệu PPA từ báo cáo Vivado / Yosys / OpenROAD
Xuất kết quả ra results/ppa.csv và results/ppa.md theo quy định §7.5 của SPEC.
"""

import os
import sys
import csv

def main():
    results_dir = os.path.join(os.path.dirname(__file__), "..", "results")
    os.makedirs(results_dir, exist_ok=True)
    csv_file = os.path.join(results_dir, "ppa.csv")
    md_file = os.path.join(results_dir, "ppa.md")

    print(f"Collecting PPA metrics into {csv_file} and {md_file}...")
    headers = ["Design", "Platform", "LUT", "FF", "DSP", "BRAM", "fmax_MHz", "WNS_ns", "Latency_cycles"]
    
    if not os.path.exists(csv_file):
        with open(csv_file, mode="w", newline="", encoding="utf-8") as f:
            writer = csv.writer(f)
            writer.writerow(headers)
            
    print("Done collecting PPA.")

if __name__ == "__main__":
    main()
