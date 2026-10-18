#include <cassert>
#include "week14_counters.hpp"
int main() {
    using C=week14::Counters;
    static_assert(2*2*5*5==100);
    for(unsigned d=0;d<5;++d)for(unsigned z=0;z<5;++z)
        assert(C::key(false,false,d,z)==5*d+z);
    assert(C::key(true,true,4,4)==99);
    assert(C::delta_bucket(28,26)==3&&C::delta_bucket(29,26)==4);
    assert(C::lzc_bucket(15)==3&&C::lzc_bucket(16)==4);
    C c;
    c.sample(true,true,true,0,0,0,false,true,0,4,false);
    c.sample(false,true,true,1,0,0,false,true,0,4,false);
    c.sample(true,true,false,1,4,0,true,true,2,0,true);
    assert(c.completed==3&&c.near_before==2&&c.near_after==1&&c.special==1&&c.exact_zero==1);
    assert(c.before[0]==1&&c.before[9]==1&&c.after[0]==1);
    assert(c.fused_cross[29]==1);
    bool rejected=false;
    try {c.sample(true,true,true,2,0,0,false,true,0,0,false);} catch(...) {rejected=true;}
    assert(rejected);
}
