import csv
import json
from collections import Counter
from pathlib import Path

folder = Path(__file__).resolve().parent

def rows(label, name):
    return list(csv.DictReader((folder/label/name).open(encoding='utf-8-sig')))

def properties(label):
    data = {}
    for line in (folder/label/'critical_path_properties.txt').read_text().splitlines():
        parts = line.split(None,3)
        if len(parts)==4 and parts[2] in ('true','false'):
            data[parts[0]]=parts[3]
    return data

old, new = properties('f_old'), properties('f_new')
assert old['STARTPOINT_PIN']==new['STARTPOINT_PIN']
assert old['ENDPOINT_PIN']==new['ENDPOINT_PIN']
assert old['SKEW']==new['SKEW'] and old['UNCERTAINTY']==new['UNCERTAINTY']
nf_old, nf_new=properties('nf_old'), properties('nf_new')
assert nf_old['DATAPATH_DELAY']==nf_new['DATAPATH_DELAY']=='7.334'
assert (folder/'status.txt').read_text(encoding='utf-8-sig').strip()=='QUERY_COMPLETE'
fan=next(r for r in rows('f_new','high_fanout.csv') if r['net'].endswith('/c_eff[31]'))
counts=Counter('count' if '/p1_cnt_q' in pin else 'payload' if '/p1_payload_seed_q' in pin else 'sign_register' for pin in fan['sinks'].split())
assert sum(counts.values())==64
connections=rows('f_new','critical_connections.csv')
mux=[r for r in connections if r['cell'].endswith('/p1_s_q_i_1')]
assert {r['init'] for r in mux}=={"16'h0CAA"}
for value in range(16):
    c,acc,clear,mode=[bool(value&(1<<i)) for i in range(4)]
    expected=((not clear) and acc) if mode else c
    assert bool((0x0CAA>>value)&1)==expected

data={'f_old':old,'f_new':new,'nf_old':nf_old,'nf_new':nf_new,
      'new_sign_net_fanout':fan,'new_sign_fanout_classes':dict(counts),
      'f_old_count_bits':rows('f_old','parser_count_bits.csv'),
      'f_new_count_bits':rows('f_new','parser_count_bits.csv')}
(folder/'diagnosis.json').write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

