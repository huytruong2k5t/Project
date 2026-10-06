#define SOFTPOSIT_BUILD_DLL 1
#include "softposit_api.h"
#include "softposit.h"

/* Posit 8 (ES=0) Operations */
uint8_t l0_p8_add(uint8_t a, uint8_t b) {
    posit8_t pa = { .v = a };
    posit8_t pb = { .v = b };
    posit8_t res = p8_add(pa, pb);
    return res.v;
}

uint8_t l0_p8_sub(uint8_t a, uint8_t b) {
    posit8_t pa = { .v = a };
    posit8_t pb = { .v = b };
    posit8_t res = p8_sub(pa, pb);
    return res.v;
}

uint8_t l0_p8_mul(uint8_t a, uint8_t b) {
    posit8_t pa = { .v = a };
    posit8_t pb = { .v = b };
    posit8_t res = p8_mul(pa, pb);
    return res.v;
}

uint8_t l0_p8_div(uint8_t a, uint8_t b) {
    posit8_t pa = { .v = a };
    posit8_t pb = { .v = b };
    posit8_t res = p8_div(pa, pb);
    return res.v;
}

uint8_t l0_p8_mulAdd(uint8_t a, uint8_t b, uint8_t c) {
    posit8_t pa = { .v = a };
    posit8_t pb = { .v = b };
    posit8_t pc = { .v = c };
    posit8_t res = p8_mulAdd(pa, pb, pc);
    return res.v;
}

double l0_p8_to_double(uint8_t a) {
    posit8_t pa = { .v = a };
    return convertP8ToDouble(pa);
}

uint8_t l0_double_to_p8(double d) {
    posit8_t res = convertDoubleToP8(d);
    return res.v;
}

/* Posit 16 (ES=1) Operations */
uint16_t l0_p16_add(uint16_t a, uint16_t b) {
    posit16_t pa = { .v = a };
    posit16_t pb = { .v = b };
    posit16_t res = p16_add(pa, pb);
    return res.v;
}

uint16_t l0_p16_sub(uint16_t a, uint16_t b) {
    posit16_t pa = { .v = a };
    posit16_t pb = { .v = b };
    posit16_t res = p16_sub(pa, pb);
    return res.v;
}

uint16_t l0_p16_mul(uint16_t a, uint16_t b) {
    posit16_t pa = { .v = a };
    posit16_t pb = { .v = b };
    posit16_t res = p16_mul(pa, pb);
    return res.v;
}

uint16_t l0_p16_div(uint16_t a, uint16_t b) {
    posit16_t pa = { .v = a };
    posit16_t pb = { .v = b };
    posit16_t res = p16_div(pa, pb);
    return res.v;
}

uint16_t l0_p16_mulAdd(uint16_t a, uint16_t b, uint16_t c) {
    posit16_t pa = { .v = a };
    posit16_t pb = { .v = b };
    posit16_t pc = { .v = c };
    posit16_t res = p16_mulAdd(pa, pb, pc);
    return res.v;
}

double l0_p16_to_double(uint16_t a) {
    posit16_t pa = { .v = a };
    return convertP16ToDouble(pa);
}

uint16_t l0_double_to_p16(double d) {
    posit16_t res = convertDoubleToP16(d);
    return res.v;
}

/* Posit 32 (ES=2) Operations */
uint32_t l0_p32_add(uint32_t a, uint32_t b) {
    posit32_t pa = { .v = a };
    posit32_t pb = { .v = b };
    posit32_t res = p32_add(pa, pb);
    return res.v;
}

uint32_t l0_p32_sub(uint32_t a, uint32_t b) {
    posit32_t pa = { .v = a };
    posit32_t pb = { .v = b };
    posit32_t res = p32_sub(pa, pb);
    return res.v;
}

uint32_t l0_p32_mul(uint32_t a, uint32_t b) {
    posit32_t pa = { .v = a };
    posit32_t pb = { .v = b };
    posit32_t res = p32_mul(pa, pb);
    return res.v;
}

uint32_t l0_p32_div(uint32_t a, uint32_t b) {
    posit32_t pa = { .v = a };
    posit32_t pb = { .v = b };
    posit32_t res = p32_div(pa, pb);
    return res.v;
}

uint32_t l0_p32_mulAdd(uint32_t a, uint32_t b, uint32_t c) {
    posit32_t pa = { .v = a };
    posit32_t pb = { .v = b };
    posit32_t pc = { .v = c };
    posit32_t res = p32_mulAdd(pa, pb, pc);
    return res.v;
}

double l0_p32_to_double(uint32_t a) {
    posit32_t pa = { .v = a };
    return convertP32ToDouble(pa);
}

uint32_t l0_double_to_p32(double d) {
    posit32_t res = convertDoubleToP32(d);
    return res.v;
}
