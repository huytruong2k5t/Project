#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "softposit_api.h"

static void print_usage(const char *prog) {
    printf("Usage: %s <command> [args...]\n", prog);
    printf("Commands:\n");
    printf("  p8_add <hex_a> <hex_b>\n");
    printf("  p8_sub <hex_a> <hex_b>\n");
    printf("  p8_mul <hex_a> <hex_b>\n");
    printf("  p8_mulAdd <hex_a> <hex_b> <hex_c>\n");
    printf("  p8_to_double <hex_a>\n");
    printf("  double_to_p8 <double_val>\n");
    printf("\n");
    printf("  p16_add <hex_a> <hex_b>\n");
    printf("  p16_sub <hex_a> <hex_b>\n");
    printf("  p16_mul <hex_a> <hex_b>\n");
    printf("  p16_mulAdd <hex_a> <hex_b> <hex_c>\n");
    printf("  p16_to_double <hex_a>\n");
    printf("  double_to_p16 <double_val>\n");
    printf("\n");
    printf("  p32_add <hex_a> <hex_b>\n");
    printf("  p32_sub <hex_a> <hex_b>\n");
    printf("  p32_mul <hex_a> <hex_b>\n");
    printf("  p32_mulAdd <hex_a> <hex_b> <hex_c>\n");
    printf("  p32_to_double <hex_a>\n");
    printf("  double_to_p32 <double_val>\n");
    printf("\n");
    printf("  test_corners\n");
}

