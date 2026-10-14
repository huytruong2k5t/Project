import fs from 'node:fs/promises';
import path from 'node:path';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import { createHash } from 'node:crypto';

// Execute from Posit_MAC. All generated files stay inside the project.
const root = process.cwd();
await fs.access(path.join(root, 'rtl/ops_sel_comb.sv'));
const skill = process.env.PRESENTATION_SKILL_DIR || 'C:/Users/This PC/.codex/plugins/cache/openai-primary-runtime/presentations/26.1013.11914/skills/presentations';
const runtimeModules = process.env.RUNTIME_NODE_MODULES || 'C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const python = process.env.RUNTIME_PYTHON || 'C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe';
process.env.RUNTIME_NODE_MODULES = runtimeModules;
const build = path.join(root, 'scratch/datapath_slides_20261014');
const output = path.join(root, 'presentation');
const revision = process.argv[2] || 'r1';
await fs.mkdir(build, { recursive: true });
await fs.mkdir(output, { recursive: true });
const link = path.join(build, 'node_modules');
try { await fs.lstat(link); }
catch { await fs.symlink(runtimeModules, link, process.platform === 'win32' ? 'junction' : 'dir'); }
const require = createRequire(path.join(build, 'package.json'));
const { Presentation, PresentationFile, FileBlob } = await import(pathToFileURL(require.resolve('@oai/artifact-tool')));
const { resolvePresentationFont, finalizePresentation } = await import(pathToFileURL(path.join(skill, 'container_tools/artifact_tool_utils.mjs')));
const FONT = resolvePresentationFont({ fontFamily: 'Arial' });
const ppt = Presentation.create({ slideSize: { width: 1280, height: 720 } });
ppt.theme.defaultFont = FONT;
const C = {
  ink: '#172B4D', muted: '#53657D', wire: '#425672', pale: '#EEF2F7', border: '#CCD6E2',
  ops: '#147D92', opsLight: '#E8F6F8', sac: '#A76807', sacLight: '#FFF4DD',
  sbm: '#6943B9', sbmLight: '#F2ECFC', reg: '#244B83', regLight: '#EAF1FA',
  red: '#B44A3A', redLight: '#FFF0EC', green: '#237855', greenLight: '#E8F5ED',
};
let serial = 0;
const positions = [];
function text(slide, value, x, y, w, h, size = 24, color = C.ink, bold = false, align = 'left') {
  const s = slide.shapes.add({ geometry: 'textbox', name: `text-${++serial}`,
    position: { left: x, top: y, width: w, height: h }, fill: 'none',
    line: { width: 0, fill: 'none' } });
  s.text = value;
  s.text.style = { typeface: FONT, fontSize: size, color, bold,
    alignment: align, verticalAlignment: 'middle', wrap: 'square', autoFit: 'none',
    insets: { left: 0, right: 0, top: 0, bottom: 0 } };
  return s;
}
function rect(slide, x, y, w, h, fill, stroke = C.border, lineWidth = 1.8, name = 'box') {
  return slide.shapes.add({ geometry: 'rect', name: `${name}-${++serial}`,
    position: { left: x, top: y, width: w, height: h }, fill,
    line: { fill: stroke, width: lineWidth } });
}
function block(slide, title, detail, x, y, w, h, color, fill, size = 26) {
  const b = rect(slide, x, y, w, h, fill, color, 2, title);
  text(slide, title, x + 10, y + 13, w - 20, 39, size, color, true, 'center');
  if (detail) text(slide, detail, x + 10, y + 52, w - 20, h - 64, 23, C.ink, false, 'center');
  return b;
}
function poly(slide, points, x, y, w, h, fill, stroke, name) {
  return slide.shapes.add({ geometry: 'custom', name: `${name}-${++serial}`,
    position: { left: x, top: y, width: w, height: h }, fill,
    line: { fill: stroke, width: 2 },
    customPaths: [{ width: w, height: h, commands: [
      { moveTo: { x: points[0][0], y: points[0][1] } },
      ...points.slice(1).map(([a,b]) => ({ lineTo: { x: a, y: b } })), { close: {} },
    ] }] });
}
function mux(slide, label, x, y, w = 85, h = 104, color = C.wire, fill = 'white') {
  const s = poly(slide, [[0,0],[w,h*.2],[w,h*.8],[0,h]], x,y,w,h,fill,color,'mux');
  text(slide,label,x+3,y+h/2-18,w-10,36,23,color,true,'center');
  return s;
}
function circle(slide, label, x, y, d, color, fill='white', size=34) {
  const s=slide.shapes.add({ geometry:'ellipse', name:`operator-${++serial}`,
    position:{left:x,top:y,width:d,height:d},fill,line:{fill:color,width:2} });
  text(slide,label,x,y,d,d,size,color,true,'center');
  return s;
}
function reg(slide, label, x,y,w,h=114, detail='') {
  const s=rect(slide,x,y,w,h,C.regLight,C.reg,2,label);
  poly(slide,[[0,0],[10,7],[0,14]],x,y+h-23,10,14,'white',C.reg,'clock');
  text(slide,label,x+4,y+15,w-8,38,24,C.reg,true,'center');
  if(detail) text(slide,detail,x+8,y+52,w-16,h-72,23,C.ink,false,'center');
  return s;
}
function segment(slide, x1,y1,x2,y2, color=C.wire, arrow=false, dashed=false, width=2.5) {
  const connector = slide.shapes.add({ geometry:'connector', name:`wire-${++serial}`, kind:'straight',
    position:{left:Math.min(x1,x2),top:Math.min(y1,y2),width:Math.abs(x2-x1),height:Math.abs(y2-y1),
      horizontalFlip:x2<x1,verticalFlip:y2<y1},
    line:{fill:color,width,style:dashed?'dashed':'solid'},
    tail:{type:arrow?'triangle':'none',width:'sm',length:'sm'} });
  connector.sendToBack();
  return connector;
}
function wire(slide, pts, color=C.wire, arrow=true, dashed=false, width=2.5) {
  for(let i=1;i<pts.length;i++) segment(slide,...pts[i-1],...pts[i],color,arrow&&i===pts.length-1,dashed,width);
}
function label(slide,value,x,y,w=170,color=C.muted,size=23,align='center') {
  return text(slide,value,x,y,w,34,size,color,false,align);
}
function sourceNotes(slide, notes, files) {
  slide.speakerNotes.text = notes + '\n\nNguồn RTL và hợp đồng:\n' + files.map(f => path.join(root,f)).join('\n');
}
function slide(title, subtitle) {
  const s=ppt.slides.add();
  s.background.fill='white';
  text(s,title,48,32,1184,62,44,C.ink,true);
  text(s,subtitle,48,99,1184,42,24,C.muted);
  segment(s,48,155,1232,155,C.border,false,false,1);
  const number=ppt.slides.items.length;
  text(s,`${number} / 7`,1155,675,76,23,18,C.muted,false,'right');
  return s;
}
function note(slide, title, body, x,y,w,color=C.ink) {
  text(slide,title,x,y,w,35,26,color,true);
  text(slide,body,x,y+44,w,88,24,C.muted);
}
function table(slide, values, x,y,w,h, widths, tint = C.regLight, fontSize=24) {
  const t=slide.tables.add({ rows:values.length,columns:values[0].length,left:x,top:y,width:w,height:h,
    columnWidths:widths,values });
  t.borders.assign({fill:C.border,width:1,style:'solid'});
  for(let r=0;r<values.length;r++) for(let c=0;c<values[0].length;c++) {
    const cell=t.getCell(r,c);
    cell.fill = r===0 ? tint : (r%2 ? 'white' : '#F7F9FC');
    cell.text.style = {typeface:FONT,fontSize,color:r===0?C.ink:C.wire,bold:r===0,
      alignment:'center',verticalAlignment:'middle',insets:{left:9,right:9,top:8,bottom:8}};
  }
  return t;
}

