
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
#include "gw1ns4c_uart.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
/* Declarations ------------------------------------------------------------------*/
void delay_ms(__IO uint32_t delay_ms);
void GPIOInit(uint32_t pin);
void UartInit(void);
//
void get_vram(int adry, int adrx);
void set_vram(int adry, int adrx);
void set_char(int adry, int adrx, int ptn, int ccd);
void set_vramm(int adry, int adrx, int ptn, int mask, int loopy, int loopx);
void dispfull(int adry, int adrx, int ptn, int ccd, int len);
void move_vram(int sadr, int dadr, int dlen, int mode);
void dispscroll(int adry, int adrx);
int  disp_vram(char chd);
void pset(int xp, int yp, int ptn);
int pget(int xp, int yp);
void basic();

#define u16 unsigned short
void DLine(u16 x1, u16 y1, u16 x2, u16 y2, u16 ptn);
void DCircle(u16 x0,u16 y0,u16 r,u16 ptn);
void DPaint(int xp, int yp, int ptn);

extern union wddt_t {
	unsigned char b[37];
	short         s[18];
	unsigned int  i[9];
} wddt;
//extern wddt_t wddt;
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

//Initializes SPI
void SPIInit(void)
{
	SPI_InitTypeDef init_spi;
  init_spi.CLKSEL= CLKSEL_CLK_DIV_4;		//80MHZ / 8
  init_spi.DIRECTION = DISABLE;					//MSB First
  init_spi.PHASE =DISABLE;							//ENABLE;//posedge
  init_spi.POLARITY =DISABLE;						//polarity 0
  SPI_Init(&init_spi);
}
//delay ms
void delay_ms(__IO uint32_t delay_ms) {
	for(delay_ms=(SystemCoreClock>>13)*delay_ms; delay_ms != 0; delay_ms--);
}

int mdgpio, mdgpioi;
void check_gpio(){
	int i;
	mdgpio = GPIO_ReadBits(GPIO0);	// ukey2 = bit13
	mdgpioi = mdgpio; mdgpio = mdgpio & 0xdfff;		// bit13.clear
	for(i=0;i<2;i++){
		GPIO_WriteBits(GPIO0,0x03); delay_ms(50);
		GPIO_WriteBits(GPIO0,0x00); delay_ms(50);
	}
}

#define getch getch_uart
#define putch putch_uart
#define gets  getsuart
#define puts  putsuart
void setsup(buf) char *buf;{
  while(*buf!=0x0d){
   if( *buf>='a' && *buf<='z') *buf = *buf - 0x20;
   buf++;
  }
}
char kinbuf[256];
int kinbwp =0, kinbrp = 0;
void key_check() {
	char ch;
	//
	ch = SPI_ReadData();
	if(ch!=0) kinbuf[kinbwp++] = ch;
	if(kinbwp>=256) kinbwp = 0;
	//
	if((UART0->STATE & UART_STATE_RXBF)) kinbuf[kinbwp++] = UART0->DATA;
	if(kinbwp>=256) kinbwp = 0;
	//
}
char getch_uart(void){
	char dt;
	while(kinbrp==kinbwp) key_check();
	dt = kinbuf[kinbrp++];
	if(kinbrp>=256) kinbrp = 0;
	return dt;
}
void putch_uart(char ch){
	volatile uint32_t gpiord;
	if((mdgpio & 0x2000)==0)
		UART_SendChar(UART0,ch);
	else {
		gpiord = 0x4000;
		while((gpiord & 0x4000)!=0) {
			key_check();
			gpiord = GPIO_ReadBits(GPIO0);
		}
		SPI_WriteData(ch);
	}
	//
	int rc;	do{ key_check(); rc = disp_vram(ch); } while(rc!=0);	// VRam Display
}

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
void putadrhd(adr) long adr;{puts("\r\n"); puth8(adr); putch(':');}

long getsh(buf) char **buf;{
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

		char ch,kd;
		SystemInit();	//Initializes system
		UartInit();
		SPIInit();		//Initializes SPI
		check_gpio();

		cbpp = &cbp; adro = 0; mbase = 0;
	  puts("\r\nMon_TN4K");
	  while(1){
		  puts("\r\n>"); getssu(cbuf);
		  cmd = cbuf[0]; cbp = &cbuf[1];
		  switch(cmd){
		  case 'B': puts("\r\n>"); basic();
			  break;
		  case 'D':
	        adr = getsh(cbpp);
	        if(adr==-1) adr = adro;
	        for(i=0; i<8; i++){
	          putadrhd(adr);
	          for(j=0; j<16; j++) { putch(' '); puth2(mbase[adr++]); }
	        }
	        adro = adr;
	        break;
	      case 'W':
	    	if(*cbp=='S'){
	    		cbp++; dt = 0;
	    		while(dt!=-1){
	    			dt = getsh(cbpp); if(dt!=-1) SPI_WriteData(dt);
	    		}
	    	}
	    	if(*cbp=='D'){
	    		cbp++; set_vramm((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp), (int)getsh(cbpp), (int)getsh(cbpp), (int)getsh(cbpp));
	    	}
			if(*cbp=='C') {
				cbp++; dispfull((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp));}
			if(*cbp=='F') {
				cbp++; move_vram((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp), 10); }
			if(*cbp=='L'){
				cbp++; DLine((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp) ); }
			if(*cbp=='M'){
				cbp++; move_vram((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp), 12); }
			if(*cbp=='P'){
				cbp++; pset((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp)); }
			if(*cbp=='Q'){
				cbp++; DPaint((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp)); }
			if(*cbp=='R'){
				cbp++; DCircle((int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp),(int)getsh(cbpp)); }
			if(*cbp=='U'){
				cbp++; dispscroll((int)getsh(cbpp),(int)getsh(cbpp)); }
			if(*cbp=='G'){
				cbp++; dt = getsh(cbpp); GPIO_WriteBits(GPIO0,dt); }
	    	break;
	      case 'R':
	    	if(*cbp=='S'){
	    		dt = -1;
	    		while(dt!=0){
	    			dt = SPI_ReadData(); puth2(dt); putch(' ');
	    		}
	    	}
	    	if(*cbp=='D'){
	    		unsigned char wddtwk[32];
	    		cbp++;
	    		get_vram((int)getsh(cbpp), (int)getsh(cbpp));
	    		memcpy(&wddtwk[0], &wddt.b[4], 32);
	    		for(j=0; j<32; j++) { putch(' '); puth2(wddtwk[j]); }
	    	}
	    	if(*cbp=='P'){
	    		cbp++; dt = pget((int)getsh(cbpp),(int)getsh(cbpp)); puth4(dt); }
	    	if(*cbp=='G'){ dt = GPIO_ReadBits(GPIO0); puth4(dt); }
	        break;
	      case 'M':
	        mmd = 1;
	        if(*cbp=='W'){ mmd = 2; cbp++; }
	        adr = getsh(cbpp);
	        while(cmd!='.'){
	          putadrhd(adr);
	          putch(' '); puth2(mbase[adr]); if(mmd==2) puth2(mbase[adr+1]);
	          putch(' ');
	          getssu(cbuf); cbp = &cbuf[0];
	          dt = getsh(cbpp); cmd = *cbp;
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
	      default: puts("??");

		  }
	  }
	  return 0;

}
