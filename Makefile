###### GD32V Makefile ######

######################################
# Target
######################################
# .elf, .bin, .hex等目标文件的名称
TARGET = GD32VF103


######################################
# Source
######################################
# C sources
C_SOURCES =  \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral/Source/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/drivers/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/*.c) \
$(wildcard GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/stubs/*.c) \

# add your c source here
C_SOURCES += \
$(wildcard ./*.c) \

# ASM sources
ASM_SOURCES =  \
GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/start.s \
GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/entry.s \


######################################
# Includes
######################################
# C includes
C_INCLUDES =  \
-I GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral/Include \
-I GD32VF103_Firmware_Library_V1.1.0/Firmware/GD32VF103_standard_peripheral \
-I GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/drivers \
-I GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/stubs \

# add your includes here
C_INCLUDES += \
-I . \

# AS includes
AS_INCLUDES = 


######################################
# Building variables
######################################
# debug build?
DEBUG = 1
# optimization
OPT = -Og

# Build path
BUILD_DIR = build


######################################
# Defines
######################################
# macros for gcc
# C defines
C_DEFS =  \
-D USE_STDPERIPH_DRIVER \
-D HXTAL_VALUE=8000000U \

# AS defines
AS_DEFS = 


######################################
# Firmware library
######################################
PERIFLIB_SOURCES = \
# $(wildcard Lib/*.a)


#######################################
# Linker
#######################################
# link script
LDSCRIPT = GD32VF103_Firmware_Library_V1.1.0/Firmware/RISCV/env_Eclipse/GD32VF103xB.lds


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
# architecture
ARCH = -march=rv32imac -mabi=ilp32 -mcmodel=medlow

# compile gcc flags
ASFLAGS = $(ARCH) $(AS_DEFS) $(AS_INCLUDES) $(OPT) -Wl,-Bstatic#, -ffreestanding -nostdlib

CFLAGS = $(ARCH) $(C_DEFS) $(C_INCLUDES) $(OPT) -Wl,-Bstatic#, -ffreestanding -nostdlib

# 如果DEBUG等于1, 则添加调试相关的参数
ifeq ($(DEBUG), 1)
CFLAGS += -g -gdwarf-2
endif

# 以下CFLAG会让GCC在编译自动推导依赖关系, 并生成与目标文件(.o)对应的依赖关系(.d)文件
# 因为头文件(.h)包含关系太复杂了, 如果手动更新到Makefile不但麻烦且容易出错
# 所以GCC/Clang等提供了相应的选项, 由编译器推导出依赖关系

# 依赖关系文件(.d)文件也是Makefile格式, 可以直接用在Makefile中
# 在此Makefile最后, 使用了include指令将所有.d文件包含进此Makefile

# -M: 输出一个用于Makefile的规则, 此规则描述了该源文件的依赖关系
#     即将源文件包含的所有的头文件做为依赖项
#     而规则的目标名称为与源文件名称相同的目标文件
#     比如对于 foobar.c , 则生成规则的目标名称为 foobar.o

# -MM: 与 -M 相同, 但不包括系统标准头文件

# -MMD: 将依赖关系写到.d文件中, 文件名为与源文件名相同的目标文件
#       比如源文件名为 foobar.c , 则生成 foobar.d 文件.

# -MF "file": 指定生成依赖关系文件的名称

# -MP: 给每个依赖的头文件生成一条内容为空的规则
#      这些空规则可以防止头文件被删除后因找不到头文件面报错退出

# -MT "target": 更改输出规则的目标名称
#      比如输出的规则如下:
#      foobar.o: foo.h bar.h
#      使用 -MT 参数更改的就是 foobar.o 这个名称

# 在此Makefile中, 不需要使用-MT 参数

# Generate dependency information
CFLAGS += -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" #-MT"$(@:%.o=%.d)"

# Generation a separate ELF section for each function and variable in the source file
# Cooperate -Wl,--gc-sections option to eliminating the unused code and data
# from the final executable
CFLAGS += -ffunction-sections -fdata-sections

# libraries
LIBS = -lc_nano -lm
LIBDIR = 
LDFLAGS = $(ARCH) -T$(LDSCRIPT) $(LIBDIR) $(LIBS) $(PERIFLIB_SOURCES) -Wl,--no-relax -Wl,--gc-sections -Wl,-Map,$(BUILD_DIR)/$(TARGET).map -nostartfiles #-ffreestanding -nostdlib

# 默认动作, 生成.elf, .hex, .bin
all: $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).hex $(BUILD_DIR)/$(TARGET).bin


#######################################
# Build the application
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
# Clean up
#######################################
clean:
	-rm -fR $(BUILD_DIR)


#######################################
# Program
#######################################
flash: all
	$()openocd -c "adapter driver cmsis-dap; adapter speed 5000; transport select jtag" -f target/gd32vf103.cfg -c "program $(BUILD_DIR)/$(TARGET).elf" -c "reset; exit"

debug: all
	$()openocd -c "adapter driver cmsis-dap; adapter speed 5000; transport select jtag" -f target/gd32vf103.cfg 

dfu: all
	$()dfu-util -a 0 -s 0x08000000:leave -D $(BUILD_DIR)/$(TARGET).bin

#######################################
# dependencies
#######################################
# 没弄明白意思, 因为生成的.d依赖文件并未保存到.dep目录中
# $(shell mkdir .dep 2>/dev/null) 的意思是
# mkdir .dep, 如果出错, 将出错信息输入到 /dev/null 中, 即不显示出错信息
#
# 在shell脚本中, 默认总有3个文件处于打开状态, 分别是
# stdin, 文件描述符: 0
# stdout, 文件描述符: 1
# stderr, 文件描述符: 2
# mkdir .dep 2>/dev/null 中 2 的意思是 stderr
# 2>$1 的意思是将 stderr 重定向到 stdout
# -include $(shell mkdir .dep 2>/dev/null) $(wildcard .dep/*)

-include $(wildcard $(BUILD_DIR)/*.d)

# *** EOF ***
