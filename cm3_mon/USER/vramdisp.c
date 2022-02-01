#include "gw1ns4c.h"
const unsigned char FONT_8x8[];

extern void putchuart();
extern void puth2();

volatile unsigned char pd;
short aryex[512];
//unsigned char wddt[37];
union wddt_t {
	unsigned char b[37];
	short         s[18];
	unsigned int  i[9];
} wddt;
#define u16 unsigned short

void set_vramadr(int adry, int adrx){
	int adr;
	adr = ((adry)*40+adrx)*32;
	GPIO_WriteBits(GPIO0,0x0000);	// dir=in clk = Lo
	do{pd = GPIO_ReadBits(GPIO0);}  while((pd & 1)!=0);		// Wait Busy
	wddt.i[0] = adr;
}
void get_vramdata(int dl){
	unsigned char i,dt;
	GPIO_WriteBits(GPIO0,0x0000);	// dir=in clk = Lo
	do{pd = GPIO_ReadBits(GPIO0);}  while((pd & 1)!=0);		// Wait Busy
	for(i=0;i<dl; i++){
		GPIO_WriteBits(GPIO0,0x100);
		wddt.b[i+4] = GPIO_ReadBits(GPIO0);
		GPIO_WriteBits(GPIO0,0x000);
	}
	GPIO_WriteBits(GPIO0,0x0000);	// dir=in clk = Lo

}
void get_vram(int adry, int adrx){
	unsigned char i,dt;
	if(adry==-1) { adry=0; adrx=0;}
	set_vramadr(adry, adrx);
	GPIO_WriteBits(GPIO0,0x200);	// dir=out clk=Lo
	for(i=0;i<4;i++){	// send addr
		dt = wddt.b[i];
		GPIO_WriteBits(GPIO0,0x200+dt);
		GPIO_WriteBits(GPIO0,0x300+dt);
	}
	get_vramdata(32);
}

void set_vramdata(int dl){
	unsigned char i, dt;
	GPIO_WriteBits(GPIO0,0x0000);	// dir=in clk = Lo
	do{pd = GPIO_ReadBits(GPIO0);}  while((pd & 1)!=0);		// Wait Busy
	GPIO_WriteBits(GPIO0,0x200);	// dir=out clk=Lo
	for(i=0;i<dl;i++){
		dt = wddt.b[i];
		GPIO_WriteBits(GPIO0,0x300+dt);
		GPIO_WriteBits(GPIO0,0x200+dt);
	}
	GPIO_WriteBits(GPIO0,0x0000);	// dir=in clk = Lo
}

void set_vramdata_f6(int dl){	// Fast(oney 6byte)
	unsigned char i, dt;
	GPIO_WriteBits(GPIO0,0x200);	// dir=out clk=Lo
	dt = wddt.b[0]; GPIO_WriteBits(GPIO0,0x300+dt); GPIO_WriteBits(GPIO0,0x200+dt);
	dt = wddt.b[1]; GPIO_WriteBits(GPIO0,0x300+dt); GPIO_WriteBits(GPIO0,0x200+dt);
	dt = wddt.b[2]; GPIO_WriteBits(GPIO0,0x300+dt); GPIO_WriteBits(GPIO0,0x200+dt);
	dt = wddt.b[3]; GPIO_WriteBits(GPIO0,0x300+dt); GPIO_WriteBits(GPIO0,0x200+dt);
	dt = wddt.b[4]; GPIO_WriteBits(GPIO0,0x300+dt); GPIO_WriteBits(GPIO0,0x200+dt);
	dt = wddt.b[5]; GPIO_WriteBits(GPIO0,0x300+dt); GPIO_WriteBits(GPIO0,0x200+dt);
	GPIO_WriteBits(GPIO0,0x0000);	// dir=in clk = Lo
}

void set_vram(int adry, int adrx){
	set_vramadr(adry, adrx);
	set_vramdata(37);
}

void move_vram(int dadr, int dlen, int sadr, int mode){
	unsigned char i, dt;
	if(dadr==-1) {
		if(mode==10){ dadr=0; dlen=640*2*(360); sadr=0x001f; }		// Fill
		if(mode==12){ dadr=0; dlen=640*2*(360-10); sadr=640*2*8; }	// Move
	}
	wddt.i[0] = dadr; wddt.i[1] = dlen; wddt.i[2] = sadr;
	set_vramdata(mode);
}
void set_vramm(int adry, int adrx, int ptn, int mask, int loopy, int loopx){
	int adr, x,y;
	unsigned char i, ph, pl, dt;
	if(loopy == -1) loopy = 1;
	if(loopx == -1) loopx = 1;
	ph = ptn >> 8; pl = ptn & 0xff;
	for(i=0;i<32;i=i+2){ wddt.b[4+i] = pl; wddt.b[5+i] = ph;}
	wddt.b[36] = mask;
	for(y=0; y<loopy; y++)
		for(x=0; x<loopx; x++) { set_vram(adry+y, adrx+x); }
 }

