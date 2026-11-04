# Golden model NF/F Posit(32,3)

Hai phiên bản nguồn hiện tại đã khóa tại [releases/current.json](../releases/current.json), kiểm lại bằng golden với100k completed mỗi NF/F và ModelSim9940 completed mỗi lõi. Xem [gói05/11](../releases/nf_f_20261105/README.md). Báo cáo cũ bên dưới chỉ để đối chiếu; source/khóa cũ đã gỡ theo yêu cầu.

Đã có golden độc lập cho cấu hình hiện tại: Posit32/ES3, fraction đầu vào12 bit, FULL_TERM26/Q24, OPS0/1, n0..12, RNE và5 cờ. Với tích approximate P_hat theo hợp đồng:

- NF: `R(R(P_hat) + C)`.
- F: `R(P_hat + C)`.

| Thành phần | Đường dẫn | Vai trò |
|---|---|---|
| Golden C++ | [full_term_reference.hpp](../tb/opt17/full_term_reference.hpp) | `opt17_reference::product/mac`: chọn bit và nhân số nguyên dạng đóng, không lặp SAC như DUT. |
| Oracle full-grid | [week12_fused_reference.hpp](../tb/week12_fused_reference.hpp) | `week12_reference::Oracle<32,3>`: decoder/encoder riêng, cộng/trừ trên lưới2^-532 bằng số nguyên1024 bit và RNE. |
| Golden Python | [gen_refactored_mac_vectors.py](../scripts/gen_refactored_mac_vectors.py) | `golden(...)`: số nguyên Python độc lập, sinh expected d/flags cho ModelSim. |
| Model thuật toán L1 | [posit_mac_full_term.hpp](../l1/include/posit_mac_full_term.hpp) | `full_term32::multiply/mac`: recurrence/checkpoint phục vụ debug, cần đối chiếu golden; không thay golden độc lập. |
| Harness NF/F | [shared_mac_harness.cpp](../tb/shared_mac_harness.cpp) | So d/flags, magnitude từng vòng, reset/stall và hồi tiếp C ở driver bên ngoài. |

Dùng `full_term32::Config{true,n,ops}`, `fused=false` cho NF và `true` cho F. Golden của DUT approximate khác Ideal giữ toàn bộ fraction26 để đo sai số. SoftPosit L0 p32 hiện có es2 nên không dùng thay oracle32/es3.

[SPEC §6.1](../SPEC_Posit_MAC_IP.md#61-golden-model-và-ideal) phân biệt golden/model/Ideal. Các báo cáo đều đi kèm snapshot/hash; không cộng PASS giữa nguồn cũ và nguồn hiện tại. Ví dụ [NF sau chỉnh parser](../results/nf_parser_recheck_20261104/summary.md), [NF/F feed-forward](../results/feedforward_a_20261104/summary.md). Main52 điểm×10M và coverage mới chưa được thay bằng regression nhỏ.

Trong WSL, từ gốc Posit_MAC, chọn root/tag chưa tồn tại:

```sh
export SHARED_RESULTS_ROOT=results/nf_f_golden_replay01
export SHARED_BUILD_TAG=replay01
python3 -B scripts/verify_shared_multiplier.py build nf
python3 -B scripts/verify_shared_multiplier.py build f
python3 -B scripts/verify_shared_multiplier.py run nf 100000 mixed -1 -1
python3 -B scripts/verify_shared_multiplier.py run f 100000 mixed -1 -1
```

ModelSim dùng `scripts/run_refactored_mac.ps1 -Stage Verify -RunRoot <mới>`; runner sinh fixture Python và snapshot nguồn. Giao diện NF/F hiện nhận trực tiếp C, không có thanh ghi hồi tiếp nội bộ.
