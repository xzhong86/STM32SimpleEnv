
PREFIX = $(HOME)/local/bin/arm-none-eabi-

STM32F1_CUBE = $(HOME)/work/geek/stm32/stm32cube/STM32Cube_FW_F1_V1.8.0

ST_FLASH = $(HOME)/local/bin/st-flash

#startup.s = $(STM32F1_CUBE)/Projects/STM32F103RB-Nucleo/Templates/SW4STM32/startup_stm32f103xb.s
#ld-script = $(STM32F1_CUBE)/Projects/STM32F103RB-Nucleo/Templates/SW4STM32/STM32F103RB_Nucleo/STM32F103VBIx_FLASH.ld
startup.s = startup_stm32f103xb.s
ld-script = STM32F103VBIx_FLASH.ld

com_objs = objs/startup.o
src_objs = $(patsubst Src/%.c,objs/%.o,$(wildcard Src/*.c))

hal_src   = $(STM32F1_CUBE)/Drivers/STM32F1xx_HAL_Driver/Src
hal_objs  = $(patsubst $(hal_src)/%.c,hal_objs/%.o,$(wildcard $(hal_src)/*.c))
hal_objs := $(filter-out %template.o, $(hal_objs))

CFLAGS += -mcpu=cortex-m3 -mthumb -DSTM32F103xB
CFLAGS += -I$(STM32F1_CUBE)/Drivers/STM32F1xx_HAL_Driver/Inc
CFLAGS += -I$(STM32F1_CUBE)/Drivers/CMSIS/Device/ST/STM32F1xx/Include
CFLAGS += -I$(STM32F1_CUBE)/Drivers/CMSIS/Include/
CFLAGS += -IInc
CFLAGS += -Os -O2 -g

BIN = gpio.bin
libhal = objs/libhal.a

all: gpio.elf

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
	rm -f objs/* hal_objs/* *.elf *.bin *.dump

flash: $(BIN)
	$(ST_FLASH) write $(BIN) 0x8000000

link:
	ln -s $(STM32F1_CUBE)/Drivers/STM32F1xx_HAL_Driver HAL_Driver
	ln -s $(STM32F1_CUBE)/Drivers/CMSIS CMSIS

# start gdb server: st-util -m
# start gdb: arm-none-eabi-gdb gpio.elf
# connect:   (gdb) target ext localhost:4242

