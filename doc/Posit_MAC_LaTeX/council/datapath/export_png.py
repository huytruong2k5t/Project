"""Render/crop lossless 240 dpi PNGs of datapath_export for reports and slides."""
import argparse
from pathlib import Path
import zipfile

NAMES = (
    "01_mac_f", "02_context", "03_parser", "04_lod_regime",
    "05_lod_sac_adder_nf", "06_ops_sac_sbm", "07_adder_5_tang",
    "08_adder_s1", "09_adder_s2", "10_adder_s3_s4", "11_adder_s5",
    "12_packer_rne", "13_nf_vs_f", "14_quire",
)
DPI = 240
MIN_MARGIN = 12
BORDER = 30


def find_nonwhite_bbox(samples: bytes, width: int, height: int, stride: int) -> tuple[int, int, int, int]:
    """Return tight half-open bbox (x0, y0, x1, y1) of non-white RGB pixels."""
    white_row = b"\xff" * (width * 3)
    active_rows = [
        y for y in range(height)
        if samples[y * stride : y * stride + width * 3] != white_row
    ]
    if not active_rows:
        return (-1, -1, -1, -1)
    y0, y1 = active_rows[0], active_rows[-1] + 1
    x0, x1 = width, 0
    for y in active_rows:
        row = samples[y * stride : y * stride + width * 3]
        left = (len(row) - len(row.lstrip(b"\xff"))) // 3
        right = (len(row.rstrip(b"\xff")) + 2) // 3
        if left < x0:
            x0 = left
        if right > x1:
            x1 = right
    return (x0, y0, x1, y1)


def crop_and_pad_rgb(samples: bytes, width: int, height: int, stride: int, label: str) -> tuple[int, int, bytes]:
    """Validate non-empty/unclipped margins, crop white space, and pad by BORDER px."""
    x0, y0, x1, y1 = find_nonwhite_bbox(samples, width, height, stride)
    if x0 < 0:
        raise SystemExit(f"Empty figure: {label}")
    if min(x0, y0, width - x1, height - y1) < MIN_MARGIN:
        raise SystemExit(f"Possible clipping: {label} ({(x0, y0, x1, y1)})")
    crop_w = x1 - x0
    out_w = crop_w + 2 * BORDER
    out_h = (y1 - y0) + 2 * BORDER
    top_bottom = b"\xff" * (out_w * 3 * BORDER)
    side = b"\xff" * (BORDER * 3)
    rows = [top_bottom]
    for y in range(y0, y1):
        start = y * stride + x0 * 3
        rows.append(side)
        rows.append(samples[start : start + crop_w * 3])
        rows.append(side)
    rows.append(top_bottom)
    return out_w, out_h, b"".join(rows)


def export_from_pdf(pdf_path: Path, out_dir: Path | None, zip_path: Path | None) -> None:
    """Render datapath_export.pdf at 240 dpi via PyMuPDF and save PNGs / ZIP archive."""
    import pymupdf

    doc = pymupdf.open(pdf_path)
    if len(doc) != len(NAMES):
        raise SystemExit(f"Expected {len(NAMES)} pages in {pdf_path}, got {len(doc)}")
    if out_dir is not None:
        out_dir.mkdir(parents=True, exist_ok=True)
    zf = zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) if zip_path else None
    try:
        for page, name in zip(doc, NAMES):
            pix = page.get_pixmap(dpi=DPI, alpha=False)
            out_w, out_h, rgb_bytes = crop_and_pad_rgb(
                bytes(pix.samples), pix.width, pix.height, pix.stride, f"{pdf_path.name}#p{page.number + 1}"
            )
            out_pix = pymupdf.Pixmap(pymupdf.csRGB, out_w, out_h, rgb_bytes, False)
            out_pix.set_dpi(DPI, DPI)
            png_bytes = out_pix.tobytes("png")
            if out_dir is not None:
                (out_dir / f"{name}.png").write_bytes(png_bytes)
            if zf is not None:
                zf.writestr(f"{name}.png", png_bytes)
            print(f"{name}: {out_w}x{out_h} ({len(png_bytes)} bytes)")
    finally:
        if zf is not None:
            zf.close()


def export_from_poppler_dir(source: Path, target: Path, zip_path: Path | None) -> None:
    """Crop lossless Poppler raw-*.png renders using Pillow (legacy Poppler mode)."""
    from PIL import Image, ImageChops, ImageOps

    pages = sorted(source.glob("raw-*.png"))
    if len(pages) != len(NAMES):
        raise SystemExit(f"Expected {len(NAMES)} pages, got {len(pages)}")
    target.mkdir(parents=True, exist_ok=True)
    zf = zipfile.ZipFile(zip_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) if zip_path else None
    try:
        for path, name in zip(pages, NAMES):
            with Image.open(path) as page:
                rgb = page.convert("RGB")
                rect = ImageChops.difference(rgb, Image.new("RGB", rgb.size, "white")).getbbox()
                if rect is None:
                    raise SystemExit(f"Empty figure: {path}")
                if min(rect[0], rect[1], rgb.width - rect[2], rgb.height - rect[3]) < MIN_MARGIN:
                    raise SystemExit(f"Possible clipping: {path} ({rect})")
                png = ImageOps.expand(rgb.crop(rect), border=BORDER, fill="white")
                out_file = target / f"{name}.png"
                png.save(out_file, dpi=(DPI, DPI), optimize=True)
                if zf is not None:
                    zf.write(out_file, arcname=f"{name}.png")
                print(f"{name}: {png.width}x{png.height}")
    finally:
        if zf is not None:
            zf.close()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Poppler raw-* dir OR PDF file (e.g. .build/datapath_export.pdf)")
    parser.add_argument("target", type=Path, nargs="?", help="Output PNG directory (optional when --zip is given for PDF input)")
    parser.add_argument("--zip", type=Path, default=None, help="Optional output ZIP archive path")
    args = parser.parse_args()
    if args.source.is_file() and args.source.suffix.lower() == ".pdf":
        if args.target is None and args.zip is None:
            raise SystemExit("Provide a target directory or --zip for PDF input")
        export_from_pdf(args.source, args.target, args.zip)
    else:
        if args.target is None:
            raise SystemExit("Provide a target directory for Poppler raw-* input")
        export_from_poppler_dir(args.source, args.target, args.zip)


if __name__ == "__main__":
    main()
