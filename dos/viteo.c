#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <dos.h>
#include <mem.h>
#include <i86.h>
#include "midasdll.h"

typedef struct
{
        unsigned port;
        unsigned char index;
        unsigned char value;
} Register;

typedef Register *RegisterPtr;

#include "mode1.h"
#include "mode2.h"
#include "key.h"

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


MIDASmodule module;                     /* Der Module */
MIDASmodulePlayHandle playHandle;       /* Das Playing Handle */

char *moduleName = "music.xm";
unsigned        position;               /* Current position */
unsigned        pattern;                /* Current pattern number */
unsigned        row;                    /* Current row number */
int             syncInfo;               /* Music synchronization info */


// video data buffers   
byte *bufferpix;
byte *buffercol;

unsigned long frame = 0;
unsigned long tick = 0;

unsigned long pixi = 0;
unsigned long coli = 0;

unsigned long plast = 0;
unsigned long clast = 0;

byte modtab[256] = {0};
byte divtab[256] = {0};
int shift8tab[256] = {0};

byte a,b,c;

byte randoms[64000] = {0};
int rx = 0;
int randr = 0;

int loopdata[16] = {
	0,359,
	0,
	359,
	61,
	120,
	122,
	180,
	65535,65535
};

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

long prevframe, startframe;

void sampleVideo() 
{
        int x=0,y=0,x1=0,y1=0,x2=0,y2=0,skips =0,x3,yy;
        byte runcolor = 0, p1 = 0, i1,ra;
        unsigned long pi,co;

        //if (prevframe == frame) return;

        startframe = frame;

        pi = pixi;
        co = coli;

        ra = randoms[tick]>>4;
        for(y=0;y<256;y+=8) {
                if (frame > startframe) { return; }
                for(x=0;x<256;x+=8) {
                        i1 = bufferpix[pi];

                        p1 = buffercol[co];
                        co++;
                        pi++;

                        x2 = modtab[i1];
                        y2 = divtab[i1];

                        x3 = x+x2;
                        yy = y+y2;

                        VGA[((yy)<<8)+x3] = p1;
                        VGA[((yy+1)<<8)+x3] = p1;

                        VGA[((yy+3)<<8)+x3] = p1;
                        VGA[((yy+4)<<8)+x3] = p1;

                        VGA[((yy+7)<<8)+x3] = p1;
                        VGA[((yy+8)<<8)+x3] = p1;
                }
        }

        prevframe = frame;
}

int fc = 0;
int loopindex = 0;
int loopspeed = 5;
int loopcount = 0;
int loopbreak = 0;
int looper = 1;
int ps = 4;

// for m in bpy.context.scene.timeline_markers: print(m.frame)

unsigned prevSyncNum = 0xFF;

void MIDAS_CALL prevr(void)
{
	tick++;

	if (prevframe > frame) {
		int prevdiff = prevframe-frame;
		pixi=plast+1024*prevdiff*ps;
		coli=clast+1024*prevdiff*ps;

		frame+=prevdiff*ps;
	} else {
		frame+=ps;
		pixi=plast+1024*ps;
		coli=clast+1024*ps;
	}

	if (looper == 1) {

		if (frame/loopspeed >= loopdata[loopindex+1] || frame/loopspeed < loopdata[loopindex+0]) {
			loopcount++;

			if (ps < 0)
				frame = loopdata[loopindex+1]*loopspeed;
			else
				frame = loopdata[loopindex]*loopspeed;

			pixi = frame*1024;
			coli = frame*1024;
		}

		if (loopbreak == 2) {
			//loopindex = ((randoms[prevSyncNum] % 3) *2) + 2;

			loopcount = 0;
			loopbreak = 0;
			frame = loopdata[loopindex]*loopspeed;
			prevframe = frame;
			pixi = frame*1024;
			coli = frame*1024;
			memset(VGA,0,64000);
		}
	}

	plast = pixi;
	clast = coli;
}

void MIDASerror(void)
{
    printf("MIDAS error: %s\n", MIDASgetErrorMessage(MIDASgetLastError()));
    MIDASclose();
    exit(EXIT_FAILURE);
}



void MIDAS_CALL UpdateInfo(void)
{
    /* MIDAS_CALL is cdecl for Watcom, empty for DJGPP. Helps calling this
       from assembler, otherwise unnecessary */
    
    static MIDASplayStatus status;

    /* Get playback status: */
    if ( !MIDASgetPlayStatus(playHandle, &status) )
        MIDASerror();

    /* Store interesting information in easy-to-access variables: */
    position = status.position;
    pattern = status.pattern;
    row = status.row;
    syncInfo = status.syncInfo;
}


int quitti = 0;

void MIDAS_CALL SyncCallback(unsigned syncNum, unsigned position, unsigned row)
{
    /* Prevent warnings: */
    position = position;
    row = row;

    if (syncNum != prevSyncNum) {
    	loopbreak = 1;
    	prevSyncNum = syncNum;
    }
}


int main(int argc, char *argv[]) 
{
        int ii = 0;
        FILE *vfile;
        FILE *cfile;
        long lsize;
        size_t result;
        unsigned char key;

        char ch;

        for (ii=0;ii<256;ii++) {
                modtab[ii] = (byte)(ii % 8);
                divtab[ii] = (byte)(ii / 8);
                shift8tab[ii] = (int)(ii<<8);
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

        MIDASstartup();

            if (!MIDASdetectSoundCard())
            {
                if ( !MIDASconfig() )
                {
                    if ( MIDASgetLastError() )
                    {
                        MIDASerror();
                    }
                    else
                    {
                        printf("User exit!\n");
                        return 1;
                    }
                }
            }

                if ( !MIDASinit() )
                    MIDASerror();

                if ( (module = MIDASloadModule(moduleName)) == NULL )
                MIDASerror();


       if ( !MIDASsetTimerCallbacks(70000, FALSE, &prevr, NULL, NULL) )
            MIDASerror();

        printf("Starting...\n");
        set_mode(0x13);
        set_mode_q();

        /* Start playing the module: */
        if ( (playHandle = MIDASplayModule(module, TRUE)) == 0 )
            MIDASerror();

            MIDASstartBackgroundPlay( 0 );

        /* Set the music synchronization callback function: */
        if ( !MIDASsetMusicSyncCallback(playHandle, &SyncCallback) )
            MIDASerror();

        installKeyboardHandler();

        while(quitti == 0) {
            sampleVideo();
            UpdateInfo();
            if (checkKey(KEY_UPARROW)) { ps+=2; if (ps > 16) { ps = 16; } }
            else if (checkKey(KEY_DOWNARROW)) { ps-=2; if (ps < -16) { ps = -16; } }
            else if (checkKey(KEY_ESC)) quitti = 1;
            clearKeys();
        }

            /* Remove music sync callback: */
            if ( !MIDASsetMusicSyncCallback(playHandle, NULL) )
                MIDASerror();
            
            /* Stop playing module: */
            if ( !MIDASstopModule(playHandle) )
                MIDASerror();

            /* Deallocate the module: */
            if ( !MIDASfreeModule(module) )
                MIDASerror();

            /* Remove timer callback: */
            if ( !MIDASremoveTimerCallbacks() )
                MIDASerror();

            /* And close MIDAS: */
            if ( !MIDASclose() )
                MIDASerror();

        quit("Have a nice day.");
        return 0;
}
