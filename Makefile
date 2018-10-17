# Target File
TARGET = test

# Include Libraries:
prefix = C:/STM32L1xx_StdPeriph_Lib_V1.3.1

LIB_CMSIS_PRE = $(prefix)/Libraries/CMSIS
LIB_CMSIS_INC = $(LIB_CMSIS_PRE)/Include/

LIB_CMSIS_DEV_PRE = $(LIB_CMSIS_PRE)/Device/ST/STM32L1xx
LIB_CMSIS_DEV_INC = $(LIB_CMSIS_DEV_PRE)/Include/
LIB_CMSIS_DEV_SRC = $(LIB_CMSIS_DEV_PRE)/Source/Templates/

LIB_PERIPHERALS_PRE = $(prefix)/Libraries/STM32L1xx_StdPeriph_Driver
LIB_PERIPHERALS_INC = $(LIB_PERIPHERALS_PRE)/inc/
LIB_PERIPHERALS_SRC = $(LIB_PERIPHERALS_PRE)/src/

PROJECT_INCLUDE = C:/ARMProgTest/inc/

#LIBEVAL = $(prefix)/Utilities/STM32_EVAL/STM32L152_EVAL/
#LIBEVALCOMM = $(prefix)/Utilities/STM32_EVAL/Common/
#LIBNUCLEO = C:/LoRa_Bug/ARM_code_test/STM32L1/STM32L1xx/bsp/STM32L152_Nucleo/

# Compiler commands
CC = arm-none-eabi-gcc
CP = arm-none-eabi-objcopy
LD = arm-none-eabi-ld
AR = arm-none-eabi-ar

# Select microcontroller
CPU = cortex-m3
ARCH = armv7-m

# Paths to files
INCLUDE_PATH = ./inc
SOURCE_PATH = ./src
STARTUP_FILE_PATH = ./tools
ARCHIVE_PATH = ./archive
OBJ_PATH = ./obj
BUILD_PATH = ./bld
UPLOAD_PATH = /cygdrive/d

# Make Rule Constants

compile := $(BUILD_PATH)/$(TARGET).o

peripheral_src := $(wildcard $(LIB_PERIPHERALS_SRC)*.c)
peripheral_obj := $(patsubst $(LIB_PERIPHERALS_SRC)%.c,$(OBJ_PATH)/%.o,$(peripheral_src))

assemble-startup := $(OBJ_PATH)/startup_stm32l1xx_md.o
assemble-nucleo := $(OBJ_PATH)/stm32l1xx_nucleo.o
assemble-device := $(OBJ_PATH)/system_stm32l1xx.o
assemble-it-file := $(OBJ_PATH)/stm32l1xx_it.o

build-library := $(ARCHIVE_PATH)/libperipherals.a

link := $(BUILD_PATH)/$(TARGET).elf
binary := $(BUILD_PATH)/$(TARGET).bin

# Compiler flags
CFLAGS = -std=gnu99 -g -O2 -Wall -mthumb -mcpu=$(CPU) -march=$(ARCH) --specs=nosys.specs
LFLAGS = -nostartfiles -Xlinker --output=$(BUILD_PATH)/$(TARGET).elf -Xlinker --script=$(STARTUP_FILE_PATH)/stm32_flash.ld -Xlinker -n -nostdlib -nodefaultlibs -fno-exceptions 

LIB_INCLUDES = -I'$(LIB_CMSIS_DEV_INC)' -I'$(LIB_CMSIS_INC)' -I'$(LIB_PERIPHERALS_INC)' 
LIB_INCLUDES_EXT = -I'$(PROJECT_INCLUDE)'
LIB_LINKS = -L'$(ARCHIVE_PATH)' -L'$(BUILD_PATH)' -L'$(OBJ_PATH)'

# Preprocessor Symbols
PRE_DEVICE = -D STM32L1XX_MD
PRE_DRIVER = -D USE_STDPERIPH_DRIVER

# Make Rules

all: $(assemble-device) $(assemble-it-file) $(peripheral_obj) $(assemble-startup) $(assemble-nucleo) $(build-library) $(compile) $(link) $(binary)

# upload
upload: $(BUILD_PATH)/$(TARGET).bin
	cp $< $(UPLOAD_PATH)/$(<F)

# build library
$(ARCHIVE_PATH)/libperipherals.a: $(peripheral_obj)
	$(AR) rcs $@ $^

# link
$(BUILD_PATH)/$(TARGET).elf: $(BUILD_PATH)/$(TARGET).o $(assemble-startup) $(assemble-nucleo) $(build-library) $(assemble-device)
	$(CC) $(CFLAGS) $(LFLAGS) $(LIB_LINKS) -lc 

# binary
$(BUILD_PATH)/$(TARGET).bin: $(BUILD_PATH)/$(TARGET).elf
	$(CP) -O binary $< $@

# compile
$(BUILD_PATH)/$(TARGET).o: $(SOURCE_PATH)/$(TARGET).c $(SOURCE_PATH)/$(TARGET).h 
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c $< -o $@

# assemble-startup
$(OBJ_PATH)/startup_stm32l1xx_md.o: $(STARTUP_FILE_PATH)/startup_stm32l1xx_md.s
	$(CC) $(CFLAGS) -c -o $@ $<

# assemble-nucleo
$(OBJ_PATH)/stm32l1xx_nucleo.o: $(INCLUDE_PATH)/stm32l1xx_nucleo.c $(INCLUDE_PATH)/stm32l1xx_nucleo.h
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DEVICE) $(PRE_DRIVER) -c -o $@ $<

# peripheral_obj
$(OBJ_PATH)/%.o: $(LIB_PERIPHERALS_SRC)%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c -o $@ $<

# assemble-it-file
$(OBJ_PATH)/stm32l1xx_it.o: $(INCLUDE_PATH)/stm32l1xx_it.c $(INCLUDE_PATH)/stm32l1xx_it.h
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c -o $@ $<


# assemble-device
$(OBJ_PATH)/system_stm32l1xx.o: $(LIB_CMSIS_DEV_SRC)system_stm32l1xx.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c -o $@ $<


clean:
	rm -f $(BUILD_PATH)/$(TARGET).* 

clean-all: 
	rm -f $(peripheral_obj) $(assemble-device) $(assemble-startup) $(assemble-nucleo) $(build-library) $(BUILD_PATH)/$(TARGET).*

clean-peripherals:
	rm -f $(peripheral_obj)

clean-all-objects:
	rm -f $(OBJ_PATH)/*.o

clean-ar:
	rm -f $(ARCHIVE_PATH)/*.a