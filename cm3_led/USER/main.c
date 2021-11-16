
/*
 * *****************************************************************************************
 *
 * 		Copyright (C) 2014-2021 Gowin Semiconductor Technology Co.,Ltd.
 * 		
 * @file			main.c
 * @author		Embedded Development Team
 * @version		V1.x.x
 * @date			2021-01-01 09:00:00
 * @brief			Main program body.
 ******************************************************************************************
 */

/* Includes ------------------------------------------------------------------*/
#include "gw1ns4c.h"
//#include "GOWIN_M3.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/* Declarations ------------------------------------------------------------------*/
void delay_ms(__IO uint32_t delay_ms);
void GPIOInit(uint32_t pin);
void UartInit(void);

/* Functions ------------------------------------------------------------------*/
int main(void)
{
	uint32_t pin;
	char ch,kd;
	SystemInit();	//Initializes system
	pin = GPIO_Pin_3;
	GPIOInit(pin);	//Initializes GPIO
	UartInit();

	printf("\r\n----------------------------------\r\n");
	printf("       GowinSemiconductor\r\n");
	printf("----------------------------------\r\n");

  ch = 0x30;
  while(1)
  {
    GPIO_ResetBit(GPIO0,pin);	//LED on
	delay_ms(100);
		
    GPIO_SetBit(GPIO0,pin);		//LED off
	delay_ms(100);

	printf("%c",ch); fflush(stdout); ch++;
	if(ch>0x39) ch = 0x30;
	// PERIPHERAL\Sources\gw1ns4c_uart.c
	if(UART_GetRxBufferFull(UART0)){
		kd = UART_ReceiveChar(UART0);
		UART_SendChar(UART0,kd);
	}
  }
}

//Initializes GPIO
void GPIOInit(uint32_t pin)
{
	GPIO_InitTypeDef GPIO_InitType;
	
	GPIO_InitType.GPIO_Pin = pin;
	GPIO_InitType.GPIO_Mode = GPIO_Mode_OUT;
	GPIO_InitType.GPIO_Int = GPIO_Int_Disable;
	GPIO_Init(GPIO0,&GPIO_InitType);
  GPIO_SetBit(GPIO0,pin);
}

void UartInit(void)
{
  UART_InitTypeDef UART_InitStruct;

  UART_InitStruct.UART_Mode.UARTMode_Tx = ENABLE;
  UART_InitStruct.UART_Mode.UARTMode_Rx = ENABLE;
  UART_InitStruct.UART_Int.UARTInt_Tx = DISABLE;
  UART_InitStruct.UART_Int.UARTInt_Rx = DISABLE;
  UART_InitStruct.UART_Ovr.UARTOvr_Tx = DISABLE;
  UART_InitStruct.UART_Ovr.UARTOvr_Rx = DISABLE;
  UART_InitStruct.UART_Hstm = DISABLE;
  UART_InitStruct.UART_BaudRate = 115200*80/72;//Baud Rate
  UART_Init(UART0,&UART_InitStruct);
}

//delay ms
void delay_ms(__IO uint32_t delay_ms)
{
	//delay_ms = delay_ms ;
	for(delay_ms=(SystemCoreClock>>13)*delay_ms; delay_ms != 0; delay_ms--);
}
