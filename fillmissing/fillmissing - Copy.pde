PGraphics source;
PGraphics sparse;
PGraphics filled;

PImage test;

color[] colortab = new color[256*16];
int[] sparsepixels = new int[256*16];

int xs = 0;
void sampleSparse() {
  int x,y,i = 0;
  
  colortab = null;
  colortab = new color[256*3];

  sparsepixels = null;
  sparsepixels = new int[256*3];

  xs++;
  if (xs > 4) xs = 0;
  
  for (y = 0; y < 256; y+=16) {
    for (x = 0; x < 256; x+=16) {
      
      IntList il = IntList.fromRange(0, 255);
      il.shuffle(this);

      int i1 = il.get(0);
      int i2 = il.get(1);
      int i3 = il.get(2);

      color p1 = source.get(x+xs + i1 % 16, y+xs + i1 / 16); 
      color p2 = source.get(x+xs + i2 % 16, y+xs + i2 / 16); 
      color p3 = source.get(x+xs + i3 % 16, y+xs + i3 / 16); 
      
      sparse.set(x+xs + i1 % 16, y+xs + i1 / 16,p1);
      sparse.set(x+xs + i2 % 16, y+xs + i2 / 16,p2);
      sparse.set(x+xs + i3 % 16, y+xs + i3 / 16,p3);
      
      colortab[i] = p1;      
      colortab[i+1] = p2;      
      colortab[i+2] = p3;
      
      sparsepixels[i] = i1;
      sparsepixels[i+1] = i2;
      sparsepixels[i+2] = i3;
      
      i+=3;
    }
  }
}

void sampleFilled() {
  int x,y,i=0;

  // decomp sparse pixel data to empty buffer
  for (y = 0; y < 256; y+=16) {
    for (x = 0; x < 256; x+=16) {
      
      int i1 = sparsepixels[i];
      int i2 = sparsepixels[i+1];
      int i3 = sparsepixels[i+2];

      color p1 = colortab[i]; 
      color p2 = colortab[i+1]; 
      color p3 = colortab[i+2]; 
      
      for(int y1 = y; y1 < y+16;y1+=4) {
        for(int x1 = x; x1 < x+16;x1+=2) {

          int x2 = i1%16;
          int y2 = i1/16;
          int x3 = i2%16;
          int y3 = i2/16;
          int x4 = i3%16;
          int y4 = i3/16;

          int d1=(int)Math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));  
          int d2=(int)Math.sqrt((x3-x1)*(x3-x1) + (y3-y1)*(y3-y1));  
          int d3=(int)Math.sqrt((x4-x1)*(x4-x1) + (y4-y1)*(y4-y1));  

          if(d1 < d2 && d1 < d3)
          {
            filled.set(x1,y1+i1/16,p1);
          }
          else if(d2 < d3)
          {
            filled.set(x1,y1+i2/16,p2);
          }
          else
          {
            filled.set(x1,y1+i3/16,p3);
          }  
        }
      }

            
      filled.set(x + i1 % 16, y + i1 / 16, p1);
      filled.set(x + i2 % 16, y + i2 / 16, p2);
      filled.set(x + i3 % 16, y + i3 / 16, p3);

      i+=3;
    }
  }

}

void setup() {
  size(512,256);

  source = createGraphics(256,256);
  sparse = createGraphics(256,256);
  filled = createGraphics(256,256);
  
  test = loadImage("256test.png");
  
  background(0,0);
  

}


int xsd = 0;

void draw() {

  source.beginDraw();
  source.background(0);
  
  source.image(test,0,0);
  source.endDraw();
  
  sparse.beginDraw();
  sparse.background(0);
  
  sampleSparse();
  sparse.endDraw();

  filled.beginDraw();
  filled.background(0,0);
  sampleFilled();
  filled.endDraw();

  //image(sparse,0,0,256,256);

  tint(255,32);
  xsd++;
  if (xsd > 4) xsd = 0;


  image(filled,256+xsd,0+xsd,256,256);
  tint(255,255);
  
  image(source,0,0,256,256);
}
