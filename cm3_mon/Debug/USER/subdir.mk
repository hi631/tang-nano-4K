################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../USER/gw1ns4c_it.c \
../USER/main.c \
../USER/retarget.c 

OBJS += \
./USER/gw1ns4c_it.o \
./USER/main.o \
./USER/retarget.o 

C_DEPS += \
./USER/gw1ns4c_it.d \
./USER/main.d \
./USER/retarget.d 


# Each subdirectory must supply rules for building sources it contributes
USER/%.o: ../USER/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -I"C:\kitaprg\GMD_RefDesign\cm3_mon\CORE" -I"C:\kitaprg\GMD_RefDesign\cm3_mon\PERIPHERAL\Includes" -I"C:\kitaprg\GMD_RefDesign\cm3_mon\SYSTEM" -I"C:\kitaprg\GMD_RefDesign\cm3_mon\USER" -std=gnu11 -Wa,-adhlns="$@.lst" -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


