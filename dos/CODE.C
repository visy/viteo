#include"code.h"
#include"key.h"

long numCodeWords=0;
CODE codeWord[MAXCODES];

char checkCode(char *codeBuf)
 {
 long i,j,c,ctr;
 for(c=0;c<numCodeWords;c++)
  {
  for(j=0;j<16;j++)
   {
   ctr=j;
   for(i=0;i<codeWord[c].numBytes;i++)
    {
    if(codeWord[c].code[i]!=codeBuf[ctr])break;
    ctr++;if(ctr>=16)ctr=0;
    }
   if(i==codeWord[c].numBytes)
    {
    for(ctr=0;ctr<16;ctr++){codeBuf[ctr]=0;}
    return codeWord[c].returnCode;
    }
   }
  }
 return CODE_NONE;
 }

void setCodes(void)
 {
 long i;
 numCodeWords=0;
 
 i=0;
 codeWord[numCodeWords].returnCode=CODE_SCAN;
 codeWord[numCodeWords].code[i++]=KEY_S;
 codeWord[numCodeWords].code[i++]=KEY_C;
 codeWord[numCodeWords].code[i++]=KEY_A;
 codeWord[numCodeWords].code[i++]=KEY_N;
 codeWord[numCodeWords].numBytes=i;
 numCodeWords++;
 
 i=0;
 codeWord[numCodeWords].returnCode=CODE_NAME;
 codeWord[numCodeWords].code[i++]=KEY_N;
 codeWord[numCodeWords].code[i++]=KEY_A;
 codeWord[numCodeWords].code[i++]=KEY_M;
 codeWord[numCodeWords].code[i++]=KEY_E;
 codeWord[numCodeWords].numBytes=i;
 numCodeWords++;

 i=0;
 codeWord[numCodeWords].returnCode=CODE_SPACESINGLE;
 codeWord[numCodeWords].code[i++]=KEY_S;
 codeWord[numCodeWords].code[i++]=KEY_P;
 codeWord[numCodeWords].code[i++]=KEY_A;
 codeWord[numCodeWords].code[i++]=KEY_C;
 codeWord[numCodeWords].code[i++]=KEY_E;
 codeWord[numCodeWords].numBytes=i;
 numCodeWords++;
 
 }
