CROSS_COMPILE ?= aarch64-linux-gnu-
CC      := $(CROSS_COMPILE)gcc
LD      := $(CROSS_COMPILE)ld
OBJCOPY := $(CROSS_COMPILE)objcopy

# 운영체제 없이 도는 코드(freestanding)를 위한 옵션
CFLAGS  := -O2 -g -Wall -Wextra -ffreestanding -fno-pie -fno-stack-protector \
           -fno-tree-loop-distribute-patterns -mgeneral-regs-only -mstrict-align \
           -Icommon -MMD -MP
ASFLAGS := -g -Icommon -MMD -MP
# 코드와 데이터가 같은 메모리에 있다는 경고(binutils 2.39+)는 베어메탈에서는 정상이라 끈다
LDFLAGS := $(shell $(LD) --help 2>/dev/null | grep -q no-warn-rwx-segments && echo --no-warn-rwx-segments)

ROM_SRCS    := $(wildcard rom/*.S rom/*.c common/*.c)
STAGE2_SRCS := $(wildcard stage2/*.S stage2/*.c common/*.c)
ROM_OBJS    := $(patsubst %,build/%.o,$(ROM_SRCS))
STAGE2_OBJS := $(patsubst %,build/%.o,$(STAGE2_SRCS))

QEMU := qemu-system-aarch64 -machine virt,secure=on -cpu cortex-a57 -m 1G \
        -nographic -serial mon:stdio \
        -serial tcp:127.0.0.1:4444,server=on,wait=off

all: rom.bin

rom.elf: $(ROM_OBJS) rom/rom.ld
	$(LD) $(LDFLAGS) -T rom/rom.ld -Map rom.map -o $@ $(ROM_OBJS)

stage2.elf: $(STAGE2_OBJS) stage2/stage2.ld
	$(LD) $(LDFLAGS) -T stage2/stage2.ld -Map stage2.map -o $@ $(STAGE2_OBJS)

%.bin: %.elf
	$(OBJCOPY) -O binary $< $@

build/%.c.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

build/%.S.o: %.S
	@mkdir -p $(dir $@)
	$(CC) $(ASFLAGS) -c $< -o $@

# 3장: 부트 이미지와 64MiB 플래시 이미지
boot.img: stage2.bin tools/mkbootimg.py
	python3 tools/mkbootimg.py stage2.bin $@

flash.img: boot.img
	rm -f $@
	truncate -s 64M $@
	dd if=boot.img of=$@ conv=notrunc status=none

image: flash.img

# GDB로 디버깅할 때: make run EXTRA="-s -S"
run: rom.bin
	$(QEMU) -bios rom.bin $(EXTRA)

run-flash: rom.bin flash.img
	$(QEMU) -bios rom.bin -drive if=pflash,format=raw,index=1,file=flash.img $(EXTRA)

clean:
	rm -rf build *.elf *.bin *.map *.img

.PHONY: all image run run-flash clean
.DELETE_ON_ERROR:

-include $(ROM_OBJS:.o=.d) $(STAGE2_OBJS:.o=.d)