void dispscroll(int adry, int adrx){
	int sbeg=8, send=16, stop=0, xlen=1;
	int x,y;

	for(y=0; y<adry; y++){ //puth2(y); fflush(2);
		for(x=0; x<adrx; x++){
			get_vram(sbeg, x); wddt.b[36] = 0xff; // mask
			set_vram(stop, x);
		}
		sbeg++; stop++;
	}
}

#define maxdy 360
#define chardh 10
void set_char(int adry, int adrx, int ptn, int ccd){
	int adr, bp;
	unsigned char i, j, cgd, ph, pl;
	ccd = ccd * 8; // font.ddr
	ph = ptn >> 8; pl = ptn & 0xff;
	if((adrx&1)==0) wddt.b[5] = 0xf0; else wddt.b[5] = 0x0f;
	for(j=0; j<8; j++) {
		cgd = FONT_8x8[(ccd+j)& 0x7ff];
		wddt.b[4] = cgd;
		set_vramadr(adry*chardh+j, adrx/2);
		set_vramdata_f6(6);
	}
}

static int dispinitf = 0;
static int defptn = 0xffff;	// Not.Use
static int csrx=0,csry=0,csrmd=0;
int disp_vram(char chd){
	int i;
	GPIO_WriteBits(GPIO0,0x0000); pd = GPIO_ReadBits(GPIO0);
	if((pd & 1)!=0) return -1;	// Busy
	else {
		if(dispinitf==0 || chd==0x0c){
			move_vram( 0, 640*2*maxdy, 0, 10);	// Clear Vram
			csrx = 0; csry = 0;	csrmd = 0; dispinitf = 1;
		}
		//
		if(chd>=0x20) { set_char(csry, csrx, defptn, chd); csrx++; }
		else if(chd==0x0d) { csrx = 0; csry++;}
		if(csrx>=80) {csrx = 0; csry++;}
		if(csry>=(maxdy/chardh)) {
			if(csrmd==0) {
				move_vram( 0, 640*2*(maxdy-chardh), 640*2*(chardh), 12);	// Scrool
				move_vram( 640*2*(maxdy-chardh),640*2*maxdy, 0, 10);	// Clear
				csry = (maxdy/chardh-1); csrx = 0;
			} else {
				csry = 0; csrx = 0;
			}
		}
		return 0;
	}
}
void disp_vramw(char ch) { int rc; do{ rc = disp_vram(ch);} while(rc!=0); }

void gotoxy(u16 yp, u16 xp, u16 fc, u16 bc){

	if(yp==0xffff) {
		if(xp==0xffff) { dispinitf = 0; disp_vramw(0);}
		else           csrmd = xp;
	}
	else { csry=yp; csrx=xp; }
	//
	if(fc!=0 || bc!=0) { wddt.s[2] = fc;  wddt.s[3] = bc; set_vramdata(8); }
}

void dispfull(int adry, int adrx, int ptn, int ccd, int len){
	int x;
	if(len==-1) len = 1;
	if(adry==-1) { adry=0; adrx=0; ptn=0x07e0; ccd=0x30; len=0x10;}
	for( x=0; x<len; x++) {
		if((adrx+x)>=80) {adrx = adrx - 80; adry++;}
		set_char(adry,adrx+x,ptn,ccd+x);
	}
}

u16 pget(u16 xp, u16 yp){
	unsigned char ph, pl, px;
	wddt.b[4] = xp & 15;
	set_vramadr(yp, xp/16);
	set_vramdata(5);	// adr(4)+bitpos(1)
	get_vramdata(2);
	pl = wddt.b[4+px+0]; ph = wddt.b[4+px+1];
	return (u16)ph<<8 | (u16)pl;
}

void pset(u16 xp, u16 yp, u16 ptn){	// xp=0-639 yp=0-359
	unsigned char ph, pl, px;
	//if(xp==0xffff) { dispinitf = 0; disp_vramw(0);}
	//else {
		wddt.s[2] = ptn; wddt.b[6] = xp & 15; // bit.pos
		set_vramadr(yp, xp/16);
		set_vramdata(7);	// adr(4)+ptn(2)+bitpos(1)
	//}
}

void DCircle(u16 x0,u16 y0,u16 r,u16 ptn) {
  int a,b,di;
  a=0; b=r; di=3-(r<<1);
  while(a<=b) {
    pset(x0-b,y0-a,ptn); pset(x0+b,y0-a,ptn); pset(x0-a,y0+b,ptn);
    pset(x0-b,y0-a,ptn); pset(x0-a,y0-b,ptn); pset(x0+b,y0+a,ptn);
    pset(x0+a,y0-b,ptn); pset(x0+a,y0+b,ptn); pset(x0-b,y0+a,ptn);
    a++;
    if(di<0) di += 4*a+6;
    else {   di += 10+4*(a-b); b--; }
    pset(x0+a,y0+b,ptn);
  }
}
void DLine(u16 x1, u16 y1, u16 x2, u16 y2, u16 ptn) {
  u16 t;
  int xerr=0,yerr=0,delta_x,delta_y,distance;
  int incx,incy,uRow,uCol;

  delta_x=x2-x1;  delta_y=y2-y1; uRow=x1; uCol=y1;
  if(delta_x>0) incx=1;
  else if(delta_x==0)incx=0;
  else {incx=-1;delta_x=-delta_x;}
  if(delta_y>0)incy=1;
  else if(delta_y==0)incy=0;
  else{incy=-1;delta_y=-delta_y;}
  if( delta_x>delta_y)distance=delta_x;
  else distance=delta_y;
  for(t=0;t<=distance+1;t++ ) {
	pset(uRow,uCol,ptn);
    xerr+=delta_x ; yerr+=delta_y ;
    if(xerr>distance) { xerr-=distance; uRow+=incx; }
    if(yerr>distance) { yerr-=distance; uCol+=incy; }
  }
}
void DrawRectangle(u16 x1, u16 y1, u16 x2, u16 y2, u16 ptn) {
  DLine(x1,y1,x2,y1,ptn); DLine(x1,y1,x1,y2,ptn);
  DLine(x1,y2,x2,y2,ptn); DLine(x2,y1,x2,y2,ptn);
}

