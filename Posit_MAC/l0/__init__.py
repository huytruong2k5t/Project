"""
L0 Golden Reference Package using SoftPosit
"""

from .softposit import (
    Posit8, Posit16, Posit32,
    p8_add, p8_sub, p8_mul, p8_div, p8_mulAdd, p8_to_double, double_to_p8,
    p16_add, p16_sub, p16_mul, p16_div, p16_mulAdd, p16_to_double, double_to_p16,
    p32_add, p32_sub, p32_mul, p32_div, p32_mulAdd, p32_to_double, double_to_p32
)

__all__ = [
    "Posit8", "Posit16", "Posit32",
    "p8_add", "p8_sub", "p8_mul", "p8_div", "p8_mulAdd", "p8_to_double", "double_to_p8",
    "p16_add", "p16_sub", "p16_mul", "p16_div", "p16_mulAdd", "p16_to_double", "double_to_p16",
    "p32_add", "p32_sub", "p32_mul", "p32_div", "p32_mulAdd", "p32_to_double", "double_to_p32"
]
