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
const revision = process.argv[2] || 'r5';
await fs.mkdir(build, { recursive: true });
await fs.mkdir(output, { recursive: true });
const link = path.join(build, 'node_modules');
try { await fs.lstat(link); }
catch { await fs.symlink(runtimeModules, link, process.platform === 'win32' ? 'junction' : 'dir'); }
const require = createRequire(path.join(build, 'package.json'));
const { Presentation, PresentationFile, FileBlob } = await import(pathToFileURL(require.resolve('@oai/artifact-tool')));
const { resolvePresentationFont, finalizePresentation } = await import(pathToFileURL(path.join(skill, 'container_tools/artifact_tool_utils.mjs')));
const FONT = resolvePresentationFont({ fontFamily: 'Arial' });
// Edit the existing native deck. SAC/SBM, tables and notes stay on their slides.
const sourceDeck = path.join(output, 'DATAPATH_OPS_SAC_SBM_r3.pptx');
const ppt = await PresentationFile.importPptx(await FileBlob.load(sourceDeck));
if (ppt.slides.items.length !== 7) throw new Error('Expected the seven-slide r3 source');
const before = await ppt.inspect({
  select: '$.slides[*]',
  include: ['id', 'index', 'layout', 'title', 'elements.id', 'elements.kind',
    'elements.text', 'elements.position', 'notes.text'],
});
await fs.writeFile(path.join(build, `before_${revision}.ndjson`), before.ndjson);
const editedElements = await ppt.inspect({
  select: '$.slides[0,1].elements[*]',
  include: ['id'],
});
ppt.delete(editedElements.records.map(element => element.id));
let slideCursor = 0;
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
  const s=ppt.slides.items[slideCursor++];
  s.background.fill='white';
  text(s,title,48,32,1184,62,44,C.ink,true);
  text(s,subtitle,48,99,1184,42,24,C.muted);
  segment(s,48,155,1232,155,C.border,false,false,1);
  const number=slideCursor;
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
  block(s,'OPS','Count / data\nsong song',64,277,173,120,C.ops,C.opsLight);
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
    'OPS là Operand Selector. Hai nhánh tổ hợp masked popcount và chuẩn bị ứng viên X/Y chạy song song, rồi choose_b điều khiển một tầng swap gồm hai MUX bus. Bit ẩn chỉ chèn trong các ứng viên Y trước swap. SAC là Shift Amount Calculator. SBM là Shift-Based Multiplier. S là lượng dịch tích lũy, khác scale factor sf của Posit. Sơ đồ tổng rút gọn R0 thành bank context gồm y_q, mode/sign/sf và state SAC. R0 nằm sau toàn bộ OPS, không thêm một tầng pipeline. R1 nằm trong iter_ctrl, R2 là t2_term và token trong mul_iter_core, L3 là acc trong sbm_accum. Các thanh ghi cùng clock. Y đi thẳng tới shifter và giữ ổn định cho toàn giao dịch. Core xử lý một giao dịch và giải phóng khi release_result. Công thức là trên mantissa/lưới FLOOR, dấu và sf được ghép sau core. ACC_W32/3=54 với EXACT_EN=1, dù payload approx chỉ16 bit.',
    ['rtl/ops_sel_comb.sv','rtl/iter_ctrl.sv','rtl/mul_iter_core.sv','rtl/sbm_shift_comb.sv','rtl/sbm_accum.sv','SPEC_Posit_MAC_IP.md']);
}

