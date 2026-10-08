"""Update existing Markdown status files; do not create Markdown files."""
import json
import re
from pathlib import Path

root = Path(__file__).resolve().parents[1]
summary = json.loads((root / "results/week9_implementation/summary.json").read_text(encoding="utf-8"))
accepted = summary["components"].get("multiplier_acceptance")
numerical = (f"ModelSim đối chiếu {accepted['comparedTransactions']:,} giao dịch, "
             f"hủy {accepted['resetAborts']:,} giao dịch bằng reset,0 mismatch."
             if accepted else "Kiểm 10⁷ RTL đang chạy; chưa có kết quả nghiệm thu lượt lớn.")
numerical = numerical.replace(",", ".") if accepted else numerical

def read(path):
    if not path.exists():
        raise RuntimeError(f"refuse to create Markdown: {path}")
    return path.read_text(encoding="utf-8-sig")

def write(path, text):
    path.write_text(text, encoding="utf-8")

def append_once(path, marker, body, before=None):
    text = read(path)
    if marker not in text:
        section=marker+"\n\n"+body.strip()+"\n\n"
        if before is not None:
            if before not in text:
                raise RuntimeError(f"missing section anchor: {before}")
            text=text.replace(before,section+before,1)
        else:
            text = text.rstrip()+"\n\n"+section
    elif accepted:
        text = text.replace("Kiểm 10⁷ RTL đang chạy; chưa có kết quả nghiệm thu lượt lớn.", numerical)
    write(path, text)

plan_path = root / "l1/PLAN.md"
plan = read(plan_path)
for milestone in ("W9-03", "W9-R1", "W9-R2", "W9-04", "W9-05"):
    plan = re.sub(rf"(?m)^(\| {milestone} \|.*\| )(?:không|processing)( \|)$", r"\1✅\2", plan)
plan = re.sub(r"(?m)^(\| W9-06 \|.*\| )(?:không|processing)( \|)$", r"\1processing\2", plan)
plan = plan.replace("**Bước thực thi tiếp theo là W9-03:**", "**Mốc W9-03 đã được thực hiện 09/10/2026; hợp đồng vẫn giữ:**")
write(plan_path, plan)
detail = f"""W9-03 đã kiểm shifter, cộng tổ hợp, normalize/adapter:252.455 commit trên width1/5/12/26/27, hai scheme,0 mismatch. Bank `sbm_accum` được kiểm trong core; FLOOR bỏ padding trước normalize, không đưa input_cut vào numerical sticky.

W9-R1 chốt interface `paper_ops_comb`/`paper_step_comb`: Q12/prefix7 đệm0, tie-A, anchor số hạng đầu và payload13+carry1 là giả định tái dựng; RND/complement, coefficient âm và cut trước cộng/trừ ghi riêng. W9-R2 đạt843 commit,293 bản ghi (292 bản ghi corpus/206 trường hợp phân biệt + một fixture Fig.4),0 mismatch. Output force-X=0x1ae34000. Không có bằng chứng mới để chạy R3 hoặc xác nhận RTL tác giả.

W9-04 đạt39.580 giao dịch hoàn tất và420 lượt reset hủy; width1/5/12/26/27, exact vượt N_MAX, n=0/early-stop, done=t+2 hoặc3, drain và context cố định đều được kiểm. W9-05 tích hợp parser A/B → M0/core → norm → packer với một slot dự trữ; pilot bản cuối31.840 giao dịch +160 reset hủy,0 mismatch. Reset bridge lấy mẫu rst_n; out_valid bị chặn tại cạnh reset, mỗi leaf nhả qua hai FF. RNE: L_valid=max(1,t)+7, TRUNC:max(1,t)+6; handshake khi không stall sau đó một cạnh. Thử config reserved/n>N_MAX, NaR/zero, stall dài, cạnh reset và giữ thứ tự.

{numerical}

Corpus lớn10.080.000 dòng,16 profile,36 ô mode/ops/n mỗi profile; generator exact/RNE so SoftPosit1.890.000 lượt và oracle ES3 độc lập630.000 lượt. Generator/fixture không thay nghiệm thu RTL. Verilator chưa có; `make lint` hiện trả lỗi khi thiếu công cụ thay vì skip rồi báo thành công. Harness C++ và `scripts/verify_week9_verilator.sh` đã chuẩn bị nhưng chưa build/chạy, cần đối chuẩn pilot khi có công cụ. Không tự cài công cụ ngoài quyền đã cấp.

Quartus13 phân tích/tổng hợp NB32/ES2/FLOOR/RNE đạt0 lỗi,14 warning đã phân loại (license parallel, attribute ASYNC_REG của Xilinx và constant resize có giới hạn); không có cảnh báo latch. Đây không thay strict lint, STA, CDC, PPA hay Gate4. Chỉ đổi generate/genvar để hỗ trợ compiler cũ trong hai shifter/OPS, không đổi phương trình; đã chạy lại327.440 frontend vector và843 paper commit đạt.

Bằng chứng, compiler, seed20261009, SoftPosit library hash, lệnh và SHA256: `results/week9_implementation/summary.json`; các log ở `results/week9_arithmetic`, `week9_paper`, `week9_core`, `week9_multiplier`. Gate2/tuần9 vẫn processing do lint chính thức còn thiếu; tuần4/provenance paper giữ processing. Git push bị chặn vì thư mục không phải Git checkout; không tự init/force/reset hoặc sửa thư mục khác.
"""
append_once(plan_path, "### 7.4. Triển khai và kiểm chứng — 09/10/2026", detail)