// 1. Actual hierarchy and stage boundaries.
{
  const s=slide('Datapath nhân lặp: OPS, SAC và SBM',
    'Profile minh họa: posit32/ES=3, FRAC_W=12, FLOOR, EXACT_EN=1');
  label(s,'A/B đã parse',45,198,170);
  label(s,'L0: launch',315,198,120,C.reg);
  label(s,'L1',620,198,65,C.reg);
  label(s,'L2',948,198,65,C.reg);
  label(s,'L3: commit',1044,198,175,C.reg);
  block(s,'OPS','Chọn X / Y',64,277,173,120,C.ops,C.opsLight);
  reg(s,'R0',292,277,65,120);
  block(s,'SAC','Tạo S\nCập nhật fx',412,277,172,120,C.sac,C.sacLight);
  reg(s,'R1',622,277,63,120);
  block(s,'SBM Shift','Dịch Y\nCắt term',731,277,165,120,C.sbm,C.sbmLight);
  reg(s,'R2',948,277,63,120);
  block(s,'SBM Acc','Cộng term\nGiữ acc_q',1056,277,176,120,C.sbm,C.sbmLight);
  for(const [a,b] of [[237,292],[357,412],[584,622],[685,731],[896,948],[1011,1056]]) wire(s,[[a,337],[b,337]]);
  label(s,'fx',358,298,52,C.sac,23);
  label(s,'S',685,294,46,C.sac);
  label(s,'term',896,298,52,C.sbm,22);
  wire(s,[[324,277],[324,235],[818,235],[818,277]],C.ops);
  text(s,'Y giữ ổn định trong y_q',415,165,347,29,23,C.ops,false,'center');
  wire(s,[[1117,397],[1117,438],[1165,438],[1165,397]],C.sbm);
  label(s,'feedback acc_q',986,443,245,C.sbm);
  wire(s,[[488,397],[488,438],[540,438],[540,397]],C.sac);
  label(s,'feedback fx_q / scale_q',390,443,325,C.sac);
  text(s,'P_hat = Y + Σ trunc_Q12(Y / 2^Sᵢ)',48,508,1060,52,32,C.ink,true);
  text(s,'Chốt dấu và sf_A + sf_B tại launch. Sau core_done, chuyển acc sang normalize / round.',48,573,1125,70,24,C.muted);
  sourceNotes(s,
    'OPS là Operand Selector. SAC là Shift Amount Calculator. SBM là Shift-Based Multiplier. S là lượng dịch tích lũy, khác scale factor sf của Posit. Sơ đồ tổng rút gọn R0 thành bank context gồm y_q, mode/sign/sf và state SAC. R1 nằm trong iter_ctrl, R2 là t2_term và token trong mul_iter_core, L3 là acc trong sbm_accum. Các thanh ghi cùng clock. Y đi thẳng tới shifter và giữ ổn định cho toàn giao dịch. Core xử lý một giao dịch và giải phóng khi release_result; không có FIFO chồng lấn transaction. Công thức là trên mantissa/lưới FLOOR, dấu và sf được ghép sau core. ACC_W32/3=54 với EXACT_EN=1, dù payload approx chỉ16 bit.',
    ['rtl/ops_sel_comb.sv','rtl/iter_ctrl.sv','rtl/mul_iter_core.sv','rtl/sbm_shift_comb.sv','rtl/sbm_accum.sv','SPEC_Posit_MAC_IP.md']);
}