text='''# Truy vấn nguyên nhân critical path sau refactor Parser/LOD — 01/11/2026

Đã mở bốn DCP synthesis NF/F trước và sau refactor, truy vấn đường F2F, từng chân count, INIT LUT, kết nối pin/net, fanout và fan-in cone. Không sửa RTL, không synthesis lại, không place/route. Checkpoint và hash truy vấn tại [manifest.json](manifest.json); cả bốn truy vấn QUERY_COMPLETE.

Kết luận: F chậm hơn vì cấu trúc LUT/net sau ánh xạ làm net delay ước lượng tăng 2.478 ns, vượt phần logic giảm 1.383 ns. NF giữ nguyên vì critical path nằm ở OPS→SAC, ngoài phần magnitude/LOD P1 vừa sửa. Đây là kết quả đo trực tiếp trên netlist; chưa tách riêng ảnh hưởng của từng thay đổi RTL.

## 1. Đúng đường F đang tăng delay

`accumulator_q_reg[31]/Q → MUX C_eff → prefix-OR/magnitude + adjacent-XOR + priority encoder → u_c/p1_cnt_q_reg[0]/D`.

Các module RTL liên quan:

- [mac_f_wrapper.sv](../source/rtl/mac_f/mac_f_wrapper.sv), dòng140: `c_eff = acc_mode ? (acc_clr ? 0 : accumulator_q) : c`.
- [posit_parser.sv](../source/rtl/parser/posit_parser.sv), dòng120–146: prefix-OR, magnitude, terminator_bits, detector_in và u_regime_detector; không có FF cắt đường giữa các phép này.
- [lod_lzd_core_fixed2.sv](../source/rtl/common/lod_lzd_core_fixed2.sv), dòng25 trở đi: casez 31 nhánh, trả về count5 bit.

| Chỉ tiêu cùng source/endpoint | Trước | Sau | Thay đổi |
| --- | ---: | ---: | ---: |
| Data Path Delay | 6.602 ns | 7.697 ns | +1.095 ns |
| Logic delay, gồm C→Q | 2.878 ns | 1.495 ns | −1.383 ns |
| Net delay ước lượng | 3.724 ns | 6.202 ns | +2.478 ns |
| Logic levels | 10 | 7 | −3 |
| Setup slack F2F | 3.147 ns | 2.052 ns | −1.095 ns |
| Skew | −0.145 ns | −0.145 ns | 0 |
| Uncertainty | 0.135 ns | 0.135 ns | 0 |

Nguồn/đích, clock và uncertainty giữ nguyên; số FF F giữ820. Không phải tăng số chu kỳ hay đổi constraint làm kết quả xấu đi. Net delay hiện chiếm80.58% data delay.

Bằng chứng: [đường cũ](f_old/critical_detailed.rpt), [đường mới](f_new/critical_detailed.rpt), [property cũ](f_old/critical_path_properties.txt), [property mới](f_new/critical_path_properties.txt).

## 2. Các cell/net gây chậm trên F

Tên cell rút gọn sau `u_dut/u_wrapper/u_c/`, trừ FF accumulator.

| Cell trên đường mới | Primitive | Delay cell (ns) | Fanout net ra | Delay net ra (ns) |
| --- | --- | ---: | ---: | ---: |
| accumulator_q_reg[31] C→Q | FDCE | 0.456 | 4 | 0.765 |
| p1_s_q_i_1 — MUX chọn C_eff[31] | LUT4 | 0.295 | 64 | 1.199 |
| p1_cnt_q[0]_i_29 | LUT6 | 0.124 | 1 | 1.111 |
| p1_cnt_q[0]_i_26 | LUT5 | 0.124 | 1 | 0.902 |
| p1_cnt_q[0]_i_16 | LUT6 | 0.124 | 1 | 1.111 |
| p1_cnt_q[0]_i_8 | LUT6 | 0.124 | 1 | 0.665 |
| p1_cnt_q[0]_i_3 | LUT5 | 0.124 | 1 | 0.449 |
| p1_cnt_q[0]_i_1 → count[0] | LUT6 | 0.124 | 1 | 0.000 |
| Tổng | | 1.495 | | 6.202 |

MUX được xác nhận bằng INIT `16'h0CAA`: I0=c[31], I1=accumulator[31], I2=acc_clr, I3=acc_mode. Đã kiểm truth table đủ16 tổ hợp khớp đúng biểu thức chọn C_eff.

Bit dấu C_eff[31] phát tới64 chân tải trong parser, gồm FANOUT_CLASSES. Cùng bit dấu đi vào cả `_i_29/I1` đầu chuỗi lẫn `_i_1/I2` cuối chuỗi: có nhiều nhánh hội tụ trong cone. Tên cell `p1_s_q_i_1` không có nghĩa đây chỉ là đường sign→FF sign: đầu ra LUT này cũng phát tới logic count/payload.

Bằng chứng: [kết nối từng pin và INIT](f_new/critical_connections.csv), [danh sách64 sinks](f_new/high_fanout.csv), [primitive properties](f_new/critical_cells.txt). INIT/net chứng minh kết nối; chưa thể từ đó kết luận congestion vật lý khi chưa đặt/định tuyến.

Fanout lớn là một yếu tố, nhưng không phải toàn bộ nguyên nhân. `_i_29` và `_i_16` chỉ có fanout1 mà mỗi net vẫn bị ước lượng1.111 ns; `_i_26` thêm0.902 ns. Ba net này chiếm3.124 ns. Tổng phụ thuộc cả cách chia cone logic và mô hình net delay của các kết nối LUT chung.

## 3. Vì sao bỏ CARRY4 và dùng casez chưa đem lại timing tốt hơn

Trước đây worst path dùng5 CARRY4,3 LUT và1 MUXF7 sau LUT đầu vào. Năm cell CARRY4 cộng1.157 ns; bốn net nối nội bộ chuỗi carry chỉ cộng0.009 ns. Đường carry chuyên dụng có thể truyền nhanh dù số cell được đếm là nhiều.

Sau refactor, chuỗi đi qua1 LUT chọn C_eff và6 LUT liên tiếp trong cone magnitude/transition/priority; không còn CARRY4/MUXF7 trên worst path. Từ RTL viết phẳng không thể suy ra toàn đường chỉ3 LUT. Synthesis đã gộp các biểu thức ở ranh giới magnitude và detector: chưa có căn cứ tách sáu LUT này thành “LOD riêng sáu tầng” hay quy mọi lỗi cho casez riêng.

Fan-in cone tới count[0] trước có52 LUT +8 CARRY4 +1 MUXF7; sau có89 LUT và0 CARRY4/MUXF7. Đây là toàn cone, khác số cell trên một worst path; gồm logic chọn C_eff. Module Parser C F tăng156→205 LUT. Hai số đều cho thấy logic tổ hợp đã rộng hơn, không phải chỉ đổi cách viết mà giữ nguyên cấu trúc phần cứng.

Nguồn: [histogram cone cũ](f_old/parser_count0_cone_histogram.txt), [cone mới](f_new/parser_count0_cone_histogram.txt), hierarchy utilization trong synth_f_final của từng snapshot.

Prefix-OR hiện viết bằng truy hồi `lower_any[i] = lower_any[i-1] | p[i-1]`; mô tả này không khóa topology cân bằng. Công thức magnitude đã được verify đúng; điều cần đánh giá tiếp là cách ánh xạ chia nhóm/prefix và tải của sign. Chưa chứng minh riêng prefix-OR hay riêng casez làm tăng bao nhiêu ns, vì hai thay đổi được đưa vào cùng snapshot.

## 4. Không phải mọi bit count đều xấu như nhau

Mỗi hàng là đường có setup slack xấu nhất tới chân D tương ứng, có thể đổi source.

| Đích Parser C P1 F | Trước (ns) | Sau (ns) | Δ (ns) |
| --- | ---: | ---: | ---: |
COUNT_ROWS

K[0] là nhánh nổi bật cần xử lý; K[1] còn cải thiện. Vì vậy thay lại toàn bộ decoder theo một nhận định chung “flat luôn nhanh/chậm hơn” sẽ bỏ qua hình dạng thực của các output cone.

## 5. NF không giảm vì đang tối ưu khác đường nghẽn

`u_b/p2_frac_q_reg[9]/Q → mask/popcount → cộng/so sánh count → choose_b → swap/bypass → MUX load/feedback SAC → u_core/u_ctrl/fx_q_reg[10]/D`.

Trước/sau cùng7.334 ns = logic1.742 + net5.592 ns,8 levels. Sáu LUT trước khi tạo choose_b, một LUT swap/bypass, một MUXF7 load/feedback. choose_b có52 sinks; net trên worst path0.532 ns. LUT trước choose_b cũng có net1.111 ns. Đây không phải chỉ do một net fanout lớn.

Các cell `fx_q[0]_i_*` nằm dưới `u_a/u_b` sau rebuilt hierarchy nhưng là logic đưa fraction qua OPS vào multiplier, không phải P1 regime decoder. Cell đầu `_i_71` nhận mode_q và fraction B[9]/[10]; INIT và pin mapping xác nhận mask/count. Tên hierarchy không đủ để gán chức năng.

RTL liên quan: [ops_sel_comb.sv](../source/rtl/multiplier/ops_sel_comb.sv), dòng80–110 mask/popcount/compare, dòng147–148 chọn X/Y; [iter_ctrl.sv](../source/rtl/multiplier/iter_ctrl.sv), dòng106–125 ưu tiên launch, nhận X hoặc feedback. `popcount6` có3 output bit nên không đồng nghĩa cả bộ đếm, cộng, compare và swap sẽ nằm trong1–3 LUT vật lý.

NF hiện vẫn có EXACT_EN=1 và đường count26 bit, mặc dù mục tiêu SPEC là approximate-only. Không đặt case-analysis theo cfg_mode trong lượt đo; đường worst đi từ frac_b[9], thuộc nhóm14 bit bị mask khi approximate. Vì vậy số này là worst path của toàn phần cứng đang tổng hợp, bao gồm khả năng exact; không phải STA riêng chỉ cho mode approximate. Muốn đổi hợp đồng phần cứng hay constraints cần quyết định thiết kế rõ ràng, không loại đường chỉ để cải thiện báo cáo.

Parser C P1 NF thực tế giảm7.063→7.019 ns, vẫn dưới OPS→SAC7.334 ns. Adder S4 giảm3.922→3.450 ns. Các cải thiện cục bộ này không thể giảm whole-MAC critical khi OPS→SAC giữ nguyên.

Bằng chứng: [đường NF mới](nf_new/critical_detailed.rpt), [đường NF cũ](nf_old/critical_detailed.rpt), [pin mapping NF](nf_new/critical_connections.csv), [fanout NF](nf_new/high_fanout.csv).

## 6. Hướng xử lý theo thứ tự ưu tiên

1. F: tập trung cone sign→count[0], đặc biệt fanout64 và chuỗi LUT `_29→_26→_16→_8→_3→_1`. Thử tách hai thay đổi: carry magnitude+flat LOD và prefix magnitude+LOD cũ; cùng recipe/verification để biết đóng góp từng phần. Đây là thử nghiệm đề xuất, chưa chạy.
2. F: nếu giữ prefix magnitude, cân nhắc topology prefix/group encoder có cấu trúc rõ và giảm fanout sign; tránh chia sẻ một control xuyên nhiều cone khi nó làm tăng độ phụ thuộc. Hiệu quả phải đo lại, không bảo đảm chỉ bằng sửa cú pháp.
3. NF: tập trung count/compare/choose_b và MUX load SAC. Chốt approximate-only ở RTL nếu đó là thiết kế muốn nghiệm thu; chỉ tối ưu parser P1 sẽ không xử lý critical path hiện tại.
4. Nếu cho phép đổi latency, có thể xem xét register ở biên OPS hoặc trước decode C; cần đồng bộ handshake/context và verify lại. Không đề xuất thêm pipeline như thay đổi mặc định trong phiên chẩn đoán này.

Đã truy vấn xong, giữ nguyên RTL và constraints. Net delay trong các bảng đều là ước lượng unplaced từ DCP synthesis; chưa xác nhận khoảng cách hay tắc nghẽn routing thực tế. Các thư mục critical_path_diagnosis và critical_path_diagnosis_r2 là lượt truy vấn chưa hoàn tất; bằng chứng hoàn tất nằm trong critical_path_diagnosis_final.
'''
classes=', '.join(f'{count} {kind}' for kind,count in sorted(counts.items()))
text=text.replace('FANOUT_CLASSES',classes)
old_bits={r['bit']:float(r['data_delay_ns']) for r in data['f_old_count_bits']}
text=text.replace('COUNT_ROWS','\n'.join(f"| K[{r['bit']}] | {old_bits[r['bit']]:.3f} | {float(r['data_delay_ns']):.3f} | {float(r['data_delay_ns'])-old_bits[r['bit']]:+.3f} |" for r in data['f_new_count_bits']))
(folder/'diagnosis.md').write_text(text,encoding='utf-8')
print(json.dumps({'status':'PASS','fanout_classes':dict(counts),'report':str(folder/'diagnosis.md')},ensure_ascii=False))
