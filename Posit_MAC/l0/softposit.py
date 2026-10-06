"""
SoftPosit Python Wrapper for Posit Arithmetic IP Golden Reference (L0)
Supports Posit8 (ES=0), Posit16 (ES=1), Posit32 (ES=2)
Cross-platform: Windows (softposit.dll) & Linux (libsoftposit.so)
"""

import os
import sys
import ctypes
from typing import Union

# Locate shared library (.dll on Windows, .so on Linux)
_DIR = os.path.dirname(os.path.abspath(__file__))

if sys.platform.startswith("win"):
    _lib_path = os.path.join(_DIR, "softposit.dll")
else:
    _lib_path = os.path.join(_DIR, "libsoftposit.so")

if not os.path.exists(_lib_path):
    raise FileNotFoundError(f"SoftPosit binary not found at {_lib_path}. Please build it first via `make`.")

_lib = ctypes.CDLL(_lib_path)

# Configure C types for P8
_lib.l0_p8_add.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
_lib.l0_p8_add.restype = ctypes.c_uint8

_lib.l0_p8_sub.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
_lib.l0_p8_sub.restype = ctypes.c_uint8

_lib.l0_p8_mul.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
_lib.l0_p8_mul.restype = ctypes.c_uint8

_lib.l0_p8_div.argtypes = [ctypes.c_uint8, ctypes.c_uint8]
_lib.l0_p8_div.restype = ctypes.c_uint8

_lib.l0_p8_mulAdd.argtypes = [ctypes.c_uint8, ctypes.c_uint8, ctypes.c_uint8]
_lib.l0_p8_mulAdd.restype = ctypes.c_uint8

_lib.l0_p8_to_double.argtypes = [ctypes.c_uint8]
_lib.l0_p8_to_double.restype = ctypes.c_double

_lib.l0_double_to_p8.argtypes = [ctypes.c_double]
_lib.l0_double_to_p8.restype = ctypes.c_uint8

# Configure C types for P16
_lib.l0_p16_add.argtypes = [ctypes.c_uint16, ctypes.c_uint16]
_lib.l0_p16_add.restype = ctypes.c_uint16

_lib.l0_p16_sub.argtypes = [ctypes.c_uint16, ctypes.c_uint16]
_lib.l0_p16_sub.restype = ctypes.c_uint16

_lib.l0_p16_mul.argtypes = [ctypes.c_uint16, ctypes.c_uint16]
_lib.l0_p16_mul.restype = ctypes.c_uint16

_lib.l0_p16_div.argtypes = [ctypes.c_uint16, ctypes.c_uint16]
_lib.l0_p16_div.restype = ctypes.c_uint16

_lib.l0_p16_mulAdd.argtypes = [ctypes.c_uint16, ctypes.c_uint16, ctypes.c_uint16]
_lib.l0_p16_mulAdd.restype = ctypes.c_uint16

_lib.l0_p16_to_double.argtypes = [ctypes.c_uint16]
_lib.l0_p16_to_double.restype = ctypes.c_double

_lib.l0_double_to_p16.argtypes = [ctypes.c_double]
_lib.l0_double_to_p16.restype = ctypes.c_uint16

# Configure C types for P32
_lib.l0_p32_add.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
_lib.l0_p32_add.restype = ctypes.c_uint32

_lib.l0_p32_sub.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
_lib.l0_p32_sub.restype = ctypes.c_uint32

_lib.l0_p32_mul.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
_lib.l0_p32_mul.restype = ctypes.c_uint32

_lib.l0_p32_div.argtypes = [ctypes.c_uint32, ctypes.c_uint32]
_lib.l0_p32_div.restype = ctypes.c_uint32

_lib.l0_p32_mulAdd.argtypes = [ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32]
_lib.l0_p32_mulAdd.restype = ctypes.c_uint32

_lib.l0_p32_to_double.argtypes = [ctypes.c_uint32]
_lib.l0_p32_to_double.restype = ctypes.c_double

_lib.l0_double_to_p32.argtypes = [ctypes.c_double]
_lib.l0_double_to_p32.restype = ctypes.c_uint32


# Low-level function wrappers
def p8_add(a: int, b: int) -> int:
    return _lib.l0_p8_add(a & 0xFF, b & 0xFF)

def p8_sub(a: int, b: int) -> int:
    return _lib.l0_p8_sub(a & 0xFF, b & 0xFF)

def p8_mul(a: int, b: int) -> int:
    return _lib.l0_p8_mul(a & 0xFF, b & 0xFF)

def p8_div(a: int, b: int) -> int:
    return _lib.l0_p8_div(a & 0xFF, b & 0xFF)

def p8_mulAdd(a: int, b: int, c: int) -> int:
    return _lib.l0_p8_mulAdd(a & 0xFF, b & 0xFF, c & 0xFF)

def p8_to_double(a: int) -> float:
    return _lib.l0_p8_to_double(a & 0xFF)

def double_to_p8(d: float) -> int:
    return _lib.l0_double_to_p8(float(d))


def p16_add(a: int, b: int) -> int:
    return _lib.l0_p16_add(a & 0xFFFF, b & 0xFFFF)

def p16_sub(a: int, b: int) -> int:
    return _lib.l0_p16_sub(a & 0xFFFF, b & 0xFFFF)

def p16_mul(a: int, b: int) -> int:
    return _lib.l0_p16_mul(a & 0xFFFF, b & 0xFFFF)

def p16_div(a: int, b: int) -> int:
    return _lib.l0_p16_div(a & 0xFFFF, b & 0xFFFF)

