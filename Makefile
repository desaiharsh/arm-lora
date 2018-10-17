# Target File
TARGET = main

# Include Libraries:
prefix = ./ext/libarm/STM32L1xx_StdPeriph_Lib_V1.3.1

LIB_CMSIS_PRE = $(prefix)/Libraries/CMSIS
LIB_CMSIS_INC = $(LIB_CMSIS_PRE)/Include/

LIB_CMSIS_DEV_PRE = $(LIB_CMSIS_PRE)/Device/ST/STM32L1xx
LIB_CMSIS_DEV_INC = $(LIB_CMSIS_DEV_PRE)/Include/
LIB_CMSIS_DEV_SRC = $(LIB_CMSIS_DEV_PRE)/Source/Templates

LIB_PERIPHERALS_PRE = $(prefix)/Libraries/STM32L1xx_StdPeriph_Driver
LIB_PERIPHERALS_INC = $(LIB_PERIPHERALS_PRE)/inc/
LIB_PERIPHERALS_SRC = $(LIB_PERIPHERALS_PRE)/src/

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

assemble-startup := $(OBJ_PATH)/startup_stm32l1xx_xl.o
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
LIB_INCLUDES_EXT = -I'$(INCLUDE_PATH)'
LIB_LINKS = -L'$(ARCHIVE_PATH)' -L'$(BUILD_PATH)' -L'$(OBJ_PATH)'

# Preprocessor Symbols
PRE_DEVICE = -D STM32L1XX_XL
PRE_DRIVER = -D USE_STDPERIPH_DRIVER

# Make Rules

all: $(assemble-device) $(assemble-it-file) $(peripheral_obj) $(assemble-startup) $(assemble-nucleo) $(build-library) $(compile) $(link) $(binary)

# upload for windows
upload-win: $(BUILD_PATH)/$(TARGET).bin
	cp $< $(UPLOAD_PATH)/$(<F)

# build library
$(build-library): $(peripheral_obj)
	$(AR) rcs $@ $^

# link
$(link): $(BUILD_PATH)/$(TARGET).o $(assemble-startup) $(assemble-nucleo) $(assemble-it-file) $(build-library) $(assemble-device)
	$(CC) $(CFLAGS) $(LFLAGS) $(LIB_LINKS) -lc $^

# binary
$(binary): $(BUILD_PATH)/$(TARGET).elf
	$(CP) -O binary $< $@

# compile
$(compile): $(SOURCE_PATH)/$(TARGET).c $(INCLUDE_PATH)/$(TARGET).h 
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c $< -o $@

# assemble-startup
$(assemble-startup): $(patsubst $(OBJ_PATH)%.o, $(STARTUP_FILE_PATH)%.s, $(assemble-startup))
	$(CC) $(CFLAGS) -c -o $@ $<

# assemble-nucleo
$(assemble-nucleo): $(patsubst $(OBJ_PATH)%.o, $(INCLUDE_PATH)%.c, $(assemble-nucleo))  $(patsubst $(OBJ_PATH)%.o, $(INCLUDE_PATH)%.h, $(assemble-nucleo))
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DEVICE) $(PRE_DRIVER) -c -o $@ $<

# peripheral_obj
$(OBJ_PATH)/%.o: $(LIB_PERIPHERALS_SRC)%.c
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c -o $@ $<

# assemble-it-file
$(assemble-it-file):  $(patsubst $(OBJ_PATH)%.o, $(INCLUDE_PATH)%.c, $(assemble-it-file))  $(patsubst $(OBJ_PATH)%.o, $(INCLUDE_PATH)%.h, $(assemble-it-file))
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c -o $@ $<


# assemble-device
$(assemble-device): $(patsubst $(OBJ_PATH)%.o, $(LIB_CMSIS_DEV_SRC)%.c, $(assemble-device))
	$(CC) $(CFLAGS) $(LIB_INCLUDES) $(LIB_INCLUDES_EXT) $(PRE_DRIVER) $(PRE_DEVICE) -c -o $@ $<

clean:
	rm -f $(BUILD_PATH)/$(TARGET).* 

clean-all: 
	rm -f $(peripheral_obj) $(assemble-device) $(assemble-startup) $(assemble-nucleo) $(assemble-it-file) $(build-library) $(BUILD_PATH)/$(TARGET).*

clean-peripherals:
	rm -f $(peripheral_obj)

clean-all-objects:
	rm -f $(OBJ_PATH)/*.o

clean-ar:
	rm -f $(ARCHIVE_PATH)/*.a

clean-locals:
	rm -f $(assemble-device) $(assemble-it-file) $(assemble-nucleo) $(assemble-startup)
