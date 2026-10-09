"""Synchronize existing documentation after observed autonomous RTL PASS."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
data = json.loads((root / "results/paper_top/windows/summary.json").read_text(encoding="utf-8-sig"))
audit = json.loads((root / "results/paper_top/audit.json").read_text())
if data["status"] != "PASS" or audit["status"] != "PASS":
    raise RuntimeError("observed PASS evidence required")

contract = """`paper_mul_iter` là top structural riêng, logic trong `paper_mul_wrapper` và `paper_norm_comb`; cố định posit32/ES3, fraction12, PT2 prefix7 đệm0/tie-A, complement/RND, anchor số hạng đầu, accumulator Q2.12/14 bit và per-term FLOOR trước áp dấu, output cut12/TRUNC. Các lựa chọn tái dựng giữ nguyên; không đổi hợp đồng normative. `n_terms=1..8` đếm cả số hạng đầu, khác `cfg_n` normative; 0 và9..15 không được nhận. `force_a` phục vụ fixture/so fixed-A, bình thường0. NaR ưu tiên Zero.

E0 nhận A/B/n/force nguyên tử qua valid/ready; chốt X/Y, sign, sf_base, anchor và limit. Mỗi cạnh tiếp theo tự cập nhật một term cùng mantissa/exponent/coefficient/accumulator; dừng khi residual0 hoặc đủ n_terms. Sau t commit, cạnh E(t+1) chốt kết quả normalize→packer và phát out_valid; special t=0. Một slot giữ kết quả tới retire, không nhận thêm khi busy/stalled. `reset_n` assert bất đồng bộ, deassert qua hai FF tại wrapper; reset hủy giao dịch và chặn valid/ready/trace. Đây là lịch research địa phương, chưa xác nhận pipeline/timing của tác giả.

ModelSim10.1d đạt **17.181 giao dịch hoàn tất /65.710 commit,0 mismatch**. Bao gồm292 bản ghi corpus phân biệt cũ + fixture Fig.4, toàn4096 fraction A Q12 ở n1/3/8,100 cặp corner x3 giá trị n x2 policy force,500 cặp random x n1..8; seed20261009. Đối chiếu thụ động trace trước/sau từng vòng và output; không cấp lại trạng thái, không hierarchical force/write. Audit xác nhận843 commit cũ giống hoàn toàn, Linux/Windows/UBSan fixture MATCH; reference residual Q96 độc lập kiểm power/coefficient/accumulator/pack.

Fig.4 force-X: accumulator4616→5770→5914, output **0x1ae34000**. Kiểm216 special,24.036 term âm,14.199 term0,45.468 term có tail,1.082 dừng sớm,178 stall96 chu kỳ và4 reset hủy (sau capture, giữa vòng, PACK, HOLD) đạt; config/context đổi khi busy không ảnh hưởng giao dịch đang sở hữu. Không nghiệm thu flags riêng của paper, code coverage, lint, STA/PPA hoặc Gate2 bằng suite này.

Bằng chứng: `results/paper_top/windows/summary.json`, `results/paper_top/audit.json`; lệnh `make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan`, `scripts/verify_paper_top_modelsim.ps1`, `scripts/audit_paper_top.py`. Compiler/seed/lệnh/hash được lưu cùng kết quả. Không có thay đổi số học hoặc bằng chứng nguồn mới: **không chạy pilot TableI**, baseline gốc và tuần4 tiếp tục processing; Gate2 normative giữ trạng thái trước đó.
"""

def append_once(relative, heading, body):
    path = root / relative
    text = path.read_text(encoding="utf-8-sig")
    if heading not in text:
        path.write_text(text.rstrip()+"\n\n"+heading+"\n\n"+body.rstrip()+"\n", encoding="utf-8")

append_once("l1/PLAN.md", "### 7.5. Top paper hồi tiếp tự động — 09/10/2026", contract)
append_once("l1/README.md", "## 23. Top paper hồi tiếp tự động — 09/10/2026", contract)
append_once("rtl/README.md", "## 9. Top paper hồi tiếp tự động — 09/10/2026", contract)
short = """`paper_mul_iter`/`paper_mul_wrapper`/`paper_norm_comb` đã tự chạy từ A/B đến kết quả; ModelSim17.181 giao dịch và65.710 commit đạt0 mismatch,843 commit corpus cũ giữ nguyên, Fig.4=0x1ae34000. Linux/Windows/UBSan fixture MATCH; reset/stall/context/early-stop/special đạt trong suite. Hợp đồng research cố định posit32ES3/Q12, n_terms1..8, outputTRUNC; chi tiết PLAN L1 §7.5 và results/paper_top/{windows/summary,audit}.json. Không có nguồn mới hoặc thay đổi số học nên không chạy TableI; provenance baseline gốc và Gate2 vẫn processing.
"""
append_once("docs/ambiguity.md", "## 5. Top paper tự hồi tiếp — 09/10/2026", short)
append_once("tb/README.md", "## 7. Kiểm top paper tự hồi tiếp — 09/10/2026", short + "\nBench `tb_paper_mul_iter.sv` chỉ điều khiển cổng công khai A/B/n_terms/force_a/reset/valid/ready, đọc trace thụ động; không nạp state DUT từ fixture. Latency được kiểm E(t+1), t là số commit thực tế. Có4 reset hủy không tính vào17.181 completed,178 output hold96cycles và kiểm cả8 encoding n_terms không hợp lệ.\n")
append_once("scripts/README.md", "## 6. Tái chạy top paper tự hồi tiếp — 09/10/2026", short + "\nTrong WSL không nạp profile, cd vào Posit_MAC, đặt TMPDIR trong results/paper_top/tmp rồi make -C l1 gen_paper_top gen_paper_top.exe gen_paper_top_ubsan. Sinh fixture Linux/UBSan theo lệnh trong audit.json; PowerShell chạy scripts/verify_paper_top_modelsim.ps1, tiếp đó chạy scripts/audit_paper_top.py bằng Python có sẵn. ModelSim work/transcript/log/wave/temp đều ở results/paper_top; compiler timescale1ns/1ps nằm ở lệnh vlog. Không cài/sửa công cụ hệ thống.\n")
spec_path = root / "SPEC_Posit_MAC_IP.md"
spec = spec_path.read_text(encoding="utf-8-sig")
heading = "### 11.5 Top paper tự hồi tiếp — 09/10/2026"
if heading not in spec:
    spec = spec.replace("## 12. Báo cáo và bảo vệ", heading+"\n\n"+short+"\n## 12. Báo cáo và bảo vệ", 1)
    spec_path.write_text(spec, encoding="utf-8")
progress = root.parent / "doc/TIEN_DO_DO_AN.md"
text = progress.read_text(encoding="utf-8-sig")
text = text.replace("Trace phân biệt và Fig.4 khớp profile tái dựng; chưa có bằng chứng mới để chốt baseline gốc hoặc đổi kết quả TableI",
                    "Ghép top paper tự chạy từ A/B; kiểm từng vòng và kết quả đạt0 mismatch, giữ nguyên trace/Fig.4. Baseline gốc/TableI còn processing")
progress.write_text(text, encoding="utf-8")
print("Updated existing PLAN/SPEC/READMEs/ambiguity/progress; no new Markdown")
