# Đo FPGA A35T — 05/11/2026

Part hiện dùng: xc7a35tcpg236-1. Benchmark clock10ns, setup/hold user uncertainty0.1ns, input delay max/min2.5ns, output max0.5ns/min0ns.

Recipe NF/F: refactored_mac_synth.tcl, report_mac_f2f.tcl và runner run_feedforward_ppa.py. Phải dùng snapshot đã verification PASS; không compile đệ quy toàn bộ RTL. Quire có quire_synth_only.tcl/report_quire_f2f.tcl và measure_quire_synth.py.

Clock/I/O XDC được đọc trước synthesis. Recipe synthesis-only không place/route/bitstream. quire_ooc.tcl là luồng route riêng, chỉ chạy khi được yêu cầu.

Hai khóa nguồn NF/F05/11 không tự chứng minh timing sau route. Các số F2F và nghịch đảo1000/F2F trong báo cáo cũ là ước lượng unplaced của đúng snapshot ngày đo. Hold, I/O và setup/skew/uncertainty phải được xét riêng khi công bố Fmax.

Đã gỡ fixed32_3_release.json và opt12_120mhz_release.json cũ. Giữ constraints và báo cáo lịch sử làm dữ liệu đối chiếu; không gọi chúng là release đang dùng.