spec_path = root / "SPEC_Posit_MAC_IP.md"
spec = read(spec_path)
spec = spec.replace("Giao diện thanh ghi/token bên dưới đã chốt cho code tiếp theo; mới có OPS/SAC tổ hợp được triển khai.",
                    "Giao diện thanh ghi/token bên dưới đã chốt và đã có RTL đến multiplier standalone; nghiệm thu Gate2 còn processing.")
spec = spec.replace("Controller tương lai", "Controller")
spec = spec.replace("Đây là yêu cầu triển khai, chưa có nghiệm thu handshake/reset ở core.",
                    "Core đã kiểm lịch done/reset/context 09/10; multiplier standalone đã kiểm pilot handshake. Không suy thành Gate2 hoặc RTL MAC.")
spec = spec.replace("RTL tích hợp (hợp đồng, chưa triển khai)", "RTL tích hợp (standalone multiplier đã triển khai; MAC còn theo kế hoạch)")
spec = spec.replace("SBM/core/top/Gate2 còn triển khai theo PLAN L1 mục7.",
                    "SBM/core/top standalone đã triển khai và kiểm pilot 09/10; Gate2 còn kiểm lớn/lint theo PLAN L1 mục7. Paper RTL843 commit/Fig.4 đạt trong profile tái dựng, không xác nhận baseline gốc.")
write(spec_path, spec)
append_once(spec_path, "### 11.4 Bằng chứng RTL tuần9 — 09/10/2026", f"""SBM/normalize/adapter đã kiểm252.455 lượt; core đạt39.580 giao dịch và420 reset hủy; standalone multiplier pilot31.840 giao dịch và160 reset hủy. Cả ba suite0 mismatch. Nghiên cứu paper riêng đạt843 commit/293 bản ghi, Fig.4 force-X=0x1ae34000; không xác nhận tie/padding/guard hoặc RTL gốc. Hợp đồng normative giữ §5.5-A/§5.7/§5.9-D.

{numerical}

Gate2/tuần9 processing: thiếu lint Verilator chính thức. Quartus13 Analysis & Synthesis NB32/ES2 đạt0 lỗi,14 warning đã phân loại, không có cảnh báo latch; không thay STA/CDC/PPA. TableI không chạy lại vì chưa có thay đổi có căn cứ. Kế hoạch/bằng chứng chi tiết: PLAN L1 §7.4 và results/week9_implementation/summary.json. GitHub backup đang vướng do thư mục không có Git checkout.
""", before="## 12. Báo cáo và bảo vệ")