// 2. Refactored OPS: the count and data lanes share inputs, not each other.
{
  const s=slide('OPS: điều khiển và dữ liệu chạy song song',
    'Exact dùng 26 bit. Approx dùng 12 MSB. Hidden chèn sẵn trong Y trước swap');

  block(s,'Ngõ vào','A[25:0]\nB[25:0]',48,267,156,130,C.ops,C.opsLight,25);
  // One genuine branch point. Solid arrows carry data, dashed arrows select MUXes.
  wire(s,[[204,324],[232,324]],C.wire,false);
  s.shapes.add({geometry:'ellipse',name:'input-junction',
    position:{left:228,top:320,width:8,height:8},fill:C.wire,
    line:{width:0,fill:'none'}});
  wire(s,[[232,324],[232,278],[275,278]],C.ops);
  wire(s,[[232,324],[232,487],[275,487]],C.green);

  text(s,'ĐIỀU KHIỂN',275,173,270,32,25,C.ops,true);
  block(s,'Mask thấp','[25:14] giữ nguyên\n[13:0] AND !mode',275,219,245,117,C.ops,C.opsLight,26);
  block(s,'Popcount A/B','Hai cây cộng\nCount A, Count B',560,219,202,117,C.ops,C.opsLight,25);
  block(s,'Chọn X','B < A & OPS bật\nHòa giữ A',814,219,238,117,C.ops,C.opsLight,26);
  wire(s,[[520,278],[560,278]],C.ops);
  wire(s,[[762,278],[814,278]],C.ops);
  // Both final MUXes use the same decision without a data dependency between them.
  wire(s,[[932,336],[932,386]],C.ops,false,true);
  wire(s,[[932,386],[844,386],[844,424]],C.ops,true,true);
  wire(s,[[932,386],[1120,386],[1120,424]],C.ops,true,true);
  s.shapes.add({geometry:'ellipse',name:'select-junction',
    position:{left:929,top:383,width:6,height:6},fill:C.ops,
    line:{width:0,fill:'none'}});
  label(s,'choose_b',942,340,172,C.ops,23,'left');

  text(s,'DỮ LIỆU',275,355,300,32,25,C.green,true);
  block(s,'Chuẩn bị A và B','Căn phải theo mode\nX_A / X_B: fraction\nY_A / Y_B: 1.f',275,414,300,159,C.green,C.greenLight,25);
  mux(s,'X',804,415,80,90,C.green,C.greenLight);
  mux(s,'Y',1080,415,80,90,C.green,C.greenLight);
  wire(s,[[575,440],[804,440]],C.green);
  wire(s,[[575,467],[804,467]],C.green);
  label(s,'0: X_A',619,403,137,C.green,22);
  label(s,'1: X_B',619,433,137,C.green,22);
  wire(s,[[575,520],[1048,520],[1048,440],[1080,440]],C.green);
  wire(s,[[575,552],[1064,552],[1064,467],[1080,467]],C.green);
  label(s,'0: Y_B',686,484,144,C.green,22);
  label(s,'1: Y_A',686,519,144,C.green,22);
  wire(s,[[884,453],[1010,453]],C.green);
  wire(s,[[1160,453],[1232,453]],C.green);
  label(s,'x_frac [25:0]',884,469,149,C.green,22);
  label(s,'y_mant [26:0]',1070,510,162,C.green,22);
  text(s,'Một tầng swap gồm 2 MUX bus song song',603,582,629,34,24,C.ink,true);
  text(s,'mode = cfg_mode. Nét liền: dữ liệu. Nét đứt: chọn MUX. Chốt X/Y tại R0 (L0).',275,609,956,25,20,C.muted);

  segment(s,48,635,1232,635,C.border,false,false,1);
  text(s,'Song song: sign_o = s_A XOR s_B       sf_o = sf_A + sf_B',48,638,1082,31,23,C.muted);
  text(s,'input_cut = mode & OR(A[13:0] OR B[13:0])',48,674,1070,29,22,C.muted);
  sourceNotes(s,
    'Profile: FRAC_MAX=26, FRAC_W=12, CUT_W=14, SF_W=11, WIDTH_W=5.\n\nHai nhánh chạy song song từ cùng frac_A/B. Nhánh điều khiển giữ nguyên 12 bit cao [25:14], AND từng bit thấp [13:0] với !cfg_mode rồi đếm bằng hai cây cộng cân bằng. Không căn phải trước popcount. PAD_N=32 gồm 26 lá dữ liệu và 6 lá zero. Hai count 5 bit. choose_b = OPS_EN && (cfg_ops == 2\'d1) && (count_B < count_A). cfg_ops=0 giữ A. cfg_ops=1 chọn B chỉ khi B ít bit 1 hơn. Hòa giữ A.\n\nNhánh dữ liệu độc lập choose_b. Exact: X_A=frac_A, X_B=frac_B, Y_A={1\'b1,frac_A}, Y_B={1\'b1,frac_B}. Approx: X_i={14\'b0,frac_i[25:14]}, Y_i={14\'b0,1\'b1,frac_i[25:14]}. Chèn hidden trong Y trước swap, ở bit12 trong approx và bit26 trong exact. X có 26 bit, không hidden. Y có 27 bit.\n\nSwap là một tầng gồm hai MUX song song: x_frac=choose_b?X_B:X_A; y_mant=choose_b?Y_A:Y_B. Nhãn 0/1 trên dây là giá trị choose_b chọn ứng viên đó. Hai MUX không mắc nối tiếp. Dây xanh lá liên tục là dữ liệu, dây xanh lam đứt là điều khiển chọn. Điểm chấm là nối nhánh. Đầu ra OPS được bank R0 chốt ở L0 như slide tổng, không thêm FF bên trong OPS.\n\nMetadata cũng tính song song: sign_o=s_A^s_B; sf_o=sf_A+sf_B trên 11 bit signed; active_width=cfg_mode?12:26; input_cut=cfg_mode & (|(frac_A[13:0]|frac_B[13:0])). Trường hợp FRAC_W==FRAC_MAX dùng generate no-cut: input_cut=0. cfg_error=(cfg_ops>1)||(!OPS_EN&&cfg_ops!=0)||(!EXACT_EN&&!cfg_mode). Khi lỗi, bốn ứng viên và metadata được zero trước swap, swapped=0. Mạng cfg_error/zero-gating được gộp trong khối chuẩn bị để giữ sơ đồ rõ. cfg_mode và cfg_ops là các ngõ cấu hình dùng chung cho những khối được ghi nhãn. Chỉ áp dụng datapath finite đã parse, wrapper xử lý Zero/NaR.',
    ['rtl/ops_sel_comb.sv','rtl/mac_nf_wrapper.sv','SPEC_Posit_MAC_IP.md']);
}