// 2. OPS selection, arithmetic metadata, and right-aligned effective fraction.
{
  const s=slide('OPS: chọn toán hạng điều khiển vòng lặp',
    'OPS=1 chọn fraction có ít bit 1 hơn. Hòa popcount giữ A làm X');
  label(s,'frac_A [25:0]',47,198,215,C.ops);
  label(s,'frac_B [25:0]',47,372,215,C.ops);
  block(s,'Chọn độ rộng','Exact: 26 bit\nApprox: 12 MSB',264,198,235,122,C.ops,C.opsLight);
  block(s,'Chọn độ rộng','Exact: 26 bit\nApprox: 12 MSB',264,372,235,122,C.ops,C.opsLight);
  wire(s,[[59,272],[264,272]],C.ops);
  wire(s,[[59,444],[264,444]],C.ops);
  block(s,'Popcount A','Cây cộng cân bằng',542,194,250,115,C.ops,C.opsLight);
  block(s,'Popcount B','Cây cộng cân bằng',542,371,250,115,C.ops,C.opsLight);
  wire(s,[[499,247],[542,247]],C.ops);
  wire(s,[[499,425],[542,425]],C.ops);
  circle(s,'B<A',835,306,63,C.ops,C.opsLight,22);
  wire(s,[[792,249],[866,249],[866,306]],C.ops);
  wire(s,[[792,425],[866,425],[866,369]],C.ops);
  mux(s,'SEL',972,218,84,112,C.ops,C.opsLight);
  mux(s,'SEL',972,420,84,112,C.ops,C.opsLight);
  text(s,'0',979,234,20,25,23,C.ops);
  text(s,'1',979,290,20,25,23,C.ops);
  text(s,'1',979,436,20,25,23,C.ops);
  text(s,'0',979,492,20,25,23,C.ops);
  // A_effective feeds X input 0 and Y input 1. B_effective feeds opposite inputs.
  wire(s,[[499,250],[517,250],[517,173],[938,173],[938,246],[972,246]],C.ops);
  wire(s,[[499,440],[520,440],[520,552],[941,552],[941,504],[972,504]],C.ops);
  wire(s,[[499,449],[508,449],[508,333],[927,333],[927,302],[972,302]],C.ops);
  wire(s,[[499,283],[528,283],[528,350],[922,350],[922,448],[972,448]],C.ops);
  wire(s,[[898,337],[955,337],[955,370],[1013,370],[1013,330]],C.wire,true,true);
  wire(s,[[1013,370],[1013,420]],C.wire,true,true);
  wire(s,[[1056,274],[1232,274]],C.ops);
  wire(s,[[1056,476],[1105,476]],C.ops);
  block(s,'1.fY','Y mant',1106,420,126,112,C.ops,C.opsLight,26);
  label(s,'X fraction',1051,228,177,C.ops);
  text(s,'X: chỉ fraction\nY: có hidden bit',982,577,246,70,24,C.ops,true);
  text(s,'choose_b = OPS_EN && (cfg_ops == 1) && (count_B < count_A)',48,582,860,40,24,C.ink);
  text(s,'sign = s_A XOR s_B       sf_base = sf_A + sf_B',48,626,940,37,24,C.muted);
  sourceNotes(s,
    'OPS là khối tổ hợp, không chứa bank M0. Trong approx, cắt12 MSB rồi đặt vào12 LSB của vector26 bit effective, phần cao bằng0. Popcount đếm vector effective này. PAD_N=32 cho F26, hai cây count5 tầng logic cộng. cfg_ops0 luôn X=A; cfg_ops1 chọnB chỉ khi countB<countA. Hai mux chọn X và Y ngược nhau, nên Y là toán hạng còn lại. Y hidden ở vị trí12 khi approx và26 khi exact, output27 bit. input_cut OR các bit thấp bị bỏ của A/B. sf là11 bit signed cho profile32/3. Các input cfg reserved bị wrapper từ chối. Sơ đồ chỉ vẽ datapath chính và nêu sign/sf ở dưới.',
    ['rtl/ops_sel_comb.sv','rtl/mac_nf_wrapper.sv','SPEC_Posit_MAC_IP.md']);
}

