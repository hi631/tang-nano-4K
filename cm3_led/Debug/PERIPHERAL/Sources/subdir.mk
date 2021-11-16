################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../PERIPHERAL/Sources/gw1ns4c_gpio.c \
../PERIPHERAL/Sources/gw1ns4c_i2c.c \
../PERIPHERAL/Sources/gw1ns4c_misc.c \
../PERIPHERAL/Sources/gw1ns4c_rtc.c \
../PERIPHERAL/Sources/gw1ns4c_spi.c \
../PERIPHERAL/Sources/gw1ns4c_syscon.c \
../PERIPHERAL/Sources/gw1ns4c_timer.c \
../PERIPHERAL/Sources/gw1ns4c_uart.c \
../PERIPHERAL/Sources/gw1ns4c_wdog.c 

OBJS += \
./PERIPHERAL/Sources/gw1ns4c_gpio.o \
./PERIPHERAL/Sources/gw1ns4c_i2c.o \
./PERIPHERAL/Sources/gw1ns4c_misc.o \
./PERIPHERAL/Sources/gw1ns4c_rtc.o \
./PERIPHERAL/Sources/gw1ns4c_spi.o \
./PERIPHERAL/Sources/gw1ns4c_syscon.o \
./PERIPHERAL/Sources/gw1ns4c_timer.o \
./PERIPHERAL/Sources/gw1ns4c_uart.o \
./PERIPHERAL/Sources/gw1ns4c_wdog.o 

C_DEPS += \
./PERIPHERAL/Sources/gw1ns4c_gpio.d \
./PERIPHERAL/Sources/gw1ns4c_i2c.d \
./PERIPHERAL/Sources/gw1ns4c_misc.d \
./PERIPHERAL/Sources/gw1ns4c_rtc.d \
./PERIPHERAL/Sources/gw1ns4c_spi.d \
./PERIPHERAL/Sources/gw1ns4c_syscon.d \
./PERIPHERAL/Sources/gw1ns4c_timer.d \
./PERIPHERAL/Sources/gw1ns4c_uart.d \
./PERIPHERAL/Sources/gw1ns4c_wdog.d 


# Each subdirectory must supply rules for building sources it contributes
PERIPHERAL/Sources/%.o: ../PERIPHERAL/Sources/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: Cross ARM C Compiler'
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -O3 -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections  -g3 -I"C:\kitaprg\GMD_RefDesign\cm3_led\CORE" -I"C:\kitaprg\GMD_RefDesign\cm3_led\PERIPHERAL\Includes" -I"C:\kitaprg\GMD_RefDesign\cm3_led\SYSTEM" -I"C:\kitaprg\GMD_RefDesign\cm3_led\USER" -std=gnu11 -MMD -MP -MF"$(@:%.o=%.d)" -MT"$(@)" -c -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


