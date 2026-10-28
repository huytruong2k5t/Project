import fs from 'node:fs/promises';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { Presentation, PresentationFile } from 'file:///C:/Users/This%20PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@oai/artifact-tool/dist/artifact_tool.mjs';

process.env.RUNTIME_NODE_MODULES = 'C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const root = 'C:/HCMUT/HK261/Do an 2/Posit_MAC';
const skill = 'C:/Users/This PC/.codex/plugins/cache/openai-primary-runtime/presentations/26.1025.11240/skills/presentations';
const build = path.join(root, 'presentation/.build_chuong3_20261028');
const out = path.join(root, 'presentation/CHUONG3_KIEN_TRUC_TONG_THE_20261028');
await fs.mkdir(build, { recursive: true });
await fs.mkdir(out, { recursive: true });

// Native PowerPoint objects only. No rasterized datapath or register symbols.
const presentation = Presentation.create({ slideSize: { width: 1600, height: 900 } });
const slide = presentation.slides.add();
slide.background.fill = '#FFFFFF';
const C = {
  ink: '#15283B', muted: '#4B5F72', wire: '#33485D',
  blue: '#1565B4', blueFill: '#EAF3FD',
  amber: '#A95A00', amberFill: '#FFF1DD',
  violet: '#7251AC', violetFill: '#F2EDFB', gray: '#E5EBF0'
};

function text(name, value, x, y, w, h, size = 23, opts = {}) {
  const shape = slide.shapes.add({
    geometry: 'textbox', name,
    position: { left: x, top: y, width: w, height: h },
    fill: 'none', line: { fill: 'none', width: 0 }
  });
  shape.text = value;
  shape.text.style = {
    typeface: 'Arial', fontSize: size, color: opts.color ?? C.ink,
    bold: opts.bold ?? false, alignment: opts.align ?? 'left',
    verticalAlignment: 'middle', autoFit: 'none', wrap: 'none', insets: 0
  };
  return shape;
}
function block(name, value, x, y, w, h, family = 'blue', size = 24) {
  const shape = slide.shapes.add({
    geometry: 'rect', name,
    position: { left: x, top: y, width: w, height: h },
    fill: C[`${family}Fill`],
    line: { fill: C[family], width: 2 }
  });
  shape.text = value;
  shape.text.style = {
    typeface: 'Arial', fontSize: size, color: C.ink,
    bold: true, alignment: 'center', verticalAlignment: 'middle',
    autoFit: 'none', wrap: 'none', insets: 8
  };
  return shape;
}
function arrow(from, to, fromSide = 'right', toSide = 'left') {
  return slide.shapes.connect(from, to, {
    kind: 'straight', fromSide, toSide,
    line: { fill: C.wire, width: 2.2 },
    tail: { type: 'triangle', width: 'med', length: 'med' }
  });
}

text('title', '3.2. Kiến trúc tổng thể MAC Posit(32,3)', 52, 34, 1496, 65, 46, { bold: true });
text('subtitle', 'Hai phương án RTL riêng: posit_mac_nf và posit_mac_f', 52, 104, 1496, 34, 26, { color: C.muted });

for (const [x, family, label] of [
  [52, 'blue', 'Cùng chức năng trong hai top'],
  [610, 'amber', 'Xử lý riêng của NF'],
  [1070, 'violet', 'Xử lý riêng của F']
]) {
  slide.shapes.add({ geometry: 'rect', name: `legend-${family}`,
    position: { left: x, top: 158, width: 24, height: 24 },
    fill: C[`${family}Fill`], line: { fill: C[family], width: 2 } });
  text(`legend-text-${family}`, label, x + 36, 153, 490, 34, 24);
}

text('nf-label', 'NON-FUSED (NF)', 52, 205, 430, 40, 29, { color: C.amber, bold: true });
text('nf-rule', 'Làm tròn tích trước cộng, làm tròn tổng ở đầu ra', 570, 207, 978, 36, 25, { color: C.amber });
const nfInput = text('nf-input-ab', 'A, B\n32 bit', 52, 267, 82, 78, 24, { bold: true });
const nfParser = block('nf-parser-ab', 'Parser\nA và B', 160, 260, 155, 98);
const nfMul = block('nf-multiplier', 'OPS + bộ nhân\nlặp SAC/SBM', 355, 260, 210, 98);
const nfProd = block('nf-product-pack', 'Chuẩn hóa\nPack tích (RNE)', 605, 260, 190, 98, 'amber', 23);
const nfDecode = block('nf-product-decode', 'Giải mã\ntích đã RNE', 835, 260, 150, 98, 'amber', 23);
const nfAdd = block('nf-adder', 'Cộng / trừ\nChuẩn hóa', 1025, 260, 225, 98, 'amber');
const nfPack = block('nf-final-pack', 'Packer\nRNE cuối', 1290, 260, 165, 98);
const nfOutput = text('nf-output', 'D_NF\n32 bit', 1492, 267, 102, 78, 23, { bold: true });
for (const [a, b] of [[nfInput,nfParser],[nfParser,nfMul],[nfMul,nfProd],
  [nfProd,nfDecode],[nfDecode,nfAdd],[nfAdd,nfPack],[nfPack,nfOutput]]) arrow(a, b);
const nfC = text('nf-c-effective', 'C_eff\n32 bit', 835, 392, 150, 65, 23);
const nfCParser = block('nf-parser-c', 'Parser C_eff', 1025, 392, 225, 64, 'blue', 24);
arrow(nfC,nfCParser);
arrow(nfCParser,nfAdd,'top','bottom');
text('nf-flags', 'flags[4:0]', 1477, 355, 116, 32, 21, { color: C.muted });