static int run_corner_tests(void) {
    int pass = 0, fail = 0;
    printf("============================================================\n");
    printf("  SoftPosit Golden Model - Comprehensive Corner Verification\n");
    printf("============================================================\n");

    /* 1. p32 Basic Values */
    uint32_t p32_zero   = 0x00000000;
    uint32_t p32_nar    = 0x80000000;
    uint32_t p32_one    = 0x40000000; // +1.0
    uint32_t p32_neg1   = 0xC0000000; // -1.0
    uint32_t p32_minpos = 0x00000001; // minpos
    uint32_t p32_negmin = 0xFFFFFFFF; // -minpos
    uint32_t p32_maxpos = 0x7FFFFFFF; // maxpos
    uint32_t p32_negmax = 0x80000001; // -maxpos

    printf("\n--- Test Suite 1: Posit32 Corner Combinations (§6.4) ---\n");

    /* NaR * 0 -> NaR */
    uint32_t r = l0_p32_mul(p32_nar, p32_zero);
    if (r == p32_nar) { printf("[PASS] NaR * 0 = 0x%08X (NaR)\n", r); pass++; }
    else { printf("[FAIL] NaR * 0 = 0x%08X, expected 0x%08X\n", r, p32_nar); fail++; }

    /* 0 * NaR -> NaR */
    r = l0_p32_mul(p32_zero, p32_nar);
    if (r == p32_nar) { printf("[PASS] 0 * NaR = 0x%08X (NaR)\n", r); pass++; }
    else { printf("[FAIL] 0 * NaR = 0x%08X, expected 0x%08X\n", r, p32_nar); fail++; }

    /* maxpos * maxpos -> maxpos (overflow/saturation) */
    r = l0_p32_mul(p32_maxpos, p32_maxpos);
    if (r == p32_maxpos) { printf("[PASS] maxpos * maxpos = 0x%08X (maxpos)\n", r); pass++; }
    else { printf("[FAIL] maxpos * maxpos = 0x%08X, expected 0x%08X\n", r, p32_maxpos); fail++; }

    /* minpos * minpos -> minpos (underflow/saturation) */
    r = l0_p32_mul(p32_minpos, p32_minpos);
    if (r == p32_minpos) { printf("[PASS] minpos * minpos = 0x%08X (minpos)\n", r); pass++; }
    else { printf("[FAIL] minpos * minpos = 0x%08X, expected 0x%08X\n", r, p32_minpos); fail++; }

    /* (-maxpos) * (-maxpos) -> maxpos */
    r = l0_p32_mul(p32_negmax, p32_negmax);
    if (r == p32_maxpos) { printf("[PASS] (-maxpos) * (-maxpos) = 0x%08X (maxpos)\n", r); pass++; }
    else { printf("[FAIL] (-maxpos) * (-maxpos) = 0x%08X, expected 0x%08X\n", r, p32_maxpos); fail++; }

    /* maxpos * minpos -> 0x40000000 (1.0 for ES=2) */
    r = l0_p32_mul(p32_maxpos, p32_minpos);
    if (r == p32_one) { printf("[PASS] maxpos * minpos = 0x%08X (1.0 for ES=2)\n", r); pass++; }
    else { printf("[FAIL] maxpos * minpos = 0x%08X, expected 0x%08X\n", r, p32_one); fail++; }

    /* maxpos + maxpos -> maxpos */
    r = l0_p32_add(p32_maxpos, p32_maxpos);
    if (r == p32_maxpos) { printf("[PASS] maxpos + maxpos = 0x%08X (maxpos)\n", r); pass++; }
    else { printf("[FAIL] maxpos + maxpos = 0x%08X, expected 0x%08X\n", r, p32_maxpos); fail++; }

    /* x + (-x) -> 0 */
    r = l0_p32_add(p32_one, p32_neg1);
    if (r == p32_zero) { printf("[PASS] (+1) + (-1) = 0x%08X (0.0)\n", r); pass++; }
    else { printf("[FAIL] (+1) + (-1) = 0x%08X, expected 0x%08X\n", r, p32_zero); fail++; }

    r = l0_p32_add(p32_maxpos, p32_negmax);
    if (r == p32_zero) { printf("[PASS] maxpos + (-maxpos) = 0x%08X (0.0)\n", r); pass++; }
    else { printf("[FAIL] maxpos + (-maxpos) = 0x%08X, expected 0x%08X\n", r, p32_zero); fail++; }

    /* 1 + minpos -> 1.0 (since minpos is below precision of 1.0 in p32) */
    r = l0_p32_add(p32_one, p32_minpos);
    if (r == p32_one) { printf("[PASS] 1 + minpos = 0x%08X (1.0 due to underflow)\n", r); pass++; }
    else { printf("[FAIL] 1 + minpos = 0x%08X, expected 0x%08X\n", r, p32_one); fail++; }

    /* NaR propagation in MAC */
    r = l0_p32_mulAdd(p32_nar, p32_one, p32_zero);
    if (r == p32_nar) { printf("[PASS] p32_mulAdd(NaR, 1, 0) = 0x%08X (NaR)\n", r); pass++; }
    else { printf("[FAIL] p32_mulAdd(NaR, 1, 0) = 0x%08X, expected 0x%08X\n", r, p32_nar); fail++; }

    r = l0_p32_mulAdd(p32_one, p32_one, p32_nar);
    if (r == p32_nar) { printf("[PASS] p32_mulAdd(1, 1, NaR) = 0x%08X (NaR)\n", r); pass++; }
    else { printf("[FAIL] p32_mulAdd(1, 1, NaR) = 0x%08X, expected 0x%08X\n", r, p32_nar); fail++; }

    /* 1 * 1 + 1 -> 2.0 (0x48000000 for ES=2: regime k=0, exp=1 -> 2^1 = 2) */
    r = l0_p32_mulAdd(p32_one, p32_one, p32_one);
    uint32_t p32_two = 0x48000000;
    if (r == p32_two) { printf("[PASS] p32_mulAdd(1, 1, 1) = 0x%08X (2.0)\n", r); pass++; }
    else { printf("[FAIL] p32_mulAdd(1, 1, 1) = 0x%08X, expected 0x%08X\n", r, p32_two); fail++; }

    printf("\n--- Test Suite 2: TV-RND Posit8 Test Vectors (§3.4) ---\n");
    /* TV-RND-00: 0.1 -> 0x06 */
    uint8_t p8_res = l0_double_to_p8(0.1);
    if (p8_res == 0x06) { printf("[PASS] TV-RND-00: double(0.1) -> p8 = 0x%02X (= 0.09375)\n", p8_res); pass++; }
    else { printf("[FAIL] TV-RND-00: double(0.1) -> p8 = 0x%02X, expected 0x06\n", p8_res); fail++; }

    /* TV-RND-01: 1 + 2^-6 = 1.015625 -> 0x40 (1.0, tie even) */
    p8_res = l0_double_to_p8(1.0 + 1.0/64.0);
    if (p8_res == 0x40) { printf("[PASS] TV-RND-01: double(1 + 2^-6) -> p8 = 0x%02X (1.0, RNE tie round-to-even)\n", p8_res); pass++; }
    else { printf("[FAIL] TV-RND-01: double(1 + 2^-6) -> p8 = 0x%02X, expected 0x40\n", p8_res); fail++; }

    /* TV-RND-02: 1 + 3*2^-6 = 1.046875 -> 0x42 (1.0625, tie odd round up) */
    p8_res = l0_double_to_p8(1.0 + 3.0/64.0);
    if (p8_res == 0x42) { printf("[PASS] TV-RND-02: double(1 + 3*2^-6) -> p8 = 0x%02X (1.0625, RNE tie round-up)\n", p8_res); pass++; }
    else { printf("[FAIL] TV-RND-02: double(1 + 3*2^-6) -> p8 = 0x%02X, expected 0x42\n", p8_res); fail++; }

    /* TV-RND-03: 100 -> 0x7F (maxpos saturation = 64) */
    p8_res = l0_double_to_p8(100.0);
    if (p8_res == 0x7F) { printf("[PASS] TV-RND-03: double(100.0) -> p8 = 0x%02X (maxpos = 64)\n", p8_res); pass++; }
    else { printf("[FAIL] TV-RND-03: double(100.0) -> p8 = 0x%02X, expected 0x7F\n", p8_res); fail++; }

    /* TV-RND-04: 0.001 -> 0x01 (minpos saturation = 2^-6) */
    p8_res = l0_double_to_p8(0.001);
    if (p8_res == 0x01) { printf("[PASS] TV-RND-04: double(0.001) -> p8 = 0x%02X (minpos = 2^-6)\n", p8_res); pass++; }
    else { printf("[FAIL] TV-RND-04: double(0.001) -> p8 = 0x%02X, expected 0x01\n", p8_res); fail++; }

    printf("\n--- Test Suite 3: Max Regime Cases (m = NB - 1) ---\n");
    /* For p8: NB=8, m=7 -> 0x7F (maxpos) and 0x01 (minpos) */
    uint8_t p8_mr_max = 0x7F;
    uint8_t p8_mr_min = 0x01;
    uint8_t p8_r = l0_p8_mul(p8_mr_max, p8_mr_min);
    /* For ES=0: maxpos = 2^6 = 64, minpos = 2^-6 = 1/64 -> product = 1.0 = 0x40 */
    if (p8_r == 0x40) { printf("[PASS] p8 maxpos * minpos = 0x%02X (1.0 for ES=0)\n", p8_r); pass++; }
    else { printf("[FAIL] p8 maxpos * minpos = 0x%02X, expected 0x40\n", p8_r); fail++; }

    /* For p16: NB=16, m=15 -> 0x7FFF (maxpos) and 0x0001 (minpos) */
    uint16_t p16_mr_max = 0x7FFF;
    uint16_t p16_mr_min = 0x0001;
    uint16_t p16_r = l0_p16_mul(p16_mr_max, p16_mr_min);
    /* For ES=1: maxpos = 2^28, minpos = 2^-28 -> product = 1.0 = 0x4000 */
    if (p16_r == 0x4000) { printf("[PASS] p16 maxpos * minpos = 0x%04X (1.0 for ES=1)\n", p16_r); pass++; }
    else { printf("[FAIL] p16 maxpos * minpos = 0x%04X, expected 0x4000\n", p16_r); fail++; }

    /* Posit16 corners */
    uint16_t p16_nar = 0x8000;
    uint16_t p16_zero = 0x0000;
    p16_r = l0_p16_mul(p16_nar, p16_zero);
    if (p16_r == p16_nar) { printf("[PASS] p16 NaR * 0 = 0x%04X (NaR)\n", p16_r); pass++; }
    else { printf("[FAIL] p16 NaR * 0 = 0x%04X, expected 0x%04X\n", p16_r, p16_nar); fail++; }

    printf("\n============================================================\n");
    printf("  Results: %d PASSED, %d FAILED (Total %d tests)\n", pass, fail, pass + fail);
    printf("============================================================\n");
    return (fail == 0) ? 0 : 1;
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }

    const char *cmd = argv[1];

    if (strcmp(cmd, "test_corners") == 0) {
        return run_corner_tests();
    }

    if (strcmp(cmd, "p8_add") == 0 && argc >= 4) {
        uint8_t a = (uint8_t)strtoul(argv[2], NULL, 0);
        uint8_t b = (uint8_t)strtoul(argv[3], NULL, 0);
        uint8_t r = l0_p8_add(a, b);
        printf("0x%02X (double: %g)\n", r, l0_p8_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p8_sub") == 0 && argc >= 4) {
        uint8_t a = (uint8_t)strtoul(argv[2], NULL, 0);
        uint8_t b = (uint8_t)strtoul(argv[3], NULL, 0);
        uint8_t r = l0_p8_sub(a, b);
        printf("0x%02X (double: %g)\n", r, l0_p8_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p8_mul") == 0 && argc >= 4) {
        uint8_t a = (uint8_t)strtoul(argv[2], NULL, 0);
        uint8_t b = (uint8_t)strtoul(argv[3], NULL, 0);
        uint8_t r = l0_p8_mul(a, b);
        printf("0x%02X (double: %g)\n", r, l0_p8_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p8_mulAdd") == 0 && argc >= 5) {
        uint8_t a = (uint8_t)strtoul(argv[2], NULL, 0);
        uint8_t b = (uint8_t)strtoul(argv[3], NULL, 0);
        uint8_t c = (uint8_t)strtoul(argv[4], NULL, 0);
        uint8_t r = l0_p8_mulAdd(a, b, c);
        printf("0x%02X (double: %g)\n", r, l0_p8_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p8_to_double") == 0 && argc >= 3) {
        uint8_t a = (uint8_t)strtoul(argv[2], NULL, 0);
        printf("%g\n", l0_p8_to_double(a));
        return 0;
    }

    if (strcmp(cmd, "double_to_p8") == 0 && argc >= 3) {
        double d = atof(argv[2]);
        uint8_t r = l0_double_to_p8(d);
        printf("0x%02X\n", r);
        return 0;
    }

    /* Posit 16 */
    if (strcmp(cmd, "p16_add") == 0 && argc >= 4) {
        uint16_t a = (uint16_t)strtoul(argv[2], NULL, 0);
        uint16_t b = (uint16_t)strtoul(argv[3], NULL, 0);
        uint16_t r = l0_p16_add(a, b);
        printf("0x%04X (double: %g)\n", r, l0_p16_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p16_mul") == 0 && argc >= 4) {
        uint16_t a = (uint16_t)strtoul(argv[2], NULL, 0);
        uint16_t b = (uint16_t)strtoul(argv[3], NULL, 0);
        uint16_t r = l0_p16_mul(a, b);
        printf("0x%04X (double: %g)\n", r, l0_p16_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p16_mulAdd") == 0 && argc >= 5) {
        uint16_t a = (uint16_t)strtoul(argv[2], NULL, 0);
        uint16_t b = (uint16_t)strtoul(argv[3], NULL, 0);
        uint16_t c = (uint16_t)strtoul(argv[4], NULL, 0);
        uint16_t r = l0_p16_mulAdd(a, b, c);
        printf("0x%04X (double: %g)\n", r, l0_p16_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p16_to_double") == 0 && argc >= 3) {
        uint16_t a = (uint16_t)strtoul(argv[2], NULL, 0);
        printf("%g\n", l0_p16_to_double(a));
        return 0;
    }

    if (strcmp(cmd, "double_to_p16") == 0 && argc >= 3) {
        double d = atof(argv[2]);
        uint16_t r = l0_double_to_p16(d);
        printf("0x%04X\n", r);
        return 0;
    }

    /* Posit 32 */
    if (strcmp(cmd, "p32_add") == 0 && argc >= 4) {
        uint32_t a = (uint32_t)strtoul(argv[2], NULL, 0);
        uint32_t b = (uint32_t)strtoul(argv[3], NULL, 0);
        uint32_t r = l0_p32_add(a, b);
        printf("0x%08X (double: %.17g)\n", r, l0_p32_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p32_sub") == 0 && argc >= 4) {
        uint32_t a = (uint32_t)strtoul(argv[2], NULL, 0);
        uint32_t b = (uint32_t)strtoul(argv[3], NULL, 0);
        uint32_t r = l0_p32_sub(a, b);
        printf("0x%08X (double: %.17g)\n", r, l0_p32_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p32_mul") == 0 && argc >= 4) {
        uint32_t a = (uint32_t)strtoul(argv[2], NULL, 0);
        uint32_t b = (uint32_t)strtoul(argv[3], NULL, 0);
        uint32_t r = l0_p32_mul(a, b);
        printf("0x%08X (double: %.17g)\n", r, l0_p32_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p32_mulAdd") == 0 && argc >= 5) {
        uint32_t a = (uint32_t)strtoul(argv[2], NULL, 0);
        uint32_t b = (uint32_t)strtoul(argv[3], NULL, 0);
        uint32_t c = (uint32_t)strtoul(argv[4], NULL, 0);
        uint32_t r = l0_p32_mulAdd(a, b, c);
        printf("0x%08X (double: %.17g)\n", r, l0_p32_to_double(r));
        return 0;
    }

    if (strcmp(cmd, "p32_to_double") == 0 && argc >= 3) {
        uint32_t a = (uint32_t)strtoul(argv[2], NULL, 0);
        printf("%.17g\n", l0_p32_to_double(a));
        return 0;
    }

    if (strcmp(cmd, "double_to_p32") == 0 && argc >= 3) {
        double d = atof(argv[2]);
        uint32_t r = l0_double_to_p32(d);
        printf("0x%08X\n", r);
        return 0;
    }

    print_usage(argv[0]);
    return 1;
}
