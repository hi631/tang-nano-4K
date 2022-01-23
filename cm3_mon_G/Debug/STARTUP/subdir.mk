################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
S_UPPER_SRCS += \
../STARTUP/startup_gw1ns4c.S 

OBJS += \
./STARTUP/startup_gw1ns4c.o 

S_UPPER_DEPS += \
./STARTUP/startup_gw1ns4c.d 


# Each subdirectory must supply rules for building sources it contributes
STARTUP/%.o: ../STARTUP/%.S
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM GNU Assembler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -x assembler-with-cpp -D__STARTUP_CLEAR_BSS -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


