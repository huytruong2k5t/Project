#ifndef SOFTPOSIT_API_H
#define SOFTPOSIT_API_H

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if defined(_WIN32) || defined(__CYGWIN__)
  #if defined(SOFTPOSIT_BUILD_DLL)
    #define SOFTPOSIT_EXPORT __declspec(dllexport)
  #else
    #define SOFTPOSIT_EXPORT __declspec(dllimport)
  #endif
#else
  #if defined(__GNUC__) && __GNUC__ >= 4
    #define SOFTPOSIT_EXPORT __attribute__((visibility("default")))
  #else
    #define SOFTPOSIT_EXPORT
  #endif
#endif

/* Posit 8 (ES=0) Operations */
SOFTPOSIT_EXPORT uint8_t  l0_p8_add(uint8_t a, uint8_t b);
SOFTPOSIT_EXPORT uint8_t  l0_p8_sub(uint8_t a, uint8_t b);
SOFTPOSIT_EXPORT uint8_t  l0_p8_mul(uint8_t a, uint8_t b);
SOFTPOSIT_EXPORT uint8_t  l0_p8_div(uint8_t a, uint8_t b);
SOFTPOSIT_EXPORT uint8_t  l0_p8_mulAdd(uint8_t a, uint8_t b, uint8_t c);
SOFTPOSIT_EXPORT double   l0_p8_to_double(uint8_t a);
SOFTPOSIT_EXPORT uint8_t  l0_double_to_p8(double d);

/* Posit 16 (ES=1) Operations */
SOFTPOSIT_EXPORT uint16_t l0_p16_add(uint16_t a, uint16_t b);
SOFTPOSIT_EXPORT uint16_t l0_p16_sub(uint16_t a, uint16_t b);
SOFTPOSIT_EXPORT uint16_t l0_p16_mul(uint16_t a, uint16_t b);
SOFTPOSIT_EXPORT uint16_t l0_p16_div(uint16_t a, uint16_t b);
SOFTPOSIT_EXPORT uint16_t l0_p16_mulAdd(uint16_t a, uint16_t b, uint16_t c);
SOFTPOSIT_EXPORT double   l0_p16_to_double(uint16_t a);
SOFTPOSIT_EXPORT uint16_t l0_double_to_p16(double d);

/* Posit 32 (ES=2) Operations */
SOFTPOSIT_EXPORT uint32_t l0_p32_add(uint32_t a, uint32_t b);
SOFTPOSIT_EXPORT uint32_t l0_p32_sub(uint32_t a, uint32_t b);
SOFTPOSIT_EXPORT uint32_t l0_p32_mul(uint32_t a, uint32_t b);
SOFTPOSIT_EXPORT uint32_t l0_p32_div(uint32_t a, uint32_t b);
SOFTPOSIT_EXPORT uint32_t l0_p32_mulAdd(uint32_t a, uint32_t b, uint32_t c);
SOFTPOSIT_EXPORT double   l0_p32_to_double(uint32_t a);
SOFTPOSIT_EXPORT uint32_t l0_double_to_p32(double d);

#ifdef __cplusplus
}
#endif

#endif /* SOFTPOSIT_API_H */