append_once(root / "l1/README.md", "## 22. RTL multiplier tuần9 — 09/10/2026", detail+"\nBuild generator bằng các target `gen_week9_arithmetic`, `gen_week9_core`, `gen_week9_paper`, `gen_week9_multiplier` trong Makefile L1, cùng hậu tố `.exe` và `_ubsan`. `gen_week9_paper` dùng corpus có sẵn, không đổi vector/seed. ES3 exact/RNE dùng decode + product nguyên + encoder bit-list độc lập, không gọi parser/packer L1. SoftPosit chỉ dùng ở ES0/1/2.")
append_once(root / "rtl/README.md", "## 8. Multiplier standalone và research paper — 09/10/2026", detail+"\n`posit_mul_iter` là top chỉ ghép instance. `mul_iter_wrapper` chốt cfg ở handshake E0, nhận cặp parser nguyên tử, giữ slot đến retire. `mul_iter_core` chốt context ở launch L0, `iter_ctrl` phát L1, bank term L2, `sbm_accum` commit L3. `mul_norm_comb` đồng thời thực hiện adapter không làm tròn; wrapper có một bank norm trước packer. Ports top:clk/rst_n/in_valid/in_ready/a/b/cfg_mode/cfg_n/cfg_ops/out_valid/out_ready/d/flags. ROUND_SCHEME và ROUND_MODE là tham số compile; cfg_mode/cfg_n/cfg_ops được chốt mỗi giao dịch. Baseline test EXACT_EN=OPS_EN=1; disable policy đã kiểm ở OPS đơn vị, không tuyên bố coverage full top mọi tham số tùy biến.")
append_once(root / "tb/README.md", "## 6. Kiểm chứng multiplier tuần9 — 09/10/2026", """Các suite mới: `tb_week9_arithmetic` (term/acc/norm/adapter), `tb_week9_paper` (score/commit/pack paper), `tb_week9_core` (latency/reset/context/drain) và `tb_week9_multiplier` (baseline top,16 profile, cả d và flags).

ModelSim chạy fixture trong thư mục kết quả riêng; scripts fail khi thiếu vector/marker hoặc gặp Fatal/Error. Vector bị reset hủy được đếm riêng, không tính vào ngưỡng10⁷ so RTL=L1. Lượt pilot bản cuối31.840 so sánh và160 reset,0 mismatch. Competing input được giữ trong lúc busy; output bị stall; reset quay qua parser/core/drain/output. Nguồn phải đặt config hợp lệ trước chờ in_ready vì wrapper từ chối reserved/n>N_MAX.

Harness `week9_multiplier_harness.cpp` và script Verilator đã chuẩn bị, chưa có bằng chứng build/chạy do công cụ thiếu. Verilator --no-timing bỏ CK2Q cho kiểm chức năng theo cạnh; ModelSim là bằng chứng có CK2Q. Cần đối chuẩn pilot hai engine trước nhận lượt lớn Verilator. Bằng chứng hiện tại ở `results/week9_implementation/summary.json`.

"""+numerical)
append_once(root / "scripts/README.md", "## 5. Kiểm chứng tuần9 và giới hạn quyền", """Chạy từ Posit_MAC: `verify_week9_arithmetic_modelsim.ps1`, `verify_week9_paper_modelsim.ps1`, `verify_week9_core_modelsim.ps1`; integrated pilot: `verify_week9_multiplier_modelsim.ps1 -PerProfile 2000 -RunName final_pilot`. Lượt lớn: `-PerProfile 630000 -RunName acceptance`; script chỉ đóng ngưỡng số học khi số giao dịch hoàn tất đạt10⁷, không tính reset-abort.

`summarize_week9_implementation.py` kiểm fixture Linux/Windows/UBSan, coverage và hash. `update_week9_status.py` chỉ sửa Markdown hiện có, không tạo Markdown mới. `verify_week9_verilator.sh` chỉ dùng tool đã cài, trả BLOCKED khi thiếu, không sudo/download/install. Mọi file build/log/work/temp đặt dưới Posit_MAC. Quyền cập nhật ngoài dự án chỉ dành đúng doc/TIEN_DO_DO_AN.md.

Git không có checkout: push chưa thực hiện; không tự init, thay remote, force hoặc sửa thư mục khác. Nguồn + hash được lưu local, không gọi đó là GitHub backup.
""")
ambiguity_path = root / "docs/ambiguity.md"
ambiguity = read(ambiguity_path)
ambiguity = ambiguity.replace("| RTL nhân tuần9 | processing; OPS/SAC tổ hợp đạt |", "| RTL nhân tuần9 | processing; standalone đã kiểm pilot, Gate2 còn thiếu |")
ambiguity = ambiguity.replace("còn SBM/core/top/Gate2 và lõi paper riêng theo PLAN mục7", "SBM/core/top standalone và paper trace đã kiểm; lượt lớn/lint theo PLAN mục7")
ambiguity = ambiguity.replace("| Core/MAC RTL | Chưa nghiệm thu | Reset bridge, token/drain, scoreboard và Gate2/3 còn triển khai |",
    "| Core/MAC RTL | Core và standalone đã kiểm pilot; MAC chưa triển khai | Reset/token/drain/slot đạt phạm vi pilot; Gate2/lint và Gate3 còn mở |")
