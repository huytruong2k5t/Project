"""Exercise the actual C shared library through ctypes, including ABI errors/state."""
import ctypes as C
import pathlib
import random
import sys

root = pathlib.Path(__file__).resolve().parents[1]
windows = sys.platform == "win32"
lib = C.CDLL(str(root / (sys.argv[1] if len(sys.argv)>1 else ("posit_l1.dll" if windows else "libposit_l1.so"))))
l0 = C.CDLL(str(root.parent / "l0" / ("softposit.dll" if windows else "libsoftposit.so")))
U = C.c_uint32
class Config(C.Structure):
    _fields_ = [(name, U) for name in ("version", "exact", "n", "ops", "scheme", "rounding")]
class Result(C.Structure):
    _fields_ = [(name, U) for name in ("bits", "flags", "iterations", "bypass")]
lib.l1_p32_mul.argtypes = [U, U]
lib.l1_p32_mul.restype = U
lib.l1_p32_mac.argtypes = [U, U, U]
lib.l1_p32_mac.restype = U
lib.l1_mac_eval.argtypes = [U] * 5 + [C.POINTER(Config), C.POINTER(Result)]
lib.l1_mac_eval.restype = C.c_int
lib.l1_acc_create.argtypes = [U, U]
lib.l1_acc_create.restype = C.c_void_p
lib.l1_acc_reset.argtypes = [C.c_void_p]
lib.l1_acc_reset.restype = C.c_int
lib.l1_acc_step.argtypes = [C.c_void_p] + [U] * 5 + [C.POINTER(Config), C.POINTER(Result)]
lib.l1_acc_step.restype = C.c_int
lib.l1_acc_destroy.argtypes = [C.c_void_p]
lib.l1_acc_destroy.restype = None
checks = 0
for nb, es, scalar in ((8, 0, C.c_uint8), (16, 1, C.c_uint16), (32, 2, U)):
    mul = getattr(l0, f"l0_p{nb}_mul")
    add = getattr(l0, f"l0_p{nb}_add")
    mul.argtypes = add.argtypes = [scalar, scalar]
    mul.restype = add.restype = scalar
    rng = random.Random(314159)
    h = lib.l1_acc_create(nb, es)
    assert h
    state = 0
    try:
        for i in range(10000):
            a, b, c = (rng.getrandbits(nb) for _ in range(3))
            expected = add(mul(a, b), c)
            for version in (0, 1):
                cfg = Config(version, 1, 2, 0, 0, 0)
                r = Result()
                assert lib.l1_mac_eval(nb, es, a, b, c, C.byref(cfg), C.byref(r)) == 0
                assert r.bits == expected
                checks += 1
            if nb == 32:
                assert lib.l1_p32_mul(a, b) == mul(a, b)
                assert lib.l1_p32_mac(a, b, c) == expected
            clear = int(i % 19 == 0)
            state = add(mul(a, b), 0 if clear else state)
            assert lib.l1_acc_step(h, a, b, c, 1, clear, None, C.byref(r)) == 0
            assert r.bits == state
            checks += 1
        assert lib.l1_acc_reset(h) == 0
        one = 1 << (nb - 2)
        nar = 1 << (nb - 1)
        assert lib.l1_acc_step(h, one, one, nar, 1, 1, None, C.byref(r)) == 0
        assert r.bits == one
        bad = Config(1, 0, 9, 0, 0, 0)
        sentinel = Result(123, 456, 789, 42)
        assert lib.l1_acc_step(h, one, one, 0, 1, 1, C.byref(bad), C.byref(sentinel)) == 1
        assert tuple(getattr(sentinel, n) for n, _ in Result._fields_) == (123, 456, 789, 42)
        assert lib.l1_acc_step(h, 0, one, 0, 1, 0, None, C.byref(r)) == 0 and r.bits == one
        assert lib.l1_acc_step(h, one, one, 0, 0, 1, None, C.byref(r)) == 1
    finally:
        lib.l1_acc_destroy(h)
assert not lib.l1_acc_create(32, 4)
assert lib.l1_acc_reset(None) == 1
assert lib.l1_mac_eval(32, 2, 0, 0, 0, None, None) == 1
assert lib.l1_mac_eval(8, 0, 256, 0, 0, None, C.byref(Result())) == 1
assert lib.l1_mac_eval(32, 3, 0x40000000, 0x40000000, 0, None, C.byref(r)) == 0
assert r.bits == 0x40000000
rng = random.Random(20261004)
for nb, es in ((8, 0), (16, 1), (32, 2), (32, 3)):
    for i in range(10000):
        a, b, c = (rng.getrandbits(nb) for _ in range(3))
        cfg = Config(0, 0, i % 9, (i // 9) % 2, (i // 18) % 2, (i // 36) % 2)
        v0, v1 = Result(), Result()
        assert lib.l1_mac_eval(nb, es, a, b, c, C.byref(cfg), C.byref(v0)) == 0
        cfg.version = 1
        assert lib.l1_mac_eval(nb, es, a, b, c, C.byref(cfg), C.byref(v1)) == 0
        assert bytes(v0) == bytes(v1)
        checks += 1
for field in ("version", "exact", "ops", "scheme", "rounding"):
    bad = Config(1, 1, 2, 0, 0, 0)
    setattr(bad, field, 2)
    assert lib.l1_mac_eval(32, 2, 1, 1, 0, C.byref(bad), C.byref(r)) == 1
l0.l0_double_to_p32.argtypes = [C.c_double]
l0.l0_double_to_p32.restype = U
half_ulp = l0.l0_double_to_p32(2.0 ** -28)
for negative in (False, True):
    for odd in (0, 1):
        a = 0x40000000 + odd
        c = half_ulp
        if negative:
            a, c = (-a) & 0xFFFFFFFF, (-c) & 0xFFFFFFFF
        for rounding in (0, 1):
            cfg = Config(1, 1, 2, 0, 0, rounding)
            assert lib.l1_mac_eval(32, 2, a, 0x40000000, c, C.byref(cfg), C.byref(r)) == 0
            expected = 0x40000000 + (2 * odd if rounding == 0 else odd)
            if negative:
                expected = (-expected) & 0xFFFFFFFF
            assert r.bits == expected and r.flags == 2
            checks += 1
print(f"C_API ctypes PASS platform={sys.platform} checks={checks} seed=314159 errors/state/ES3 PASS")
