# Danh Sách Corner Cases Bắt Buộc (§6.4)

## 1. Các giá trị đặc biệt cơ bản (posit32 ví dụ)
- **Zero**: `0x00000000`
- **NaR (Not a Real)**: `0x80000000`
- **+1.0**: `0x40000000`
- **-1.0**: `0xC0000000`
- **minpos**: `0x00000001`
- **-minpos**: `0xFFFFFFFF`
- **maxpos**: `0x7FFFFFFF`
- **-maxpos**: `0x80000001`

## 2. Các tổ hợp kiểm tra bắt buộc
1. `NaR * 0 -> NaR`
2. `0 * NaR -> NaR`
3. `maxpos * maxpos -> maxpos` (Bão hòa trên)
4. `minpos * minpos -> minpos` (Bão hòa dưới, không về 0)
5. `(-maxpos) * (-maxpos) -> maxpos`
6. `maxpos * minpos` (Với `ES=2`: bằng đúng 1 = `0x40000000`)
7. `maxpos + maxpos -> maxpos`
8. `x + (-x) -> 0` (Triệt tiêu chính xác)
9. `1 + minpos`
10. Các cặp kiểm tra làm tròn RNE hòa (TV-RND-01, TV-RND-02)
11. Trường hợp regime chiếm hết `NB-1` bit (`m = NB-1`)
