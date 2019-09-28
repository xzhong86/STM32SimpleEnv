# zpzhong, stm32 simple project

PREFIX = $(HOME)/local/bin/arm-none-eabi-

ST_FLASH = $(HOME)/local/bin/st-flash

CUBE_ROOT    = $(HOME)/work/geek/stm32/stm32cube/STM32Cube_FW_F1_V1.8.0
CUBE_DRIVER  = $(CUBE_ROOT)/Drivers
CUBE_PROJECT = $(CUBE_ROOT)/Projects/STM32F103RB-Nucleo/Templates
STM32_TYPE   = STM32F1xx

startup.s = $(CUBE_PROJECT)/SW4STM32/startup_stm32f103xb.s
ld-script = $(CUBE_PROJECT)/SW4STM32/STM32F103RB_Nucleo/STM32F103VBIx_FLASH.ld

hal_src   = $(CUBE_DRIVER)/$(STM32_TYPE)_HAL_Driver/Src
hal_objs  = $(patsubst $(hal_src)/%.c,hal_objs/%.o,$(wildcard $(hal_src)/*.c))
hal_objs := $(filter-out %template.o, $(hal_objs))
libhal    = hal_objs/libhal.a

CUBE_INC  = -I$(CUBE_DRIVER)/$(STM32_TYPE)_HAL_Driver/Inc
CUBE_INC += -I$(CUBE_DRIVER)/CMSIS/Device/ST/$(STM32_TYPE)/Include
CUBE_INC += -I$(CUBE_DRIVER)/CMSIS/Include

com_objs = objs/startup.o
src_objs = $(patsubst Src/%.c,objs/%.o,$(wildcard Src/*.c))

CFLAGS += -mcpu=cortex-m3 -mthumb -DSTM32F103xB
CFLAGS += $(CUBE_INC) -I./src
CFLAGS += -Os -O2 -g

BIN = gpio.bin

all: _mkdir gpio.elf

objs/startup.o : $(startup.s)
	$(PREFIX)gcc $(CFLAGS) -c -o $@ $<

gpio.elf : $(com_objs) $(src_objs) $(libhal)
	$(PREFIX)gcc $(CFLAGS) -T $(ld-script) -o $@ $^

$(libhal) : $(hal_objs)
	$(PREFIX)ar -r $@ $^

hal_objs/%.o : $(hal_src)/%.c
	$(PREFIX)gcc $(CFLAGS) -c -o $@ $<

objs/%.o : Src/%.c
	$(PREFIX)gcc $(CFLAGS) -c -o $@ $<

%.dump : %.elf
	$(PREFIX)objdump -D $< > $@

%.bin : %.elf
	$(PREFIX)objcopy -O binary $< $@

.PHONY: clean flash link
clean:
	rm -rf objs/ hal_objs/ *.elf *.bin *.dump
_mkdir:
	mkdir -p objs hal_objs

flash: $(BIN)
	$(ST_FLASH) write $(BIN) 0x8000000

link:   # to view source code
	ln -s $(STM32F1_CUBE)/Drivers/STM32F1xx_HAL_Driver HAL_Driver
	ln -s $(STM32F1_CUBE)/Drivers/CMSIS CMSIS

# start gdb server: st-util -m
# start gdb: arm-none-eabi-gdb gpio.elf
# connect:   (gdb) target ext localhost:4242

