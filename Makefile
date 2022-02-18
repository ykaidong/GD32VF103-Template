###### GD32V Makefile ######


######################################
# target
######################################
TARGET = GD32VF103


######################################
# building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -Og

# Build path
BUILD_DIR = build

######################################
# source
######################################
# C sources
C_SOURCES =  \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral/Source/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/drivers/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/stubs/*.c) \
$(wildcard ./*.c) \
# $(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_usbfs_driver/Source/*.c) \

# ASM sources
ASM_SOURCES =  \
GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/start.s \
GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/entry.s \

######################################
# firmware library
######################################
PERIFLIB_SOURCES = \
# $(wildcard Lib/*.a)

#######################################
# binaries
#######################################

PREFIX = riscv32-unknown-elf-
CC = $(PREFIX)gcc
AS = $(PREFIX)gcc -x assembler-with-cpp
CP = $(PREFIX)objcopy
AR = $(PREFIX)ar
SZ = $(PREFIX)size
OD = $(PREFIX)objdump
HEX = $(CP) -O ihex
BIN = $(CP) -O binary -S
 
#######################################
# CFLAGS
#######################################
# cpu
ARCH = -march=rv32imac -mabi=ilp32 -mcmodel=medlow

# macros for gcc
# AS defines
AS_DEFS = 

# C defines
C_DEFS =  \
-DUSE_STDPERIPH_DRIVER \
-DHXTAL_VALUE=8000000U \

# AS includes
AS_INCLUDES = 

# C includes
C_INCLUDES =  \
-IGD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral/Include \
-IGD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral \
-IGD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/drivers \
-IGD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/stubs \
-I. \
# -IGD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_usbfs_driver/Include \

# compile gcc flags
ASFLAGS = $(ARCH) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wl,-Bstatic#, -ffreestanding -nostdlib

CFLAGS = $(ARCH) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wl,-Bstatic#, -ffreestanding -nostdlib

ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif

# Generate dependency information
CFLAGS += -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@:%.o=%.d)"

# Generation a separate ELF section for each function and variable in the source file
# Cooperate -Wl,--gc-sections option to eliminating the unused code and data
# from the final executable
CFLAGS += -ffunction-sections -fdata-sections

#######################################
# LDFLAGS
#######################################
# link script
LDSCRIPT = GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/GD32VF103xB.lds

# libraries
LIBS = -lc_nano -lm
LIBDIR = 
LDFLAGS = $(ARCH) -T$(LDSCRIPT) $(LIBDIR) $(LIBS) $(PERIFLIB_SOURCES) -Wl,--no-relax -Wl,--gc-sections -Wl,-Map,$(BUILD_DIR)/$(TARGET).map -nostartfiles #-ffreestanding -nostdlib

# default action: build all
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin

#######################################
# build the application
#######################################
# list of objects
OBJECTS = $(addprefix $(BUILD_DIR)/,$(notdir $(C_SOURCES:.c=.o)))
vpath %.c $(sort $(dir $(C_SOURCES)))
# list of ASM program objects
OBJECTS += $(addprefix $(BUILD_DIR)/,$(notdir $(ASM_SOURCES:.s=.o)))
vpath %.s $(sort $(dir $(ASM_SOURCES)))

$(BUILD_DIR)/%.o: %.c Makefile | $(BUILD_DIR) 
	@echo "CC $<"
	@$(CC) -c $(CFLAGS) -Wa,-a,-ad,-alms=$(BUILD_DIR)/$(notdir $(<:.c=.lst)) $< -o $@

$(BUILD_DIR)/%.o: %.s Makefile | $(BUILD_DIR)
	@echo "AS $<"
	@$(AS) -c $(CFLAGS) $< -o $@

$(BUILD_DIR)/$(TARGET).elf: $(OBJECTS) Makefile
	@echo "LD $@"
	@$(CC) $(OBJECTS) $(LDFLAGS) -o $@
	@echo "OD $@"
	@$(OD) $(BUILD_DIR)/$(TARGET).elf -xS > $(BUILD_DIR)/$(TARGET).s $@
	@echo "SZ $@"
	@$(SZ) $@

$(BUILD_DIR)/%.hex: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(HEX) $< $@
	
$(BUILD_DIR)/%.bin: $(BUILD_DIR)/%.elf | $(BUILD_DIR)
	$(BIN) $< $@	
	
$(BUILD_DIR):
	mkdir $@

#######################################
# clean up
#######################################

clean:
	-rm -fR .dep $(BUILD_DIR)

flash: all
	$()openocd -c "adapter driver cmsis-dap; adapter speed 5000; transport select jtag" -f ./gd32vf103.cfg -c "program $(BUILD_DIR)/$(TARGET).elf" -c "reset; exit"

debug: all
	$()openocd -c "adapter driver cmsis-dap; adapter speed 5000; transport select jtag" -f ./gd32vf103.cfg 

dfu: all
	$()dfu-util -a 0 -s 0x08000000:leave -D $(BUILD_DIR)/$(TARGET).bin

#######################################
# dependencies
#######################################
# -include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)

# *** EOF ***