// 3. One SAC recurrence with local state owned by iter_ctrl.
{
  const s=slide('SAC: quét bit 1 và tính lượng dịch tích lũy',
    'sac_step_comb là tổ hợp. iter_ctrl giữ fx_q, scale_q và số vòng');
  reg(s,'fx_q',48,234,148,119,'W bit');
  block(s,'LOD','K = clz(fx)\nvld',252,214,185,112,C.sac,C.sacLight);
  circle(s,'+1',482,235,64,C.sac,C.sacLight,30);
  circle(s,'+',653,235,64,C.sac,C.sacLight,38);
  reg(s,'R1',837,234,155,119,'scale = S');
  wire(s,[[196,272],[252,272]],C.sac);
  wire(s,[[437,270],[482,270]],C.sac);
  wire(s,[[546,268],[653,268]],C.sac);
  wire(s,[[717,267],[837,267]],C.sac);
  label(s,'K',437,218,44,C.sac);
  label(s,'sa',551,218,97,C.sac);
  label(s,'S_next',718,218,113,C.sac);
  reg(s,'scale_q',564,346,177,112,'S hiện tại');
  wire(s,[[652,346],[652,324],[685,324],[685,299]],C.sac);
  block(s,'Dịch trái','fx_next = fx << sa',254,430,282,106,C.sac,C.sacLight);
  wire(s,[[196,295],[220,295],[220,477],[254,477]],C.sac);
  wire(s,[[515,299],[515,374],[395,374],[395,430]],C.wire,true,true);
  wire(s,[[536,477],[787,477],[787,575],[123,575],[123,353]],C.sac);
  label(s,'fx_next cập nhật ở cạnh clock',228,579,438,C.sac);
  wire(s,[[789,267],[789,368],[741,368]],C.sac);
  label(s,'S_next',747,385,130,C.sac);
  block(s,'Kiểm tra','S_next ≤ W\nfx_next == 0',1037,232,195,138,C.wire,C.pale,26);
  wire(s,[[815,267],[815,362],[1014,362],[1014,224],[1134,224],[1134,232]],C.wire);
  wire(s,[[780,477],[1134,477],[1134,370]],C.wire);
  text(s,'sa = K + 1       S_next = S + sa',48,639,1000,33,26,C.ink,true);
  sourceNotes(s,
    'LOD MODE0 tìm bit1 đầu tiên từ MSB, trả số leading zeros K và leading_valid. Nếu vld=0, không tạo term, sa0, scale_next giữ scale, fx_next giữ fx và exhausted1. Với vld1, step=K+1, scale_sum tính rộngS_W+1 và kiểm không vượtW_X. state_error nếu scale>W hoặc scale_sum>W. Chỉ term_valid khi vld&&!error. Dịch trái sa loại leading zeros và bit1 vừa xử lý. Khoanh các bank fx_q,scale_q là state bên ngoài sac_step_comb trong iter_ctrl. R1 là token xuấtscale đã chốt, không phải bank feedback dùng lại để đếm vòng. ApproxW12, exactW26, S_W5 ở32/3. iter_ctrl có hai instance SAC và mux mode; hình vẽ một đường active để dễ đọc.',
    ['rtl/sac_step_comb.sv','rtl/lod_lzd_core.sv','rtl/iter_ctrl.sv','SPEC_Posit_MAC_IP.md']);
}

