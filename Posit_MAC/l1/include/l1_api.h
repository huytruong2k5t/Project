#ifndef POSIT_L1_API_H
#define POSIT_L1_API_H
#include <stdint.h>
#if defined(_WIN32)
# if defined(L1_BUILD_DLL)
#  define L1_EXPORT __declspec(dllexport)
# else
#  define L1_EXPORT __declspec(dllimport)
# endif
#else
# define L1_EXPORT __attribute__((visibility("default")))
#endif
#ifdef __cplusplus
extern "C" {
#endif
/* Stable uint32 ABI, also usable from DPI-C and ctypes. Return codes:
   0 success, 1 invalid arguments/config, 2 allocation/internal error.
   Failure leaves output and accumulator unchanged. No exceptions cross C ABI.
   version:0/1; exact:0/1; ops:0/1; scheme:0 FLOOR/1 STICKY_ACC;
   rounding:0 RNE/1 TRUNC. flags: nar[4],sat_max[3],sat_min[2],inexact[1],approx_cut[0]. */
typedef struct l1_mac_config {
    uint32_t version,exact,n,ops,scheme,rounding;
} l1_mac_config;
typedef struct l1_mac_result {uint32_t bits,flags,iterations,bypass;} l1_mac_result;
typedef struct l1_accumulator l1_accumulator;
L1_EXPORT uint32_t l1_p32_mul(uint32_t a,uint32_t b);
L1_EXPORT uint32_t l1_p32_mac(uint32_t a,uint32_t b,uint32_t c);
L1_EXPORT int l1_mac_eval(uint32_t nb,uint32_t es,uint32_t a,uint32_t b,uint32_t c,
                         const l1_mac_config* config,l1_mac_result* result);
/* NULL config selects exact, v1, RNE. Supported formats:8/0,16/1,32/2,32/3.
   Opaque handle ownership stays with the caller. Serialize access to one handle. */
L1_EXPORT l1_accumulator* l1_acc_create(uint32_t nb,uint32_t es);
L1_EXPORT int l1_acc_reset(l1_accumulator* handle);
L1_EXPORT int l1_acc_step(l1_accumulator* handle,uint32_t a,uint32_t b,uint32_t c,
                         uint32_t acc_mode,uint32_t acc_clr,const l1_mac_config* config,
                         l1_mac_result* result);
L1_EXPORT void l1_acc_destroy(l1_accumulator* handle);
#ifdef __cplusplus
}
#endif
#endif