text('f-label', 'FUSED (F)', 52, 495, 430, 40, 29, { color: C.violet, bold: true });
text('f-rule', 'Tích trước pack đi thẳng vào cộng, RNE tại đầu ra', 570, 497, 978, 36, 25, { color: C.violet });
const fInput = text('f-input-ab', 'A, B\n32 bit', 52, 557, 82, 78, 24, { bold: true });
const fParser = block('f-parser-ab', 'Parser\nA và B', 160, 550, 155, 98);
const fMul = block('f-multiplier', 'OPS + bộ nhân\nlặp SAC/SBM', 355, 550, 210, 98);
const fPrepack = block('f-prepack', 'Tích trước pack\nĐộ lớn và scale', 605, 550, 190, 98, 'violet', 22);
const fAdd = block('f-add-normalize', 'Căn chỉnh tích với C_eff\nCộng / trừ và chuẩn hóa', 835, 550, 415, 98, 'violet', 25);
const fPack = block('f-final-pack', 'Packer\nRNE cuối', 1290, 550, 165, 98);
const fOutput = text('f-output', 'D_F\n32 bit', 1492, 557, 102, 78, 23, { bold: true });
for (const [a, b] of [[fInput,fParser],[fParser,fMul],[fMul,fPrepack],
  [fPrepack,fAdd],[fAdd,fPack],[fPack,fOutput]]) arrow(a,b);
const fC = text('f-c-effective', 'C_eff\n32 bit', 748, 680, 150, 65, 23);
const fCParser = block('f-parser-c', 'Parser C_eff', 930, 680, 225, 64, 'blue', 24);
arrow(fC,fCParser);
arrow(fCParser,fAdd,'top','bottom');
text('f-flags', 'flags[4:0]', 1477, 645, 116, 32, 21, { color: C.muted });

text('c-effective-rule', 'C_eff = C khi tính độc lập; C_eff = S_k khi tích lũy; C_eff = 0 khi acc_clr = 1 hợp lệ',
  52, 770, 1496, 36, 24);
text('interface', 'Điều khiển: clk, rst_n, valid/ready, acc_mode, acc_clr, cfg_mode, cfg_n, cfg_ops',
  52, 814, 1496, 34, 24, { color: C.muted });
text('scope-note', 'S_k là kết quả Posit đã làm tròn của giao dịch tích lũy trước. Màu xanh không hàm ý chia sẻ phần cứng vật lý.',
  52, 858, 1496, 30, 21, { color: C.muted });

slide.speakerNotes.text = [
  'Nguồn: RTL production tại ngày 28/10/2026 trong dự án Posit_MAC.',
  'rtl/mac_nf/posit_mac_nf.sv; rtl/mac_nf/mac_nf_wrapper.sv;',
  'rtl/mac_f/posit_mac_f.sv; rtl/mac_f/mac_f_wrapper.sv;',
  'rtl/multiplier/ops_sel_comb.sv; SPEC_Posit_MAC_IP.md mục 4.1/4.2, 5.1, 5.12.',
  'Hai hàng là hai top độc lập, không phải một top chia sẻ bộ nhân hay có tín hiệu chọn NF/F.',
  'Các khối xanh có cùng vai trò chức năng nhưng không cam kết cùng width hoặc cùng instance.',
  'Khối Parser A và B gom hai parser song song. Parser C_eff nhận toán hạng cộng đã chọn.',
  'NF: chuẩn hóa bảo toàn tích, posit_product_pack RNE, posit_magnitude_parse, posit_add, posit_pack.',
  'F: p_magnitude=acc[15:2] và core_sf đưa vào fused_add_pipe rồi posit_pack, không có product RNE.',
  'Không vẽ thanh ghi, dây metadata hoặc mọi cổng handshake trong phác thảo tổng thể này.',
  'cfg_mode=0 exact chỉ NF nhận; F chỉ nhận cfg_mode=1. Approx n=0..8, cfg_ops=0/1.',
  'NF và F phản hồi d đã làm tròn, không phải quire tích lũy không làm tròn cả chuỗi.',
  'Cắt FLOOR bên trong bộ nhân gần đúng vẫn gây mất thông tin trước RNE cuối.',
  'Accumulator cập nhật một lần khi kết quả được ghi vào bộ đệm đầu ra, không lặp lại khi stalled.'
].join('\n');

const draft = path.join(build, 'candidate.pptx');
await (await PresentationFile.exportPptx(presentation)).save(draft);
const png = await presentation.export({ slide, format: 'png', scale: 1 });
await fs.writeFile(path.join(out, 'KIEN_TRUC_TONG_THE_NF_F.png'), new Uint8Array(await png.arrayBuffer()));
const layout = await slide.export({ format: 'layout' });
await fs.writeFile(path.join(build, 'slide.layout.json'), await layout.text());
const { finalizePresentation } = await import(pathToFileURL(path.join(skill, 'container_tools/artifact_tool_utils.mjs')).href);
const result = await finalizePresentation({
  explicitTotalSlideCount: 1,
  workspaceDir: root,
  candidatePath: draft,
  finalPath: path.join(out, 'KIEN_TRUC_TONG_THE_NF_F.pptx'),
  pythonExecutable: 'C:/Users/This PC/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe',
  integrityValidatorPath: path.join(skill, 'container_tools/inspect_presentation_package_integrity.py'),
  layoutValidatorPath: path.join(skill, 'container_tools/inspect_presentation_layout_geometry.py'),
  layoutArgs: ['--expected-slide-size-emu', '15240000,8572500', '--validate-heading-fit'],
  requiredNativeTableOwnerSlides: [],
  fontPolicy: { basis: 'design', families: ['Arial'] },
  verifyArtifactToolImport: true,
  receiptPath: path.join(build, 'validation.json')
});
console.log(JSON.stringify({ outputDirectory: out, finalization: result }));