#define MAXSIZE 256 // Seed Size MAX
#define MINX 0
#define MINY 0
#define MAXX 640
#define MAXY 360

struct BufStr { u16 sx; u16 sy; };
//struct BufStr buff[MAXSIZE]; // Seed Buf
struct BufStr *buff = (struct BufStr *)&aryex[0]; // Seed Buf
struct BufStr *sIdx, *eIdx;  // Seed Buf Poiner

u16 point( u16 x, u16 y ){ return pget(x,y); }
void scanLine( u16 lx, u16 rx, u16 y, u16 col ){
  while ( lx <= rx ) {
    for ( ; lx <= rx ; lx++ ) if ( point( lx, y ) == col ) break;
    if ( point( lx, y ) != col ) break;
    for ( ; lx <= rx ; lx++ ) if ( point( lx, y ) != col ) break;
    eIdx->sx = lx - 1; eIdx->sy = y;
    if ( ++eIdx == &buff[MAXSIZE] ) eIdx = buff;
  }
}
void DPaint( u16 x, u16 y, u16 paintCol ){
  u16 lx, rx, ly,  i;
  u16 col = point( x, y );
  if ( col == paintCol ) return;
  sIdx = buff;  eIdx = buff + 1;
  sIdx->sx = x; sIdx->sy = y;
  do {
    lx = rx = sIdx->sx; ly = sIdx->sy;
    if ( ++sIdx == &buff[MAXSIZE] ) sIdx = buff;
    if ( point( lx, ly ) != col ) continue;
     while ( rx < MAXX ) { // Scan Right
      if ( point( rx + 1, ly ) != col ) break;
      rx++;
    }
    while ( lx > MINX ) { // Scan Left
      if ( point( lx - 1, ly ) != col ) break;
      lx--;
    }
    for ( i = lx ; i <= rx ; i++ ) pset( i, ly, paintCol );
    if ( ly - 1 >= MINY ) scanLine( lx, rx, ly - 1, col ); // Scan UP Line
    if ( ly + 1 <= MAXY ) scanLine( lx, rx, ly + 1, col ); // Scan Down Line
  } while ( sIdx != eIdx );
}

