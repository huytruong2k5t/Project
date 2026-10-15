#pragma once
#include <cstdint>
namespace week12 {
struct Case {
    uint32_t a,b,c;
    uint8_t n,ops,control,reserved;
};
static_assert(sizeof(Case)==16,"fixed x86 little-endian corpus record");
}