// Slides 3–7 are preserved from r3, including editable SAC/SBM diagrams, tables and notes.

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
  fontPolicy:{basis:'reference',families:[FONT],referencePath:sourceDeck,
    referenceSha256:createHash('sha256').update(await fs.readFile(sourceDeck)).digest('hex')},
  verifyArtifactToolImport:true,
  receiptPath:path.join(build,`validation_${revision}.json`),
});
console.log('FINALIZED',finalPath);
// Render the finalized package after an import, not a screenshot of the builder.
const rendered=await PresentationFile.importPptx(await FileBlob.load(finalPath));
for(const [index,sl] of rendered.slides.items.entries()) {
  const png=await rendered.export({slide:sl,format:'png',scale:1.25});
  await fs.writeFile(path.join(build,`${revision}_slide_${index+1}.png`),new Uint8Array(await png.arrayBuffer()));
  if (index < 2) {
    const layout=await sl.export({format:'layout'});
    await fs.writeFile(path.join(build,`${revision}_slide_${index+1}.layout.json`),await layout.text());
  }
}
await fs.writeFile(path.join(build,`authoring_${revision}.json`),JSON.stringify({
  date:'2026-10-14',slides:7,profile:'32/3 FRAC_W12 FLOOR EXACT_EN1',
  allDiagramsNative:true,sourceHashes,finalPath,sourceDeck,
  editedSlides:[1,2],preservedSlides:[3,4,5,6,7],
},null,2)+'\n');
const content = await rendered.inspect({select:'$.slides[*]',include:['index','title','elements.text']});
await fs.writeFile(path.join(output,`DATAPATH_OPS_SAC_SBM_${revision}_source.json`),JSON.stringify({
  date:'2026-10-14',slides:7,profile:'32/3 FRAC_W12 FLOOR EXACT_EN1',allDiagramsNative:true,
  sourceHashes,deck:path.basename(finalPath),
  deckSha256:createHash('sha256').update(await fs.readFile(finalPath)).digest('hex'),
  builder:'scripts/build_datapath_ops_sac_sbm.mjs',
  builderSha256:createHash('sha256').update(await fs.readFile(path.join(root,'scripts/build_datapath_ops_sac_sbm.mjs'))).digest('hex'),
  baseDeck:path.basename(sourceDeck),baseDeckSha256:createHash('sha256').update(await fs.readFile(sourceDeck)).digest('hex'),
  editedSlides:[1,2],preservedSlides:[3,4,5,6,7],
  scope:'Current normative RTL; masked popcount parallel to aligned X/Y candidate preparation; one final swap stage with two bus MUXes; R0 unchanged',
  slideTitles:content.records.map(record=>record.title || record.elements.find(element=>element.text)?.text),
},null,2)+'\n');
console.log('RENDERED',rendered.slides.items.length,'slides');
