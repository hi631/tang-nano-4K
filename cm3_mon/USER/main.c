
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
// アセンブラ　コンパイルできる記述例(実行性は未検証)
//　関数例　gcc用(Arm純正はエラー)
int add3_embasm(int i);
asm (
    "add3_embasm:\n\t"
    " add r0, #3\n\t"
    " bx lr\n\t"
);

void c2asm(void){
	__asm("nop");
	//　インライン Arm純正ツールチェーン用(レジスタ名は書けない)
	static int vb,i
	 __asm("add vb, i");
	//　インライン　gcc用
	asm( "add %[Rd1], %[Rs1] \n\t"	// 命令(add)テンプレート
	    : [Rd1] "=r" (vb)			// 変数(vb)をレジスタ(rd1)にヒモ付け
	    : [Rs1] "r" (i)
	    :							// 壊れるレジスタを記述
	);
}

#define getch getchuart
#define putch putchuart
#define gets  getsuart
#define puts  putsuart
void setsup(buf) char *buf;{
  while(*buf!=0x0d){
   if( *buf>='a' && *buf<='z') *buf = *buf - 0x20;
   buf++;
  }
}
char getchuart(void){ return UART_ReceiveChar(UART0); }
void putchuart(char ch){ UART_SendChar(UART0,ch);}
void puth(dt) int dt;{ if(dt<10) putch(0x30+dt); else putch(0x37+dt); }
void puth2(dt) int dt;{ puth((dt >> 4) & 0xf); puth(dt & 0xf); }
void puth4(dt) int dt;{ puth2((dt >> 8) & 0xff); puth2(dt & 0xff); }
void puth6(dt) long dt;{ int dh,dl; dh = dt >> 16; dl = dt & 0xffff; puth2(dh); puth4(dl); }
void puth8(dt) long dt;{ int dh,dl; dh = dt >> 16; dl = dt & 0xffff; puth4(dh); puth4(dl); }
void putsuart(char *buf){
	while(1){
		if(*buf==0) break;
		else        putch(*buf++);
	}
}
void getsuart(char *buf){
	char ch;
	while(1){
		ch = getch(); putch(ch); *buf++ = ch;
		if(ch==0x0d) break;
	}
}
int ishex(ch) char ch;{
  int hd;
  if(ch>='0' && ch<='9') hd = ch - 0x30;
  else if(ch>='A' && ch<='F') hd = ch - 0x37;
  else hd = -1;
  return hd;
}
void getssu(cbuf) char *cbuf;{ gets(cbuf); setsup(cbuf);}
void putadrhd(adr) long adr;{putch('\n'); puth8(adr); putch(':');}

long gets2h(buf) char **buf;{
  long num = 0; int hd;
  if(**buf==0x0d) return -1;
  while(**buf==' ') (*buf)++; /* spip sp*/
  while( (hd=ishex(**buf)) != -1){ num = num * 16 + hd; (*buf)++; }
  return num;
}

int main(void){
	unsigned char *mbase;
	  long adr,ade,adro,dt,dtr,wk,sct,scr,sl;
	  long i,j,mmd,rno;
	  unsigned int * cmp, *wrp, *sbp;
	  char cmd, cbuf[32], *cbp, **cbpp;

		uint32_t pin;
		char ch,kd;
		SystemInit();	//Initializes system
		pin = GPIO_Pin_3;
		GPIOInit(pin);	//Initializes GPIO
		UartInit();

		mbase = 0;
		cbpp = &cbp; adro = 0;
	  puts("\nMon_TN4K");
	  while(1){
		  puts("\n>"); getssu(cbuf);
		  cmd = cbuf[0]; cbp = &cbuf[1];
		  switch(cmd){
	      case 'D':
	        adr = gets2h(cbpp);
	        if(adr==-1) adr = adro;
	        for(i=0; i<8; i++){
	          putadrhd(adr);
	          for(j=0; j<16; j++) { putch(' '); puth2(mbase[adr++]); }
	        }
	        adro = adr;
	        break;
	      case 'M':
	        mmd = 1;
	        if(*cbp=='W'){ mmd = 2; cbp++; }
	        adr = gets2h(cbpp);
	        while(cmd!='.'){
	          putadrhd(adr);
	          putch(' '); puth2(mbase[adr]); if(mmd==2) puth2(mbase[adr+1]);
	          putch(' ');
	          getssu(cbuf); cbp = &cbuf[0];
	          dt = gets2h(cbpp); cmd = *cbp;
	          if(cmd==0x0d && dt>=0){
	            if(mmd==1){
	              if(dt>=0) {
	                mbase[adr] = dt; dtr = mbase[adr];
	                if(dt!=dtr) adr--;
	              }
	            } else {
	              wrp = (unsigned int *)&mbase[adr];
	              if(dt>=0) {
	                *wrp = dt; dtr = *wrp;
	                if(dt!=dtr) wrp--;
	              }
	              adr = (long)wrp;
	            }
	          }
	          if(cmd=='-') adr = adr - mmd;
	          else         adr = adr + mmd;
	        }
	        break;
	      default: puts("??\n");

		  }
	  }
	  return 0;

}