write(ambiguity_path, ambiguity)
append_once(ambiguity_path, "## 4. Trạng thái sau RTL paper và core — 09/10/2026", "Paper843 commit/Fig.4 đạt cùng giả định fig3; chưa có bằng chứng mới cho tie/prefix/internal guard hoặc generator gốc, nên không chạy lại TableI. W9-03..05 đã có code/test; Gate2/tuần9 processing. Verilator/lint thiếu và Git checkout không có là hai trở ngại vận hành, không đổi mô hình để né tiêu chí.\n\n"+numerical)

progress_path = root.parent / "doc/TIEN_DO_DO_AN.md"
progress = read(progress_path)
progress = progress.replace("**Ngày cập nhật:** 08/10/2026", "**Ngày cập nhật:** 09/10/2026")
progress = progress.replace("Đã chốt giao diện lõi nhân và kiểm OPS/SAC tổ hợp; còn SBM, điều khiển lặp, tích hợp và harness/coverage", "Đã triển khai và kiểm core/multiplier standalone; còn nghiệm thu lớn/lint Gate2 và RTL MAC/Gate3")
progress = progress.replace("**Thứ tự tiếp theo:** SBM/chuẩn hóa tuần9 → lõi paper tối thiểu và đối chiếu trace → controller/multiplier top/Gate2", "**Thứ tự tiếp theo:** Hoàn tất kiểm lớn/lint multiplier tuần9 — Gate2")
progress = progress.replace("Giao diện và OPS/SAC tổ hợp đã kiểm; còn SBM, core tuần tự, top và Gate2. Lõi paper nghiên cứu giữ riêng", "Đã triển khai SBM/core/multiplier và kiểm pilot; paper trace đạt phạm vi tái dựng. Còn nghiệm thu lớn/lint Gate2; chưa chốt baseline gốc")
write(progress_path, progress)
append_once(progress_path, "### 4.8. Ngày 09/10/2026", """| STT | Mốc / nhóm công việc | Kết quả chính | Trạng thái |
| --- | --- | --- | --- |
| 1 | Lõi nhân RTL và tích hợp standalone — tuần9 | Hoàn thiện số học, controller và multiplier; kiểm core, reset/stall/latency và pilot đạt. Còn ngưỡng nghiệm thu/lint Gate2 | processing |
| 2 | Đối chiếu paper bằng RTL tối thiểu | Trace phân biệt và Fig.4 khớp profile tái dựng; chưa có bằng chứng mới để chốt baseline gốc hoặc đổi kết quả TableI | ✅ |
| 3 | Hồ sơ kiểm chứng và bảo toàn dữ liệu | Đồng bộ tài liệu, lưu corpus/log/hash; GitHub backup còn vướng do chưa có Git checkout | processing |
""", before="### 4.9. Mẫu cập nhật tiếp theo")
if accepted:
    progress = read(progress_path).replace("Còn ngưỡng nghiệm thu/lint Gate2", "Đạt ngưỡng số học10⁷; còn lint chính thức để đóng Gate2")
    write(progress_path, progress)
print("Updated existing week9 documents; Gate2 remains processing")
