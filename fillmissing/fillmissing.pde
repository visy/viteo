import processing.video.*;
import java.nio.file.*;
import java.io.*;
import static java.nio.file.StandardOpenOption.*;
 
void fwrite(String filename, byte[] data, boolean append){
  Path file = Paths.get(filename);
  OutputStream output = null;
    try
    {
      if(append){
        output = new BufferedOutputStream(Files.newOutputStream(file, APPEND));
      }
      else{
        output = new BufferedOutputStream(Files.newOutputStream(file, CREATE));
      }
      output.write(data);
      output.flush();
      output.close();
    }
    catch(Exception e)
    {
        System.out.println("Message: " + e);
    }
}

PGraphics source;
PGraphics sparse;
PGraphics filled;

PImage test;

Movie viteo;

int[] vgacolors_RGB = {
0,0,0,0,2,170,20,170,0,0,170,170,170,0,3,170,0,170,170,85,0,170,170,170,85,85,85,85,85,255,85,255,85,85,255,255,255,85,85,253,85,255,255,255,85,255,255,255,0,0,0,16,16,16,32,32,32,53,53,53,69,69,69,85,85,85,101,101,101,117,117,117,138,138,138,154,154,154,170,170,170,186,186,186,202,202,202,223,223,223,239,239,239,255,255,255,0,4,255,65,4,255,130,3,255,190,2,255,253,0,255,254,0,190,255,0,130,255,0,65,255,0,8,255,65,5,255,130,0,255,190,0,255,255,0,190,255,0,130,255,0,65,255,1,36,255,0,34,255,66,29,255,130,18,255,190,0,255,255,0,190,255,1,130,255,0,65,255,130,130,255,158,130,255,190,130,255,223,130,255,253,130,255,254,130,223,255,130,190,255,130,158,255,130,130,255,158,130,255,190,130,255,223,130,255,255,130,223,255,130,190,255,130,158,255,130,130,255,130,130,255,158,130,255,190,130,255,223,130,255,255,130,223,255,130,190,255,130,158,255,186,186,255,202,186,255,223,186,255,239,186,255,254,186,255,254,186,239,255,186,223,255,186,202,255,186,186,255,202,186,255,223,186,255,239,186,255,255,186,239,255,186,223,255,186,202,255,187,186,255,186,186,255,202,186,255,223,186,255,239,186,255,255,186,239,255,186,223,255,186,202,255,1,1,113,28,1,113,57,1,113,85,0,113,113,0,113,113,0,85,113,0,57,113,0,28,113,0,1,113,28,1,113,57,0,113,85,0,113,113,0,85,113,0,57,113,0,28,113,0,9,113,0,9,113,28,6,113,57,3,113,85,0,113,113,0,85,113,0,57,113,0,28,113,57,57,113,69,57,113,85,57,113,97,57,113,113,57,113,113,57,97,113,57,85,113,57,69,113,57,57,113,69,57,113,85,57,113,97,57,113,113,57,97,113,57,85,113,57,69,113,58,57,113,57,57,113,69,57,113,85,57,113,97,57,113,113,57,97,113,57,85,113,57,69,114,81,81,113,89,81,113,97,81,113,105,81,113,113,81,113,113,81,105,113,81,97,113,81,89,113,81,81,113,89,81,113,97,81,113,105,81,113,113,81,105,113,81,97,113,81,89,113,81,81,113,81,81,113,90,81,113,97,81,113,105,81,113,113,81,105,113,81,97,113,81,89,113,0,0,66,17,0,65,32,0,65,49,0,65,65,0,65,65,0,50,65,0,32,65,0,16,65,0,0,65,16,0,65,32,0,65,49,0,65,65,0,49,65,0,32,65,0,16,65,0,3,65,0,3,65,16,2,65,32,1,65,49,0,65,65,0,49,65,0,32,65,0,16,65,32,32,65,40,32,65,49,32,65,57,32,65,65,32,65,65,32,57,65,32,49,65,32,40,65,32,32,65,40,32,65,49,32,65,57,33,65,65,32,57,65,32,49,65,32,40,65,32,32,65,32,32,65,40,32,65,49,32,65,57,32,65,65,32,57,65,32,49,65,32,40,65,45,45,65,49,45,65,53,45,65,61,45,65,65,45,65,65,45,61,65,45,53,65,45,49,65,45,45,65,49,45,65,53,45,65,61,45,65,65,45,61,65,45,53,65,45,49,65,45,45,65,45,45,65,49,45,65,53,45,65,61,45,65,65,45,61,65,45,53,65,45,49,65,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
};

int[] colortab = new int[256*3*4];
int[] sparsepixels = new int[256*3*4];

int xs = 0;
int sqs = 8;

float colorDistance(color a, color b) 
{
  float redDiff = red(a) - red(b);
  float grnDiff = green(a) - green(b);
  float bluDiff = blue(a) - blue(b);

  return sqrt( sq(redDiff) + sq(grnDiff) + sq(bluDiff) );
} 

color getVGAColor(int i) {
  color c = color(vgacolors_RGB[i*3],vgacolors_RGB[(i*3)+1],vgacolors_RGB[(i*3)+2]);
  return c;
}

int getClosestVGAColorIndex(color c) {
  float dist = 100000.0f;
  int currentBest = 0;
  for (int i = 0; i < 255; i++) {
    color compColor = getVGAColor(i);
    float distToVga = colorDistance(c, compColor);
    
    if (distToVga < dist) { 
      dist = distToVga;
      currentBest = i;
    }
  }
  
  return currentBest;
}


