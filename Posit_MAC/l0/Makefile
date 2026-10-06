# Makefile for building SoftPosit C API, DLL, shared object, and CLI tool
# Works in WSL/Linux and cross-compiles for Windows MinGW

SOURCE_DIR = SoftPosit_src/source
BUILD_DIR = SoftPosit_src/build/Linux-x86_64-GCC
INCLUDE_DIRS = -I. -I$(SOURCE_DIR)/include -I$(SOURCE_DIR)/8086-SSE -I$(BUILD_DIR)

# Source files needed for p8, p16, p32 operations and conversions
C_SRCS = \
	$(SOURCE_DIR)/s_addMagsP8.c \
	$(SOURCE_DIR)/s_subMagsP8.c \
	$(SOURCE_DIR)/s_mulAddP8.c \
	$(SOURCE_DIR)/p8_add.c \
	$(SOURCE_DIR)/p8_sub.c \
	$(SOURCE_DIR)/p8_mul.c \
	$(SOURCE_DIR)/p8_div.c \
	$(SOURCE_DIR)/p8_mulAdd.c \
	$(SOURCE_DIR)/p8_to_i32.c \
	$(SOURCE_DIR)/p8_to_i64.c \
	$(SOURCE_DIR)/p8_to_p16.c \
	$(SOURCE_DIR)/p8_to_p32.c \
	$(SOURCE_DIR)/i32_to_p8.c \
	$(SOURCE_DIR)/i64_to_p8.c \
	$(SOURCE_DIR)/ui32_to_p8.c \
	$(SOURCE_DIR)/ui64_to_p8.c \
	$(SOURCE_DIR)/c_convertDecToPosit8.c \
	$(SOURCE_DIR)/c_convertPosit8ToDec.c \
	$(SOURCE_DIR)/s_addMagsP16.c \
	$(SOURCE_DIR)/s_subMagsP16.c \
	$(SOURCE_DIR)/s_mulAddP16.c \
	$(SOURCE_DIR)/p16_add.c \
	$(SOURCE_DIR)/p16_sub.c \
	$(SOURCE_DIR)/p16_mul.c \
	$(SOURCE_DIR)/p16_div.c \
	$(SOURCE_DIR)/p16_mulAdd.c \
	$(SOURCE_DIR)/p16_to_i32.c \
	$(SOURCE_DIR)/p16_to_i64.c \
	$(SOURCE_DIR)/p16_to_p8.c \
	$(SOURCE_DIR)/p16_to_p32.c \
	$(SOURCE_DIR)/i32_to_p16.c \
	$(SOURCE_DIR)/i64_to_p16.c \
	$(SOURCE_DIR)/ui32_to_p16.c \
	$(SOURCE_DIR)/ui64_to_p16.c \
	$(SOURCE_DIR)/c_convertDecToPosit16.c \
	$(SOURCE_DIR)/c_convertPosit16ToDec.c \
	$(SOURCE_DIR)/s_addMagsP32.c \
	$(SOURCE_DIR)/s_subMagsP32.c \
	$(SOURCE_DIR)/s_mulAddP32.c \
	$(SOURCE_DIR)/p32_add.c \
	$(SOURCE_DIR)/p32_sub.c \
	$(SOURCE_DIR)/p32_mul.c \
	$(SOURCE_DIR)/p32_div.c \
	$(SOURCE_DIR)/p32_mulAdd.c \
	$(SOURCE_DIR)/p32_to_i32.c \
	$(SOURCE_DIR)/p32_to_i64.c \
	$(SOURCE_DIR)/p32_to_p8.c \
	$(SOURCE_DIR)/p32_to_p16.c \
	$(SOURCE_DIR)/i32_to_p32.c \
	$(SOURCE_DIR)/i64_to_p32.c \
	$(SOURCE_DIR)/ui32_to_p32.c \
	$(SOURCE_DIR)/ui64_to_p32.c \
	$(SOURCE_DIR)/c_convertDecToPosit32.c \
	$(SOURCE_DIR)/c_convertPosit32ToDec.c \
	$(SOURCE_DIR)/c_int.c \
	$(SOURCE_DIR)/quire_helper.c \
	softposit_api.c

CFLAGS_COMMON = -O3 -DSOFTPOSIT_FAST_INT64 -DINLINE_LEVEL=5 $(INCLUDE_DIRS)

.PHONY: all linux windows clean

all: linux windows

linux: libsoftposit.so softposit_cli

windows: softposit.dll softposit_cli.exe

# Linux shared library and CLI
libsoftposit.so: $(C_SRCS)
	gcc -shared -fPIC $(CFLAGS_COMMON) -o $@ $^ -lm

softposit_cli: softposit_cli.c libsoftposit.so
	gcc $(CFLAGS_COMMON) softposit_cli.c -L. -lsoftposit -Wl,-rpath,. -lm -o $@

# Windows 64-bit DLL and CLI using MinGW
softposit.dll: $(C_SRCS)
	x86_64-w64-mingw32-gcc -shared -DSOFTPOSIT_BUILD_DLL $(CFLAGS_COMMON) -o $@ $^

softposit_cli.exe: softposit_cli.c softposit.dll
	x86_64-w64-mingw32-gcc $(CFLAGS_COMMON) softposit_cli.c -L. -l:softposit.dll -o $@

clean:
	rm -f libsoftposit.so softposit_cli softposit.dll softposit_cli.exe *.o
