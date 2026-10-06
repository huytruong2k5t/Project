#include "l1_api.h"
#include <stdio.h>
/* A real C translation unit verifies the ABI header and linkage (not a C++ client). */
int main(void) {
    l1_mac_result r={0};
    l1_mac_config c={1,1,2,0,0,0};
    l1_accumulator* h=l1_acc_create(32,2);
    if(!h || l1_p32_mac(0x40000000,0x40000000,0)!=0x40000000) return 1;
    if(l1_mac_eval(32,2,0x40000000,0x40000000,0,&c,&r) || r.bits!=0x40000000 || r.flags) return 2;
    if(l1_acc_step(h,0x40000000,0x40000000,0x80000000,1,1,&c,&r) || r.bits!=0x40000000) return 3;
    if(l1_acc_reset(h)) return 4;
    l1_acc_destroy(h);
    puts("C_HEADER_AND_LINKAGE PASS");return 0;
}
