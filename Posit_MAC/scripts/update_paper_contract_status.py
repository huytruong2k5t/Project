"""Update existing documents only after source audit and RTL observation."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
report = json.loads((root / "results/paper_contract_audit/summary.json").read_text())
if report["packer"]["status"] != "PASS":
    raise RuntimeError("observed RTL evidence required")
body = """Đọc trực quan PDF2019 p2–5 (Algorithm1, Eq10–12, Table1/3/4, Fig4) và PDF2021 p3–4 (Fig3–6, TableI–III). RND/complement của2019 có căn cứ trực tiếp và fixtureTable1 tái lập powers−1/−5/−8, coefficients+/−/−. Tuy nhiên mô tả2021 III-C/Fig4 quét bit1 và n1/2 là hai lần cập nhật fraction sau khởi tạoY. Ví dụ này chỉ có term dương, nên không chứng minh nhánh round-up/term âm của RND. Không áp dụng tự động mọi chi tiết2024 cho2021.

Nghiên cứu deterministic163.840 cặp `(X_Q12,Y_Q12,n)` (4096 X,5 Y,n1..8,force-A để tách OPS) cho thấy RND và literal bit-scan không tương đương, cả khi cùng tổng số hạng hoặc khi scan tính fraction riêng. Ví dụ X6144,Y4097,n_total2: RND0x42008000, scan0x42004000. Đây là vector phân biệt giữa mô hình, chưa có output tác giả cho vector này. Fig4 force-X: n_fraction2/n_total3 cho0x1ae34000; n_total2 chỉ cho0x1ad14000. Mười hai ô Kim2019 được chép nguyên sang cột Kim2021 hỗ trợ nhãn comparator, nhưng chưa khóa ngữ nghĩa SAC/n của Proposed TableI. Giữ `n_terms` API địa phương; không tự đổi TableI thành n+1.

Reference packer C++ độc lập diễn giải đúng cổng Fig5(b): m=Rgm[4:0] XOR Rgm[5]; hai bit đầu là XNOR/XOR Rgm[5] với sign, payload29 XOR sign; dịch phải arithmetic trên31 bit rồi cộng sign và ghép Out[31]. Không gọi parser/packer L1 để tạo expected. Kiểm3.940.352 trường hợp sf−240..240 ×4096 fraction ×2 dấu với L1 đạt; ModelSim10.1d kiểm155.648 trường hợp với RTL TRUNC đạt0 mismatch. Linux/Windows/UBSan fixture MATCH, không dùng PRNG. Có8.448 raw/clamped differences ngoài miền sf−240..240 (underflow/điều khiển regime6bit wrap): clamp là chính sách đồ án, hình lược bỏ cờ/range handling; không tính các khác biệt này là lỗi RTL hoặc khẳng định tác giả dùng clamp đó.

Có thể loại khác biệt mã hóa packer trên miền Q12/scale đã kiểm; chưa loại normalize/cut nội bộ, OPS, generator hoặc khác biệt recurrence/n. Không sửa normative hay top RND đã đóng băng; không chạy pilotTableI vì chưa chọn được thay đổi số học có xác nhận nguồn duy nhất. Audit đã hoàn thành, baseline gốc/tuần4 và Gate2 vẫn processing. Bước tiếp theo cần trace/code hoặc xác nhận tác giả cho SAC/n2021 ở vector round-up, tie/prefix và internal cut; không dò seed/tham số.

Bằng chứng: results/paper_contract_audit/{summary.json,windows/summary.json,windows/source2019_trace.csv,windows/source2021_count.csv,windows/divergent.csv,windows/sac_counts.csv}; PDF/RTL/fixture SHA256, compiler và lệnh trong summary. Build `make -C l1 test_paper_contract_audit test_paper_contract_audit.exe test_paper_contract_audit_ubsan`; chạy `scripts/verify_paper_contract_modelsim.ps1` rồi `scripts/summarize_paper_contract_audit.py`.\n"""

short = """Audit trực tiếp nguồn2019/2021 và kiểm deterministic163.840 cặp cho thấy RND/complement và quét bit1 không tương đương. Fig4 khớp n_fraction2/n_total3 (0x1ae34000), nhưng n_total2 cho0x1ad14000; TableI Proposed chưa khóa cách đếm/recurrence từ nguồn. Giữ nguyên profile normative và top RND nghiên cứu, không đổi n/seed để ép bảng.

Reference cổng Fig5 độc lập khớp L1 trên3.940.352 trường hợp; ModelSim155.648 trường hợp đạt0 mismatch, Linux/Windows/UBSan MATCH.8.448 raw/clamped differences nằm ngoài miền sf−240..240, do range handling đồ án bổ sung; không phải lỗi RTL hoặc xác nhận clamp tác giả. Không chạy pilotTableI, baseline gốc/Gate2 vẫn processing. Chi tiết duy nhất tại README L1 §24; bằng chứng/lệnh/hash/compiler tại results/paper_contract_audit/{summary.json,windows/summary.json}.\n"""

def append(relative, heading):
    path = root / relative
    text = path.read_text(encoding="utf-8-sig")
    desired = body if relative == "l1/README.md" else short
    desired = desired.replace("m=Rgm[4:0] XOR Rgm[5]", "m=Rgm[4:0] XOR {5{Rgm[5]}}")
    if heading not in text:
        text = text.rstrip()+"\n\n"+heading+"\n\n"+desired
    else:
        text = text.replace(heading+"\n\n"+body, heading+"\n\n"+desired,1)
    path.write_text(text, encoding="utf-8")

for relative, heading in (
    ("l1/PLAN.md", "### 7.6. Rà soát SAC/n và packer theo nguồn — 09/10/2026"),
    ("l1/README.md", "## 24. Rà soát SAC/n và packer theo nguồn — 09/10/2026"),
    ("rtl/README.md", "## 10. Phạm vi baseline paper sau audit nguồn — 09/10/2026"),
    ("docs/ambiguity.md", "## 6. SAC/n2021 và packer Fig5 — 09/10/2026"),
    ("tb/README.md", "## 8. Kiểm packer Fig5 độc lập — 09/10/2026"),
    ("scripts/README.md", "## 7. Audit SAC/n và packer theo nguồn — 09/10/2026")):
    append(relative, heading)
spec_path = root / "SPEC_Posit_MAC_IP.md"
spec = spec_path.read_text(encoding="utf-8-sig")
heading = "### 11.6 Rà soát SAC/n và packer theo nguồn — 09/10/2026"
if heading not in spec:
    spec = spec.replace("## 12. Báo cáo và bảo vệ", heading+"\n\n"+short+"\n## 12. Báo cáo và bảo vệ",1)
else:
    spec = spec.replace(heading+"\n\n"+body, heading+"\n\n"+short,1)
spec_path.write_text(spec,encoding="utf-8")
progress = root.parent / "doc/TIEN_DO_DO_AN.md"
text = progress.read_text(encoding="utf-8-sig")
row = "| 4 | Rà soát baseline theo nguồn | Phân biệt SAC/cách đếm vòng giữa các nguồn; kiểm packer Fig5 độc lập đạt0 mismatch. Audit hoàn thành, baseline gốc vẫn processing | ✅ |\n"
if row not in text:
    text = text.replace("\n### 4.9. Mẫu cập nhật tiếp theo", row+"\n### 4.9. Mẫu cập nhật tiếp theo",1)
progress.write_text(text,encoding="utf-8")
print("Existing documentation synchronized; baseline not promoted")