// 4. Shift and cut, in physical versus useful grids.
{
  const s=slide('SBM Shift: tạo số hạng trên cùng lưới tích lũy',
    'Profile FLOOR: cắt từng term về12 bit fraction trước khi cộng');
  reg(s,'y_q',48,272,134,119,'27 bit');
  block(s,'Căn lưới','Approx: << 2\nExact: << 26',227,263,235,130,C.sbm,C.sbmLight);
  block(s,'Dịch phải','y_base >> S',515,263,240,130,C.sbm,C.sbmLight);
  block(s,'FLOOR','term[1:0] = 0',805,263,224,130,C.sbm,C.sbmLight);
  reg(s,'R2',1078,271,154,119,'term / tail');
  for(const [a,b] of [[182,227],[462,515],[755,805],[1029,1078]]) wire(s,[[a,330],[b,330]],C.sbm);
  wire(s,[[633,194],[633,263]],C.sac);
  label(s,'S từ R1',552,169,166,C.sac);
  wire(s,[[348,393],[348,560],[1232,560]],C.sbm);
  label(s,'y_base tới accumulator',350,523,313,C.sbm);
  block(s,'OR phần bỏ','term_tail',677,440,259,100,C.red,C.redLight);
  wire(s,[[647,393],[647,489],[677,489]],C.red);
  wire(s,[[936,489],[1155,489],[1155,390]],C.red);
  text(s,'FLOOR: term_tail đi vào metadata mất thông tin. sticky_acc vẫn bằng0.',48,574,1150,55,24,C.muted);
  text(s,'ACC_W vật lý = 54 bit     Payload approx = 16 bit     P_hat hữu ích = Q12 / 14 bit',48,636,1167,31,24,C.ink,true);
  sourceNotes(s,
    'sbm_shift_comb nhận y_mant right-aligned từ OPS: approximatehidden ởbit12, exacthidden ởbit26. Approx <<2 tạo Q14 trong bank vật lý54 bit. FLOORmask2LSB sau shift tạo term là bội4, nên chiaacc>>2 lấy Q12. Exact <<F tạo gridQ52. shift_discard=S+2 trongapproxFLOOR, hoặcS các modekhác; term_tail ORy_base bits thấp dưới shift_discard. init_only buộcterm0 vàtail0. VớiFLOOR, numerical_tail giữORterm_tail nhưng numerical_sticky cho R(P_hat) bằng0; không dùng metadata cut khôi phục giá trị. Có thể chọn JAM ởstandalonelegacy, NFtop hardwireFLOOR. R2 lưu term vàtail trongmul_iter_core, y_base vẫn là dây tổ hợp từ y_q ổn định. Slide không vẽ muxexact/approx vàinit đầy đủ; ghi rõ trongnotes.',
    ['rtl/sbm_shift_comb.sv','rtl/mul_iter_core.sv','rtl/sbm_accum_comb.sv','rtl/mul_prepack_norm_comb.sv','SPEC_Posit_MAC_IP.md']);
}