const unsigned char FONT_8x8[] = {
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// 00
   0x7e, 0x81, 0xa5, 0x81, 0xbd, 0x99, 0x81, 0x7e,
   0x7e, 0xff, 0xdb, 0xff, 0xc3, 0xe7, 0xff, 0x7e,
   0x6c, 0xfe, 0xfe, 0xfe, 0x7c, 0x38, 0x10, 0x00,
   0x10, 0x38, 0x7c, 0xfe, 0x7c, 0x38, 0x10, 0x00,
   0x3c, 0x3c, 0x18, 0xff, 0xe7, 0x18, 0x3c, 0x00,
   0x10, 0x38, 0x7c, 0xfe, 0xee, 0x10, 0x38, 0x00,
   0x00, 0x00, 0x18, 0x3c, 0x3c, 0x18, 0x00, 0x00,
   0xff, 0xff, 0xe7, 0xc3, 0xc3, 0xe7, 0xff, 0xff,
   0x00, 0x3c, 0x66, 0x42, 0x42, 0x66, 0x3c, 0x00,
   0xff, 0xc3, 0x99, 0xbd, 0xbd, 0x99, 0xc3, 0xff,
   0x1e, 0x06, 0x0a, 0x78, 0xcc, 0xcc, 0x78, 0x00,
   0x3c, 0x42, 0x42, 0x42, 0x3c, 0x18, 0x7e, 0x18,
   0x08, 0x0c, 0x0a, 0x0a, 0x08, 0x78, 0xf0, 0x00,
   0x18, 0x14, 0x1a, 0x16, 0x72, 0xe2, 0x0e, 0x1c,
   0x10, 0x54, 0x38, 0xee, 0x38, 0x54, 0x10, 0x00,
   0x80, 0xe0, 0xf8, 0xfe, 0xf8, 0xe0, 0x80, 0x00,	// 10
   0x02, 0x0e, 0x3e, 0xfe, 0x3e, 0x0e, 0x02, 0x00,
   0x18, 0x3c, 0x5a, 0x18, 0x5a, 0x3c, 0x18, 0x00,
   0x66, 0x66, 0x66, 0x66, 0x66, 0x00, 0x66, 0x00,
   0x7f, 0xdb, 0xdb, 0xdb, 0x7b, 0x1b, 0x1b, 0x00,
   0x1c, 0x22, 0x38, 0x44, 0x44, 0x38, 0x88, 0x70,
   0x00, 0x00, 0x00, 0x00, 0x7e, 0x7e, 0x7e, 0x00,
   0x18, 0x3c, 0x5a, 0x18, 0x5a, 0x3c, 0x18, 0x7e,
   0x18, 0x3c, 0x5a, 0x18, 0x18, 0x18, 0x18, 0x00,
   0x18, 0x18, 0x18, 0x18, 0x5a, 0x3c, 0x18, 0x00,
   0x00, 0x18, 0x0c, 0xfe, 0x0c, 0x18, 0x00, 0x00,
   0x00, 0x30, 0x60, 0xfe, 0x60, 0x30, 0x00, 0x00,
   0x00, 0x00, 0x00, 0xc0, 0xc0, 0xc0, 0xff, 0x00,
   0x00, 0x24, 0x42, 0xff, 0x42, 0x24, 0x00, 0x00,
   0x00, 0x10, 0x38, 0x7c, 0xfe, 0xfe, 0x00, 0x00,
   0x00, 0xfe, 0xfe, 0x7c, 0x38, 0x10, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,	// 20
   0x30, 0x78, 0x78, 0x30, 0x30, 0x00, 0x30, 0x00,
   0x6c, 0x24, 0x24, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x6c, 0x6c, 0xfe, 0x6c, 0xfe, 0x6c, 0x6c, 0x00,
   0x10, 0x7c, 0xd0, 0x7c, 0x16, 0xfc, 0x10, 0x00,
   0x00, 0x66, 0xac, 0xd8, 0x36, 0x6a, 0xcc, 0x00,
   0x38, 0x4c, 0x38, 0x78, 0xce, 0xcc, 0x7a, 0x00,
   0x30, 0x10, 0x20, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x18, 0x30, 0x60, 0x60, 0x60, 0x30, 0x18, 0x00,
   0x60, 0x30, 0x18, 0x18, 0x18, 0x30, 0x60, 0x00,
   0x00, 0x66, 0x3c, 0xff, 0x3c, 0x66, 0x00, 0x00,
   0x00, 0x30, 0x30, 0xfc, 0x30, 0x30, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x10, 0x20,
   0x00, 0x00, 0x00, 0xfc, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30, 0x00,
   0x02, 0x06, 0x0c, 0x18, 0x30, 0x60, 0xc0, 0x00,
   0x7c, 0xce, 0xde, 0xf6, 0xe6, 0xe6, 0x7c, 0x00,	// 30
   0x18, 0x38, 0x78, 0x18, 0x18, 0x18, 0x7e, 0x00,
   0x7c, 0xc6, 0x06, 0x1c, 0x70, 0xc0, 0xfe, 0x00,
   0x7c, 0xc6, 0x06, 0x3c, 0x06, 0xc6, 0x7c, 0x00,
   0x1c, 0x3c, 0x6c, 0xcc, 0xfe, 0x0c, 0x1e, 0x00,
   0xfe, 0xc0, 0xfc, 0x06, 0x06, 0xc6, 0x7c, 0x00,
   0x7c, 0xc6, 0xc0, 0xfc, 0xc6, 0xc6, 0x7c, 0x00,
   0xfe, 0xc6, 0x86, 0x0c, 0x18, 0x30, 0x30, 0x00,
   0x7c, 0xc6, 0xc6, 0x7c, 0xc6, 0xc6, 0x7c, 0x00,
   0x7c, 0xc6, 0xc6, 0x7e, 0x06, 0xc6, 0x7c, 0x00,
   0x00, 0x30, 0x00, 0x00, 0x00, 0x30, 0x00, 0x00,
   0x00, 0x30, 0x00, 0x00, 0x00, 0x30, 0x10, 0x20,
   0x0c, 0x18, 0x30, 0x60, 0x30, 0x18, 0x0c, 0x00,
   0x00, 0x00, 0x7e, 0x00, 0x00, 0x7e, 0x00, 0x00,
   0x60, 0x30, 0x18, 0x0c, 0x18, 0x30, 0x60, 0x00,
   0x78, 0xcc, 0x0c, 0x18, 0x30, 0x00, 0x30, 0x00,
   0x7c, 0x82, 0x9e, 0xa6, 0x9e, 0x80, 0x7c, 0x00,	// 40
   0x7c, 0xc6, 0xc6, 0xfe, 0xc6, 0xc6, 0xc6, 0x00,
   0xfc, 0x66, 0x66, 0x7c, 0x66, 0x66, 0xfc, 0x00,
   0x7c, 0xc6, 0xc0, 0xc0, 0xc0, 0xc6, 0x7c, 0x00,
   0xfc, 0x66, 0x66, 0x66, 0x66, 0x66, 0xfc, 0x00,
   0xfe, 0x62, 0x68, 0x78, 0x68, 0x62, 0xfe, 0x00,
   0xfe, 0x62, 0x68, 0x78, 0x68, 0x60, 0xf0, 0x00,
   0x7c, 0xc6, 0xc6, 0xc0, 0xce, 0xc6, 0x7e, 0x00,
   0xc6, 0xc6, 0xc6, 0xfe, 0xc6, 0xc6, 0xc6, 0x00,
   0x3c, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0x1e, 0x0c, 0x0c, 0x0c, 0xcc, 0xcc, 0x78, 0x00,
   0xe6, 0x66, 0x64, 0x78, 0x6c, 0x66, 0xe6, 0x00,
   0xf0, 0x60, 0x60, 0x60, 0x62, 0x66, 0xfe, 0x00,
   0x82, 0xc6, 0xee, 0xfe, 0xd6, 0xc6, 0xc6, 0x00,
   0xc6, 0xe6, 0xf6, 0xde, 0xce, 0xc6, 0xc6, 0x00,
   0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0xfc, 0x66, 0x66, 0x7c, 0x60, 0x60, 0xf0, 0x00,	// 50
   0x7c, 0xc6, 0xc6, 0xc6, 0xd6, 0xde, 0x7c, 0x06,
   0xfc, 0x66, 0x66, 0x7c, 0x66, 0x66, 0xe6, 0x00,
   0x7c, 0xc6, 0xc0, 0x7c, 0x06, 0xc6, 0x7c, 0x00,
   0x7e, 0x5a, 0x5a, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x6c, 0x38, 0x00,
   0xc6, 0xc6, 0xd6, 0xfe, 0xee, 0xc6, 0x82, 0x00,
   0xc6, 0x6c, 0x38, 0x38, 0x38, 0x6c, 0xc6, 0x00,
   0x66, 0x66, 0x66, 0x3c, 0x18, 0x18, 0x3c, 0x00,
   0xfe, 0xc6, 0x8c, 0x18, 0x32, 0x66, 0xfe, 0x00,
   0x78, 0x60, 0x60, 0x60, 0x60, 0x60, 0x78, 0x00,
   0xc0, 0x60, 0x30, 0x18, 0x0c, 0x06, 0x02, 0x00,
   0x78, 0x18, 0x18, 0x18, 0x18, 0x18, 0x78, 0x00,
   0x10, 0x38, 0x6c, 0xc6, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xff,
   0x30, 0x20, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00,	// 60
   0x00, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0x76, 0x00,
   0xe0, 0x60, 0x60, 0x7c, 0x66, 0x66, 0x7c, 0x00,
   0x00, 0x00, 0x7c, 0xc6, 0xc0, 0xc6, 0x7c, 0x00,
   0x1c, 0x0c, 0x0c, 0x7c, 0xcc, 0xcc, 0x76, 0x00,
   0x00, 0x00, 0x7c, 0xc6, 0xfe, 0xc0, 0x7c, 0x00,
   0x1c, 0x36, 0x30, 0x78, 0x30, 0x30, 0x78, 0x00,
   0x00, 0x00, 0x76, 0xcc, 0xcc, 0x7c, 0x0c, 0x78,
   0xe0, 0x60, 0x6c, 0x76, 0x66, 0x66, 0xe6, 0x00,
   0x18, 0x00, 0x38, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0x00, 0x0c, 0x00, 0x1c, 0x0c, 0x0c, 0xcc, 0x78,
   0xe0, 0x60, 0x66, 0x6c, 0x78, 0x6c, 0xe6, 0x00,
   0x38, 0x18, 0x18, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0x00, 0x00, 0xcc, 0xfe, 0xd6, 0xd6, 0xd6, 0x00,
   0x00, 0x00, 0xdc, 0x66, 0x66, 0x66, 0x66, 0x00,
   0x00, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0x00, 0x00, 0xdc, 0x66, 0x66, 0x7c, 0x60, 0xf0,	// 70
   0x00, 0x00, 0x7c, 0xcc, 0xcc, 0x7c, 0x0c, 0x1e,
   0x00, 0x00, 0xde, 0x76, 0x60, 0x60, 0xf0, 0x00,
   0x00, 0x00, 0x7c, 0xc0, 0x7c, 0x06, 0x7c, 0x00,
   0x10, 0x30, 0xfc, 0x30, 0x30, 0x34, 0x18, 0x00,
   0x00, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00,
   0x00, 0x00, 0xc6, 0xc6, 0xc6, 0x6c, 0x38, 0x00,
   0x00, 0x00, 0xc6, 0xd6, 0xd6, 0xfe, 0x6c, 0x00,
   0x00, 0x00, 0xc6, 0x6c, 0x38, 0x6c, 0xc6, 0x00,
   0x00, 0x00, 0xc6, 0xc6, 0xc6, 0x7e, 0x06, 0x7c,
   0x00, 0x00, 0xfc, 0x98, 0x30, 0x64, 0xfc, 0x00,
   0x0e, 0x18, 0x18, 0x30, 0x18, 0x18, 0x0e, 0x00,
   0x18, 0x18, 0x18, 0x00, 0x18, 0x18, 0x18, 0x00,
   0xe0, 0x30, 0x30, 0x18, 0x30, 0x30, 0xe0, 0x00,
   0x76, 0xdc, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x10, 0x38, 0x6c, 0xc6, 0xc6, 0xfe, 0x00,
   0x7c, 0xc6, 0xc0, 0xc0, 0xc6, 0x7c, 0x18, 0x70,
   0xcc, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00,
   0x0e, 0x10, 0x7c, 0xc6, 0xfe, 0xc0, 0x7c, 0x00,
   0x7c, 0x82, 0x38, 0x0c, 0x7c, 0xcc, 0x76, 0x00,
   0xcc, 0x00, 0x78, 0x0c, 0x7c, 0xcc, 0x76, 0x00,
   0xe0, 0x10, 0x78, 0x0c, 0x7c, 0xcc, 0x76, 0x00,
   0x30, 0x30, 0x78, 0x0c, 0x7c, 0xcc, 0x76, 0x00,
   0x00, 0x00, 0x7c, 0xc0, 0xc0, 0x7c, 0x18, 0x70,
   0x7c, 0x82, 0x7c, 0xc6, 0xfe, 0xc0, 0x7c, 0x00,
   0xc6, 0x00, 0x7c, 0xc6, 0xfe, 0xc0, 0x7c, 0x00,
   0xe0, 0x10, 0x7c, 0xc6, 0xfe, 0xc0, 0x7c, 0x00,
   0x66, 0x00, 0x38, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0x7c, 0x82, 0x38, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0xe0, 0x10, 0x38, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0xc6, 0x00, 0x7c, 0xc6, 0xfe, 0xc6, 0xc6, 0x00,
   0x38, 0x38, 0x7c, 0xc6, 0xfe, 0xc6, 0xc6, 0x00,
   0x0e, 0x10, 0xfe, 0x60, 0x78, 0x60, 0xfe, 0x00,
   0x00, 0x00, 0x7c, 0x12, 0x7e, 0xd0, 0x7e, 0x00,
   0x7e, 0xc8, 0xc8, 0xfe, 0xc8, 0xc8, 0xce, 0x00,
   0x7c, 0x82, 0x7c, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0xc6, 0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0xe0, 0x10, 0x7c, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0x7c, 0x82, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00,
   0xe0, 0x10, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00,
   0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0x7e, 0x06, 0x7c,
   0xc6, 0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0xc6, 0x00, 0xc6, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0x18, 0x7c, 0xd6, 0xd0, 0xd6, 0x7c, 0x18, 0x00,
   0x38, 0x6c, 0x60, 0xf0, 0x60, 0xf2, 0xdc, 0x00,
   0x66, 0x3c, 0x18, 0x7e, 0x18, 0x7e, 0x18, 0x00,
   0xf8, 0xcc, 0xf8, 0xc4, 0xcc, 0xde, 0xcc, 0x06,
   0x0e, 0x1b, 0x18, 0x3c, 0x18, 0x18, 0xd8, 0x70,
   0x0e, 0x10, 0x78, 0x0c, 0x7c, 0xcc, 0x76, 0x00,
   0x0e, 0x10, 0x38, 0x18, 0x18, 0x18, 0x3c, 0x00,
   0x0e, 0x10, 0x7c, 0xc6, 0xc6, 0xc6, 0x7c, 0x00,
   0x0e, 0x10, 0xcc, 0xcc, 0xcc, 0xcc, 0x76, 0x00,
   0x66, 0x98, 0xdc, 0x66, 0x66, 0x66, 0x66, 0x00,
   0x66, 0x98, 0xe6, 0xf6, 0xde, 0xce, 0xc6, 0x00,
   0x38, 0x0c, 0x3c, 0x34, 0x00, 0x7e, 0x00, 0x00,
   0x38, 0x6c, 0x6c, 0x38, 0x00, 0x7c, 0x00, 0x00,
   0x30, 0x00, 0x30, 0x60, 0xc6, 0xc6, 0x7c, 0x00,
   0x00, 0x00, 0xfe, 0xc0, 0xc0, 0xc0, 0x00, 0x00,
   0x00, 0x00, 0xfe, 0x06, 0x06, 0x06, 0x00, 0x00,
   0xc0, 0xc8, 0xd0, 0xfe, 0x46, 0x8c, 0x1e, 0x00,
   0xc0, 0xc8, 0xd0, 0xec, 0x5c, 0xbe, 0x0c, 0x00,
   0x18, 0x00, 0x18, 0x18, 0x18, 0x18, 0x18, 0x00,
   0x00, 0x36, 0x6c, 0xd8, 0x6c, 0x36, 0x00, 0x00,
   0x00, 0xd8, 0x6c, 0x36, 0x6c, 0xd8, 0x00, 0x00,
   0x00, 0x55, 0x00, 0x55, 0x00, 0x55, 0x00, 0x55,
   0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55, 0xaa, 0x55,
   0xff, 0x55, 0xff, 0x55, 0xff, 0x55, 0xff, 0x55,
   0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x18, 0x18, 0xf8, 0x18, 0x18, 0x18,
   0x18, 0x18, 0xf8, 0x18, 0xf8, 0x18, 0x18, 0x18,
   0x36, 0x36, 0x36, 0x36, 0xf6, 0x36, 0x36, 0x36,
   0x00, 0x00, 0x00, 0x00, 0xfe, 0x36, 0x36, 0x36,
   0x00, 0x00, 0xf8, 0x18, 0xf8, 0x18, 0x18, 0x18,
   0x36, 0x36, 0xf6, 0x06, 0xf6, 0x36, 0x36, 0x36,
   0x36, 0x36, 0x36, 0x36, 0x36, 0x36, 0x36, 0x36,
   0x00, 0x00, 0xfe, 0x06, 0xf6, 0x36, 0x36, 0x36,
   0x36, 0x36, 0xf6, 0x06, 0xfe, 0x00, 0x00, 0x00,
   0x36, 0x36, 0x36, 0x36, 0xfe, 0x00, 0x00, 0x00,
   0x18, 0x18, 0xf8, 0x18, 0xf8, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0xf8, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x18, 0x18, 0x1f, 0x00, 0x00, 0x00,
   0x18, 0x18, 0x18, 0x18, 0xff, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0xff, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x18, 0x18, 0x1f, 0x18, 0x18, 0x18,
   0x00, 0x00, 0x00, 0x00, 0xff, 0x00, 0x00, 0x00,
   0x18, 0x18, 0x18, 0x18, 0xff, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x1f, 0x18, 0x1f, 0x18, 0x18, 0x18,
   0x36, 0x36, 0x36, 0x36, 0x37, 0x36, 0x36, 0x36,
   0x36, 0x36, 0x37, 0x30, 0x3f, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x3f, 0x30, 0x37, 0x36, 0x36, 0x36,
   0x36, 0x36, 0xf7, 0x00, 0xff, 0x00, 0x00, 0x00,
   0x00, 0x00, 0xff, 0x00, 0xf7, 0x36, 0x36, 0x36,
   0x36, 0x36, 0x37, 0x30, 0x37, 0x36, 0x36, 0x36,
   0x00, 0x00, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00,
   0x36, 0x36, 0xf7, 0x00, 0xf7, 0x36, 0x36, 0x36,
   0x18, 0x18, 0xff, 0x00, 0xff, 0x00, 0x00, 0x00,
   0x36, 0x36, 0x36, 0x36, 0xff, 0x00, 0x00, 0x00,
   0x00, 0x00, 0xff, 0x00, 0xff, 0x18, 0x18, 0x18,
   0x00, 0x00, 0x00, 0x00, 0xff, 0x36, 0x36, 0x36,
   0x36, 0x36, 0x36, 0x36, 0x3f, 0x00, 0x00, 0x00,
   0x18, 0x18, 0x1f, 0x18, 0x1f, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x1f, 0x18, 0x1f, 0x18, 0x18, 0x18,
   0x00, 0x00, 0x00, 0x00, 0x3f, 0x36, 0x36, 0x36,
   0x36, 0x36, 0x36, 0x36, 0xff, 0x36, 0x36, 0x36,
   0x18, 0x18, 0xff, 0x18, 0xff, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x18, 0x18, 0xf8, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x1f, 0x18, 0x18, 0x18,
   0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
   0x00, 0x00, 0x00, 0x00, 0xff, 0xff, 0xff, 0xff,
   0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0, 0xf0,
   0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f, 0x0f,
   0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x74, 0xcc, 0xc8, 0xdc, 0x76, 0x00,
   0x78, 0xcc, 0xd8, 0xcc, 0xc6, 0xc6, 0xdc, 0x40,
   0xfe, 0x62, 0x60, 0x60, 0x60, 0x60, 0xf0, 0x00,
   0x00, 0x02, 0x7e, 0xec, 0x6c, 0x6c, 0x48, 0x00,
   0xfe, 0x62, 0x30, 0x18, 0x30, 0x62, 0xfe, 0x00,
   0x00, 0x00, 0x7e, 0xd0, 0xc8, 0xc8, 0x70, 0x00,
   0x00, 0x00, 0xcc, 0xcc, 0xcc, 0xcc, 0xf8, 0x80,
   0x00, 0x00, 0x7e, 0xd8, 0x18, 0x18, 0x10, 0x00,
   0x38, 0x10, 0x7c, 0xd6, 0xd6, 0x7c, 0x10, 0x38,
   0x7c, 0xc6, 0xc6, 0xfe, 0xc6, 0xc6, 0x7c, 0x00,
   0x7c, 0xc6, 0xc6, 0xc6, 0x6c, 0x28, 0xee, 0x00,
   0x3c, 0x22, 0x18, 0x7c, 0xcc, 0xcc, 0x78, 0x00,
   0x00, 0x00, 0x66, 0x99, 0x99, 0x66, 0x00, 0x00,
   0x00, 0x06, 0x7c, 0x9e, 0xf2, 0x7c, 0xc0, 0x00,
   0x00, 0x00, 0x7c, 0xc0, 0xf8, 0xc0, 0x7c, 0x00,
   0x00, 0x7c, 0xc6, 0xc6, 0xc6, 0xc6, 0xc6, 0x00,
   0x00, 0xfe, 0x00, 0xfe, 0x00, 0xfe, 0x00, 0x00,
   0x18, 0x18, 0x7e, 0x18, 0x18, 0x00, 0x7e, 0x00,
   0x30, 0x18, 0x0c, 0x18, 0x30, 0x00, 0x7c, 0x00,
   0x18, 0x30, 0x60, 0x30, 0x18, 0x00, 0x7c, 0x00,
   0x0e, 0x1b, 0x1b, 0x18, 0x18, 0x18, 0x18, 0x18,
   0x18, 0x18, 0x18, 0x18, 0x18, 0xd8, 0xd8, 0x70,
   0x00, 0x18, 0x00, 0x7e, 0x00, 0x18, 0x00, 0x00,
   0x00, 0x76, 0xdc, 0x00, 0x76, 0xdc, 0x00, 0x00,
   0x38, 0x6c, 0x38, 0x00, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x18, 0x18, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x18, 0x00, 0x00, 0x00,
   0x0f, 0x0c, 0x0c, 0x0c, 0xec, 0x6c, 0x3c, 0x00,
   0xd8, 0x6c, 0x6c, 0x6c, 0x00, 0x00, 0x00, 0x00,
   0xf0, 0x30, 0xc0, 0xf0, 0x00, 0x00, 0x00, 0x00,
   0x00, 0x00, 0x3c, 0x3c, 0x3c, 0x3c, 0x00, 0x00,
   0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
 };

