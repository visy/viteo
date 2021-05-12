#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <dos.h>
#include <mem.h>
#include <i86.h>


typedef struct
{
	unsigned port;
	unsigned char index;
	unsigned char value;
} Register;

typedef Register *RegisterPtr;

#include "mode1.h"
#include "mode2.h"

typedef unsigned char  byte;
typedef unsigned short word;
typedef unsigned long  dword;

#define SET_MODE  0x00      /* BIOS func to set the video mode. */
#define VIDEO_INT 0x10      /* the BIOS video interrupt. */

byte *VGA=(byte*)0xA0000L;

void set_mode(byte mode)
{
	union REGS regs;

	regs.h.ah = SET_MODE;
	regs.h.al = mode;
	int386(VIDEO_INT, &regs, &regs);
}

#define ATTRCON_ADDR	0x3c0
#define MISC_ADDR		0x3c2
#define VGAENABLE_ADDR	0x3c3
#define SEQ_ADDR		0x3c4
#define GRACON_ADDR		0x3ce
#define CRTC_ADDR		0x3d4
#define STATUS_ADDR		0x3da

#define outportb outp
#define inportb inp

void readyVgaRegs(void)
{
	int v;
	outportb(0x3d4,0x11);
  v = inportb(0x3d5) & 0x7f;
	outportb(0x3d4,0x11);
	outportb(0x3d5,v);
}

/*
	outReg sets a single register according to the contents of the
	passed Register structure.
*/

void outReg(Register r)
{
	switch (r.port)
	{
		/* First handle special cases: */

		case ATTRCON_ADDR:
			inportb(STATUS_ADDR);  		/* reset read/write flip-flop */
			outportb(ATTRCON_ADDR, r.index | 0x20);
										/* ensure VGA output is enabled */
			outportb(ATTRCON_ADDR, r.value);
			break;

		case MISC_ADDR:
		case VGAENABLE_ADDR:
			outportb(r.port, r.value);	/*	directly to the port */
			break;

		case SEQ_ADDR:
		case GRACON_ADDR:
		case CRTC_ADDR:
		default:						/* This is the default method: */
			outportb(r.port, r.index);	/*	index to port			   */
			outportb(r.port+1, r.value);/*	value to port+1 		   */
			break;
	}
}

void outRegArray(Register *r, int n)
{
  readyVgaRegs();
	while (n--)
		outReg(*r++);
}

void set_mode_q() 
{
	RegisterPtr rarray = mode2;
	outRegArray(rarray,25);
}

void quit(char *message) 
{
  set_mode(0x03);
	printf(message);
	exit(0);
}

// video data buffers	
byte *bufferpix;
byte *buffercol;

inline void set(int x, int y, int c) 
{
	VGA[(y<<8)+x] = c;
}

byte frame = 0;

long vi = 0;

void sampleVideo() 
{
	int x=0,y=0,x1=0,y1=0;

	VGA[0] = frame;

	for(y=0;y<256;y+=8) {
		for(x=0;x<256;x+=8) {
			byte i1 = bufferpix[vi];
			byte i2 = bufferpix[vi+1];
			byte i3 = bufferpix[vi+2];

			byte p1 = buffercol[vi];
			byte p2 = buffercol[vi+1];
			byte p3 = buffercol[vi+2];

			int x2 = i1%8;
			int y2 = i1/8;
			int x3 = i2%8;
			int y3 = i2/8;
			int x4 = i3%8;
			int y4 = i3/8;

			for (y1=0;y1<8;y1++) {
				for (x1=0;x1<8;x1++) {

					double d1=sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));
					double d2=sqrt((x3-x1)*(x3-x1) + (y3-y1)*(y3-y1));
		   		  	double d3=sqrt((x4-x1)*(x4-x1) + (y4-y1)*(y4-y1));

					if (d1 < d2 && d1 < d3) {
						set(x+x1+x2,y+y1+y2,p1);
					}
					else if (d2 < d2) {
						set(x+x1+x3,y+y1+y3,p2);
					}
					else {
						set(x+x1+x4,y+y1+y4,p3);
					}

				}
			}
	

			vi+=3;
		}
	}
}

int main(int argc, char *argv[]) 
{
	FILE *vfile;
  FILE *cfile;
	long lsize;
	size_t result;

	char ch;
	
	vfile = fopen("vpix.dat","rb");
	if (vfile == NULL) { 
		quit("error opening vpix.dat\n"); 
	}

	fseek(vfile,0,SEEK_END);
	lsize = ftell(vfile);
  rewind(vfile);

	bufferpix = (byte*) malloc(sizeof(byte)*lsize);
	if (bufferpix == NULL) { quit("not enough memory\n"); }

	result = fread(bufferpix,1,lsize,vfile);
	if (result != lsize) { quit("error reading vpix.dat\n"); }

	//
	
  cfile = fopen("vcol.dat","rb");
	if (cfile == NULL) { 
		quit("error opening vcol.dat\n"); 
	}

	fseek(cfile,0,SEEK_END);
	lsize = ftell(cfile);
  rewind(cfile);

	buffercol = (byte*) malloc(sizeof(byte)*lsize);
	if (buffercol == NULL) { quit("not enough memory\n"); }

	result = fread(buffercol,1,lsize,cfile);
	if (result != lsize) { quit("error reading vcol.dat\n"); }

	fclose(vfile);
	fclose(cfile);

  printf("Starting...\n");
	set_mode(0x13);
	set_mode_q();

	while(!kbhit()) {
		sampleVideo();
		frame++;
	}

	quit("Have a nice day.");
	return 0;
}