// 5. Accumulator update, first/init and carried metadata.
{
  const s=slide('SBM Accumulator: commit term và giữ tổng',
    'first chọn hidden term. init_only chỉ nạp Y. commit_valid cho phép cập nhật');
  label(s,'y_base',48,202,166,C.sbm);
  label(s,'acc_q',48,344,166,C.sbm);
  wire(s,[[64,247],[249,247]],C.sbm);
  wire(s,[[64,389],[224,389],[224,316],[249,316]],C.sbm);
  mux(s,'MUX',249,219,100,128,C.sbm,C.sbmLight);
  wire(s,[[299,180],[299,219]],C.wire,true,true);
  label(s,'first',344,167,131,C.muted);
  circle(s,'+',521,247,76,C.sbm,C.sbmLight,43);
  wire(s,[[349,283],[521,283]],C.sbm);
  reg(s,'acc_q',768,225,183,130,'54 bit');
  wire(s,[[597,283],[768,283]],C.sbm);
  label(s,'sum[53:0]',595,223,174,C.sbm);
  wire(s,[[951,291],[1232,291]],C.sbm);
  label(s,'acc / P_hat',995,235,229,C.sbm);
  block(s,'Term / 0','init_only',371,433,201,105,C.sbm,C.sbmLight);
  wire(s,[[65,485],[371,485]],C.sbm);
  label(s,'term từ R2',185,438,178,C.sbm);
  wire(s,[[572,485],[633,485],[633,386],[559,386],[559,323]],C.sbm);
  wire(s,[[852,355],[852,556],[169,556],[169,389]],C.sbm);
  label(s,'Feedback tổng cũ cho commit kế tiếp',661,567,545,C.sbm);
  wire(s,[[913,177],[913,225]],C.wire,true,true);
  label(s,'commit_valid',844,150,217,C.muted);
  block(s,'Done','commit_valid\n&& last',1013,420,219,120,C.reg,C.regLight,25);
  poly(s,[[0,0],[10,7],[0,14]],1013,514,10,14,'white',C.reg,'clock-done');
  text(s,'first=1: acc_next = y_base + term\ninit_only=1: acc_next = y_base',48,610,900,65,26,C.ink,true);
  sourceNotes(s,
    'sbm_accum_comb sum rộng55bit đểkiểm carryerror bit54. first1 mux chọny_base thayacc; normalfirst cộngtermfraction đầu cùnghidden. init_only bỏphépcộngterm, khôngY+Y. first reset numericaltail/sticky. numericaltail ORtermtail; sticky chỉOR khi exact hoặcROUND_SCHEME1, NFapproxFLOORgiữ0. sbm_accum chốt acc, iterations_done, approx_cut_o vàtails khi commit_valid. done <=commit_valid&&last, khôngphảiđoánkhibitfxhết ởSAC. Córesetleaf asyncassert/syncrelease2FF vàrun_ready; khôngvẽmạngresetđểgiữdatapathdễđọc. Diagram first control arrows representboolean first, labelsnearport. Bankacc giữ output khi khôngcommit. Kếtquả cầnnormalize vàRNE bênngoàicore; khôngpacktrongaccumulator.',
    ['rtl/sbm_accum_comb.sv','rtl/sbm_accum.sv','rtl/mul_iter_core.sv','SPEC_Posit_MAC_IP.md']);
}