color getClosestVGAColor(color c) {
  return getVGAColor(getClosestVGAColorIndex(c));
}

void sampleSparse() {
  int x,y,i = 0;

  for (int ii=0;ii<256*3*4;ii++) {
    colortab[ii] = 0;
    sparsepixels[ii] = 0;
  }


//  xs++;
  if (xs > 4) xs = 0;
  
  for (y = 0; y < 256; y+=sqs) {
    for (x = 0; x < 256; x+=sqs) {
      
      IntList il = IntList.fromRange(0, 255);
      il.shuffle(this);

      int i1 = il.get(0);
      int i2 = il.get(1);
      int i3 = il.get(2);

      color p1 = source.get(x+xs + i1 % sqs, y+xs + i1 / sqs); 
      color p2 = source.get(x+xs + i2 % sqs, y+xs + i2 / sqs); 
      color p3 = source.get(x+xs + i3 % sqs, y+xs + i3 / sqs); 
      
      sparse.set(x+xs + i1 % sqs, y+xs + i1 / sqs,p1);
      sparse.set(x+xs + i2 % sqs, y+xs + i2 / sqs,p2);
      sparse.set(x+xs + i3 % sqs, y+xs + i3 / sqs,p3);
      
      colortab[i] = getClosestVGAColorIndex(p1);      
      colortab[i+1] = getClosestVGAColorIndex(p2);      
      colortab[i+2] = getClosestVGAColorIndex(p3);
      
      sparsepixels[i] = i1;
      sparsepixels[i+1] = i2;
      sparsepixels[i+2] = i3;
      
      i+=3;
    }
  }
}

boolean sampled = false;

void sampleFilled() {
  int x,y,i=0;

  // decomp sparse pixel data to empty buffer
  for (y = 0; y < 256; y+=sqs) {
    for (x = 0; x < 256; x+=sqs) {
      
      int i1 = sparsepixels[i];
      int i2 = sparsepixels[i+1];
      int i3 = sparsepixels[i+2];

      color p1 = getVGAColor(colortab[i]); 
      color p2 = getVGAColor(colortab[i+1]); 
      color p3 = getVGAColor(colortab[i+2]); 
      
      for(int y1 = 0; y1 < sqs;y1+=1) {
        for(int x1 = 0; x1 < sqs;x1+=1) {

          int x2 = i1%sqs;
          int y2 = i1/sqs;
          int x3 = i2%sqs;
          int y3 = i2/sqs;
          int x4 = i3%sqs;
          int y4 = i3/sqs;

          int d1=(int)Math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));  
          int d2=(int)Math.sqrt((x3-x1)*(x3-x1) + (y3-y1)*(y3-y1));  
          int d3=(int)Math.sqrt((x4-x1)*(x4-x1) + (y4-y1)*(y4-y1));  

          if(d1 < d2 && d1 < d3)
          {
            filled.set(x+x1+x2,y+y1+y2,p1);
          }
          else if(d2 < d3)
          {
            filled.set(x+x1+x3,y+y1+y3,p2);
          }
          else
          {
            filled.set(x+x1+x4,y+y1+y4,p3);
          }  
        }
      }

      i+=3;
    }
  }

}

void setup() {
  size(256,256);

  source = createGraphics(256,256);
  sparse = createGraphics(256,256);
  filled = createGraphics(256,256);
  
  test = loadImage("256test.png");
  
  background(0,0);

  Path file = Paths.get(dataPath("vpix.dat"));
  
  File f = new File(dataPath("vpix.dat"));
  if (f.exists()) {
    f.delete();
  }
  
  OutputStream output = null;
  try {
    output = new BufferedOutputStream(Files.newOutputStream(file, CREATE));
    output.flush();
    output.close();
  } catch(Exception e) {
    System.out.println("Message: " + e);
  }

  Path file2 = Paths.get(dataPath("vcol.dat"));
  
  File f2 = new File(dataPath("vcol.dat"));
  if (f2.exists()) {
    f2.delete();
  }
  
  OutputStream output2 = null;
  try {
    output2 = new BufferedOutputStream(Files.newOutputStream(file2, CREATE));
    output2.flush();
    output2.close();
  } catch(Exception e) {
    System.out.println("Message: " + e);
  }

  frameRate(15);
  
  viteo = new Movie(this, "viteo.mp4");
  viteo.play();
}


int xsd = 0;
int ff = 0;

void movieEvent(Movie m) {
  m.read();
}

void dumpFrameData() {
  byte[] pix = new byte[256*3*4];
  byte[] cols = new byte[256*3*4];
  
  for (int i=0;i<256*3*4;i++) {
    pix[i] = (byte)sparsepixels[i];
    cols[i] = (byte)colortab[i];
  }

  fwrite(dataPath("vpix.dat"),pix,true);
  fwrite(dataPath("vcol.dat"),cols,true);
}

void draw() {

  source.beginDraw();
  source.pushMatrix();
  source.scale(0.4);
  source.background(0);
  source.image(viteo,-300,0);
  source.popMatrix();
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

  tint(255,255);
  image(filled,0,0,256,256);

  ff++;
  if (ff < 400) {
    dumpFrameData();
  } else {
    stop();
  }
}