/* Test For Basic
// LINE
10 GOXY -1,-1
20 FOR X=0 TO 639 step 4
30 LINE X,0,X,359,X*128+X
40 NEXT X
50 FOR Y=0 TO 359 step 4
60 LINE 0,Y,639,Y,Y*256+Y
70 NEXT Y
run
//
10 GOXY -1,-1
15 X=0
16 Y=0
20 FOR R=1 TO 50
22 A=RND(640)
23 IF A<50 A=0
24 IF A>620 A=639
25 B=RND(360)
26 IF B<20 B=0
27 IF B>340 B=359
30 LINE X,Y,A,B,RND(32767)*2
32 X=A
34 Y=B
40 NEXT R
50 FOR R=1 TO 50
60 PAINT RND(640-200)+100,RND(360-200)+100,RND(32767)*2
70 NEXT R
//
10 GOXY -1,-1
20 FOR R=1 TO 20
30 CIRCLE RND(640),RND(360),RND(320),RND(32767)*2
40 NEXT R
50 FOR R=1 TO 50
60 PAINT RND(640-100)+50,RND(360-100)+50,RND(32767)*2
70 NEXT R
// 3D
10 GOXY -1,-1
20 ? "Start"
40 FOR J=0 TO 480
41 @@(J)=1000
42 NEXT J
100 N=0
110 Y=0
120 X=20
130 GOSUB 200
131 C=F
132 C=-C*32 + ((16-C)*16) + (C/2)
140 Z=360-F-Y
145 IF @@(X)<Z GOTO 160
150 REM ? X," ",Z," "," ",C
151 PSET X*2,Z,C
152 PSET X*2+1,Z,C
153 PSET X*2,Z+1,C
154 PSET X*2+1,Z+1,C
159 @@(X)=Z
160 X=X+1
161 IF X<300 GOTO 130
170 Y=Y+1
171 IF Y<300 GOTO 120
180 REM
190 ? "End"
191 STOP
200 REM
210 J=X-160
220 K=Y-180
230 J=J/2*J
232 T=J
234 K=K/2*K
236 J=J+K
240 K=J/2
250 L=0
260 M=K-L
261 IF M<0 M=-M
270 IF M<2 GOTO 300
280 L=K
281 K=(J/K+K)/2
282 GOTO 260
300 REM
310 IF K<=49 GOTO 320
311 K=K-50
312 GOTO 310
320 IF K>24 K=49-K
330 F=K*4
331 RETURN
*/
/*

HyperRAM ���_�l
�@�쓮Clock  = 148.5MHz�ŋ쓮(MAX��166MHz)
�@DRAM�ш敝 = 148.5�~2=297MB/S(166MHz�쓮�Ȃ�332MB/S)
  �@�o�[�X�g��128Byte
�@�@���_����   = 74%
�@�@���_�ш敝 = 297MB�~74%=220MB/S(�@�V�@246MB/S)
  �A�o�[�X�g��32Byte
�@�@���_����   = 42%
�@�@���_�ш敝 = 297MB�~42%=125MB/S

VRAM�g�p�ш�
�@�@1280x720 60fps 3Byte/Pixcel
�@�@�K�v�ш� = 1280�~720�~60�~3=166MB/S
�@�A1280x720 60fps 2Byte/Pixcel
�@�@�K�v�ш� = 1280�~720�~60�~2=111MB/S
�@�B640x360  60fps 2Byte/Pixcel
  �@�K�v�ш� = 640�~360�~60�~2=28MB/S
*/