// 6. Concrete edge schedule and token drain.
{
  const s=slide('Pipeline core: token đi cùng số hạng',
    'Ví dụ hai vòng fraction. L0 là cạnh launch được core chấp nhận');
  block(s,'L1: SAC','scale / first / last',110,184,266,94,C.sac,C.sacLight,25);
  block(s,'L2: Shift','term / tail / token',506,184,266,94,C.sbm,C.sbmLight,25);
  block(s,'L3: Acc','commit / done',905,184,266,94,C.sbm,C.sbmLight,25);
  wire(s,[[376,232],[506,232]],C.wire);
  wire(s,[[772,232],[905,232]],C.wire);
  table(s,[
    ['Khối / cạnh','L0','L1','L2','L3','L4'],
    ['Context','Chốt X,Y','Giữ Y','Giữ Y','Giữ Y','Giữ Y'],
    ['SAC / R1','Nạp state','Token 1','Token 2','Dừng phát',''],
    ['Shift / R2','','','Term 1','Term 2',''],
    ['Accumulator','','','','Y + term 1','+ term 2\ndone=1'],
  ],48,316,1184,271,[254,186,186,186,186,186],C.regLight,23);
  text(s,'core_done sau q + 2 cạnh từ launch, với q = max(1, số vòng thực tế)',48,612,1160,38,27,C.ink,true);
  text(s,'n=0 vẫn đi qua token init_only. early-stop giảm số vòng. release_result nhả slot của core.',48,650,1102,28,23,C.muted);
  sourceNotes(s,
    'L0khácE0inputhandshake củaMAC. iter_ctrl nạpstate tạiL0, phát token1sauL1. mul_iter_core R2 chốt shift/token1L2. sbm_accum commit1L3. Token2 phátL2, R2L3, commitlastL4. t=2,q2doneL4=t+2. t0init vẫnR1L1,R2L2,accL3 nênq1done3. token_valid/first/last/init_only/iteration/cut phải đi quaR2đồngbộterm. count/n giới hạn số termfraction, hidden nằmtrongfirstkhôngđếmthêm. core vẫnbusyđếnrelease_resultdo wrapperoutputretire. Các stage khác giao dịchkhôngchồnglấptrongbaseline hiện tại. Khônggánlịchcorecho latencycảMAC. Resetflushcảvalid/datacontexttheoguideline.',
    ['rtl/iter_ctrl.sv','rtl/mul_iter_core.sv','rtl/sbm_accum.sv','SPEC_Posit_MAC_IP.md']);
}

