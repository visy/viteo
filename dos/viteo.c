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


#define SET_MODE                0x00      /* BIOS func to set the video mode. */
#define VIDEO_INT               0x10      /* the BIOS video interrupt. */
#define VRETRACE                0x08
#define INPUT_STATUS_1  0x03da

byte *VGA=(byte*)0xA0000L;

void set_mode(byte mode)
{
        union REGS regs;

        regs.h.ah = SET_MODE;
        regs.h.al = mode;
        int386(VIDEO_INT, &regs, &regs);
}

#define ATTRCON_ADDR    0x3c0
#define MISC_ADDR               0x3c2
#define VGAENABLE_ADDR  0x3c3
#define SEQ_ADDR                0x3c4
#define GRACON_ADDR             0x3ce
#define CRTC_ADDR               0x3d4
#define STATUS_ADDR             0x3da

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
                        inportb(STATUS_ADDR);           /* reset read/write flip-flop */
                        outportb(ATTRCON_ADDR, r.index | 0x20);
                                                                                /* ensure VGA output is enabled */
                        outportb(ATTRCON_ADDR, r.value);
                        break;

                case MISC_ADDR:
                case VGAENABLE_ADDR:
                        outportb(r.port, r.value);      /*      directly to the port */
                        break;

                case SEQ_ADDR:
                case GRACON_ADDR:
                case CRTC_ADDR:
                default:                                                /* This is the default method: */
                        outportb(r.port, r.index);      /*      index to port                      */
                        outportb(r.port+1, r.value);/*  value to port+1                    */
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

int frame = 0;

long pixi = 0;
long coli = 0;

byte modtab[256] = {0};
byte divtab[256] = {0};

byte a,b,c;

byte randoms[64000] = {0};
int rx = 0;
int randr = 0;

void init_rng(byte s1,byte s2,byte s3) //Can also be used to seed the rng with more entropy during use.
{
	//XOR new entropy into key state
	a ^=s1;
	b ^=s2;
	c ^=s3;

	rx++;
	a = (a^c^rx);
	b = (b+a);
	c = (c+(b>>1)^a);
}

byte randomize()
{
	rx++;               //x is incremented every round and is not affected by any other variable
	a = (a^c^rx);       //note the mix of addition and XOR
	b = (b+a);         //And the use of very few instructions
	c = (c+(b>>1)^a);  //the right shift is to ensure that high-order bits from b can affect  
	return(c);          //low order bits of other variables
}

void sampleVideo() 
{
        int x=0,y=0,x1=0,y1=0,skips=0,x2=0,y2=0;
        byte runcolor = 0, p1 = 0;

        for(y=0;y<256;y+=6) {
                for(x=0;x<256;x+=6) {
                        byte i1 = bufferpix[pixi];

					    if (i1 == 255) {
					    	pixi++;
					    	skips = bufferpix[pixi];
					        runcolor = buffercol[coli];
					    }

					    if (skips > 0) {
					    	i1 = randoms[randr++];
					    	if (randr > 64000) randr = 0;
					    	p1 = runcolor;
					    }

					    if (skips == 0) {
					    	p1 = buffercol[coli];
					    	coli++;
					    	pixi++;
					    }

					    if (skips > 0) {
					    	skips--;

					    	if (skips == 0) {
					    		coli++;
					    		pixi++;
					    	}
					    }

                        x2 = modtab[i1];
                        y2 = divtab[i1];

                        VGA[((y+y1+y2)<<8)+x+x2] = p1;
                        VGA[((y+y1+y2+1)<<8)+x+x2] = p1;
                        VGA[((y+y1+y2+3)<<8)+x+x2] = p1;
                        VGA[((y+y1+y2+4)<<8)+x+x2] = p1;
                        VGA[((y+y1+y2+6)<<8)+x+x2] = p1;
                        VGA[((y+y1+y2+7)<<8)+x+x2] = p1;

                }
        }

        if (frame > 10020) { frame = 0; pixi = 0; coli = 0; }
}

int main(int argc, char *argv[]) 
{
        int ii = 0;
        FILE *vfile;
        FILE *cfile;
        long lsize;
        size_t result;

        char ch;

        for (ii=0;ii<256;ii++) {
                modtab[ii] = (byte)(ii % 6);
                divtab[ii] = (byte)(ii / 6);
        }


		init_rng(1,2,3);

        for (ii=0;ii<64000;ii++) {
        	randoms[ii] = randomize()>>1;
        }
        
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

            while ((inp(INPUT_STATUS_1) & VRETRACE));
            while (!(inp(INPUT_STATUS_1) & VRETRACE));

                frame++;
        }

        quit("Have a nice day.");
        return 0;
}