def p16_mulAdd(a: int, b: int, c: int) -> int:
    return _lib.l0_p16_mulAdd(a & 0xFFFF, b & 0xFFFF, c & 0xFFFF)

def p16_to_double(a: int) -> float:
    return _lib.l0_p16_to_double(a & 0xFFFF)

def double_to_p16(d: float) -> int:
    return _lib.l0_double_to_p16(float(d))


def p32_add(a: int, b: int) -> int:
    return _lib.l0_p32_add(a & 0xFFFFFFFF, b & 0xFFFFFFFF)

def p32_sub(a: int, b: int) -> int:
    return _lib.l0_p32_sub(a & 0xFFFFFFFF, b & 0xFFFFFFFF)

def p32_mul(a: int, b: int) -> int:
    return _lib.l0_p32_mul(a & 0xFFFFFFFF, b & 0xFFFFFFFF)

def p32_div(a: int, b: int) -> int:
    return _lib.l0_p32_div(a & 0xFFFFFFFF, b & 0xFFFFFFFF)

def p32_mulAdd(a: int, b: int, c: int) -> int:
    return _lib.l0_p32_mulAdd(a & 0xFFFFFFFF, b & 0xFFFFFFFF, c & 0xFFFFFFFF)

def p32_to_double(a: int) -> float:
    return _lib.l0_p32_to_double(a & 0xFFFFFFFF)

def double_to_p32(d: float) -> int:
    return _lib.l0_double_to_p32(float(d))


# Object-oriented classes for convenience
class Posit8:
    def __init__(self, val: Union[int, str, float] = 0):
        if isinstance(val, str):
            self.v = int(val, 0) & 0xFF
        elif isinstance(val, float):
            self.v = double_to_p8(val)
        else:
            self.v = int(val) & 0xFF

    @classmethod
    def from_double(cls, d: float) -> "Posit8":
        return cls(double_to_p8(d))

    @property
    def double(self) -> float:
        return p8_to_double(self.v)

    @property
    def hex(self) -> str:
        return f"0x{self.v:02X}"

    def __add__(self, other: "Posit8") -> "Posit8":
        return Posit8(p8_add(self.v, other.v))

    def __sub__(self, other: "Posit8") -> "Posit8":
        return Posit8(p8_sub(self.v, other.v))

    def __mul__(self, other: "Posit8") -> "Posit8":
        return Posit8(p8_mul(self.v, other.v))

    def __truediv__(self, other: "Posit8") -> "Posit8":
        return Posit8(p8_div(self.v, other.v))

    def mul_add(self, b: "Posit8", c: "Posit8") -> "Posit8":
        return Posit8(p8_mulAdd(self.v, b.v, c.v))

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Posit8):
            return self.v == other.v
        return self.v == (other & 0xFF)

    def __repr__(self) -> str:
        return f"Posit8(0x{self.v:02X}, val={self.double})"


class Posit16:
    def __init__(self, val: Union[int, str, float] = 0):
        if isinstance(val, str):
            self.v = int(val, 0) & 0xFFFF
        elif isinstance(val, float):
            self.v = double_to_p16(val)
        else:
            self.v = int(val) & 0xFFFF

    @classmethod
    def from_double(cls, d: float) -> "Posit16":
        return cls(double_to_p16(d))

    @property
    def double(self) -> float:
        return p16_to_double(self.v)

    @property
    def hex(self) -> str:
        return f"0x{self.v:04X}"

    def __add__(self, other: "Posit16") -> "Posit16":
        return Posit16(p16_add(self.v, other.v))

    def __sub__(self, other: "Posit16") -> "Posit16":
        return Posit16(p16_sub(self.v, other.v))

    def __mul__(self, other: "Posit16") -> "Posit16":
        return Posit16(p16_mul(self.v, other.v))

    def __truediv__(self, other: "Posit16") -> "Posit16":
        return Posit16(p16_div(self.v, other.v))

    def mul_add(self, b: "Posit16", c: "Posit16") -> "Posit16":
        return Posit16(p16_mulAdd(self.v, b.v, c.v))

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Posit16):
            return self.v == other.v
        return self.v == (other & 0xFFFF)

    def __repr__(self) -> str:
        return f"Posit16(0x{self.v:04X}, val={self.double})"


class Posit32:
    def __init__(self, val: Union[int, str, float] = 0):
        if isinstance(val, str):
            self.v = int(val, 0) & 0xFFFFFFFF
        elif isinstance(val, float):
            self.v = double_to_p32(val)
        else:
            self.v = int(val) & 0xFFFFFFFF

    @classmethod
    def from_double(cls, d: float) -> "Posit32":
        return cls(double_to_p32(d))

    @property
    def double(self) -> float:
        return p32_to_double(self.v)

    @property
    def hex(self) -> str:
        return f"0x{self.v:08X}"

    def __add__(self, other: "Posit32") -> "Posit32":
        return Posit32(p32_add(self.v, other.v))

    def __sub__(self, other: "Posit32") -> "Posit32":
        return Posit32(p32_sub(self.v, other.v))

    def __mul__(self, other: "Posit32") -> "Posit32":
        return Posit32(p32_mul(self.v, other.v))

    def __truediv__(self, other: "Posit32") -> "Posit32":
        return Posit32(p32_div(self.v, other.v))

    def mul_add(self, b: "Posit32", c: "Posit32") -> "Posit32":
        return Posit32(p32_mulAdd(self.v, b.v, c.v))

    def __eq__(self, other: object) -> bool:
        if isinstance(other, Posit32):
            return self.v == other.v
        return self.v == (other & 0xFFFFFFFF)

    def __repr__(self) -> str:
        return f"Posit32(0x{self.v:08X}, val={self.double})"