// 7. Transparent numerical walk-through of SAC and per-term FLOOR.
{
  const s=slide('Ví dụ 12 bit: hai vòng fraction',
    'X = 1.010010000000₂        Y = 1.001000001000₂        n = 2');
  text(s,'Popcount X = 2, popcount Y = 2. OPS hòa nên giữ A làm X.',48,180,1168,42,26,C.ops,true);
  table(s,[
    ['Bước','fx trước bước','K','sa','S','term Q12','acc Q12'],
    ['Y_base','010010000000','—','—','0','—','4616'],
    ['Vòng 1','010010000000','1','2','2','1154','5770'],
    ['Vòng 2','001000000000','2','3','5','144','5914'],
  ],48,256,1184,245,[160,282,90,90,90,218,254],C.sacLight,24);
  text(s,'Vòng 2: 4616 / 32 = 144,25. FLOOR giữ 144 và báo term_tail=1.',48,527,1168,42,26,C.sbm,true);
  text(s,'P_hat = 5914 / 4096 = 1,44384765625',48,582,1140,42,32,C.ink,true);
  text(s,'fx_next = 0: kết thúc quét fraction. Normalize và RNE tích tiếp tục sau core_done.',48,636,1126,37,24,C.muted);
  sourceNotes(s,
    'Đây là ví dụmantissa12bitvớisf_base0,dấudương. Cắtinputkhôngmấtbitvìphầnbỏ0. Xa=1.28125,Yb=1.126953125,y_baseQ12=4616. Vòng1fx010010000000,clz1,sa2,S2,fx_next001000000000;term4616>>2=1154,first cộng4616+1154=5770. Vòng2clz2,sa3,S5,fx_next0;termFLOOR4616>>5=144,đuôi8/32=.25Q12units,numericaltail1,acc5914. PayloadvậtlýQ14 ybase18464,term1=4616,term2=576,acc23656;divide4raQ12giátrị5914. Tíchmantissathật=1.44390869140625,khácprepackmộtquarterQ12LSBdoFLOOR. numerical_stickyFLOOR0,metadata inexact1. Khônggọi ví dụnàylàbằngchứngtáihiệnbaselinepaper; chỉminhhọarecurrence đãchốt. last nhậnởR1vòng2,doneởR3commitvòng2.',
    ['rtl/ops_sel_comb.sv','rtl/sac_step_comb.sv','rtl/sbm_shift_comb.sv','rtl/sbm_accum_comb.sv','SPEC_Posit_MAC_IP.md']);
}

const sources = ['rtl/ops_sel_comb.sv','rtl/sac_step_comb.sv','rtl/iter_ctrl.sv','rtl/mul_iter_core.sv',
  'rtl/sbm_shift_comb.sv','rtl/sbm_accum_comb.sv','rtl/sbm_accum.sv','SPEC_Posit_MAC_IP.md'];
const sourceHashes = Object.fromEntries(await Promise.all(sources.map(async f => [f,createHash('sha256').update(await fs.readFile(path.join(root,f))).digest('hex')])));
const candidate = path.join(build,`candidate_${revision}.pptx`);
const finalPath = path.join(output,`DATAPATH_OPS_SAC_SBM_${revision}.pptx`);
await (await PresentationFile.exportPptx(ppt)).save(candidate);
console.log('EXPORTED',candidate);
const result = await finalizePresentation({
  workspaceDir:root,candidatePath:candidate,finalPath,
  pythonExecutable:python,
  integrityValidatorPath:path.join(skill,'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath:path.join(skill,'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs:['--expected-slide-size-emu','12192000,6858000','--validate-bullet-geometry','--validate-heading-fit',
    '--require-native-table-slide','6','--require-native-table-slide','7'],
  requiredNativeTableOwnerSlides:[6,7],
  fontPolicy:{basis:'design',families:[FONT]},
  verifyArtifactToolImport:true,
  receiptPath:path.join(build,`validation_${revision}.json`),
});
console.log('FINALIZED',finalPath);
// Render the finalized package after an import, not a screenshot of the builder.
const rendered=await PresentationFile.importPptx(await FileBlob.load(finalPath));
for(const [index,sl] of rendered.slides.items.entries()) {
  const png=await rendered.export({slide:sl,format:'png',scale:1.25});
  await fs.writeFile(path.join(build,`${revision}_slide_${index+1}.png`),new Uint8Array(await png.arrayBuffer()));
}
await fs.writeFile(path.join(build,`authoring_${revision}.json`),JSON.stringify({
  date:'2026-10-14',slides:7,profile:'32/3 FRAC_W12 FLOOR EXACT_EN1',
  allDiagramsNative:true,sourceHashes,finalPath,
},null,2)+'\n');
console.log('RENDERED',rendered.slides.items.length,'slides');
