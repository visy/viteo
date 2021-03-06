import processing.video.*;
import java.nio.file.*;
import java.io.*;
import static java.nio.file.StandardOpenOption.*;

void fwrite(String filename, byte[] data, boolean append) {
  Path file = Paths.get(filename);
  OutputStream output = null;
  try
  {
    if (append) {
      output = new BufferedOutputStream(Files.newOutputStream(file, APPEND));
    } else {
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

PGraphics prevsource;
PGraphics source;
PGraphics sparse;
PGraphics filled;

PImage test;

Movie viteo;
//Capture viteo;

int[] vgacolors_RGB = {
  0, 0, 0, 0, 2, 170, 20, 170, 0, 0, 170, 170, 170, 0, 3, 170, 0, 170, 170, 85, 0, 170, 170, 170, 85, 85, 85, 85, 85, 255, 85, 255, 85, 85, 255, 255, 255, 85, 85, 253, 85, 255, 255, 255, 85, 255, 255, 255, 0, 0, 0, 16, 16, 16, 32, 32, 32, 53, 53, 53, 69, 69, 69, 85, 85, 85, 101, 101, 101, 117, 117, 117, 138, 138, 138, 154, 154, 154, 170, 170, 170, 186, 186, 186, 202, 202, 202, 223, 223, 223, 239, 239, 239, 255, 255, 255, 0, 4, 255, 65, 4, 255, 130, 3, 255, 190, 2, 255, 253, 0, 255, 254, 0, 190, 255, 0, 130, 255, 0, 65, 255, 0, 8, 255, 65, 5, 255, 130, 0, 255, 190, 0, 255, 255, 0, 190, 255, 0, 130, 255, 0, 65, 255, 1, 36, 255, 0, 34, 255, 66, 29, 255, 130, 18, 255, 190, 0, 255, 255, 0, 190, 255, 1, 130, 255, 0, 65, 255, 130, 130, 255, 158, 130, 255, 190, 130, 255, 223, 130, 255, 253, 130, 255, 254, 130, 223, 255, 130, 190, 255, 130, 158, 255, 130, 130, 255, 158, 130, 255, 190, 130, 255, 223, 130, 255, 255, 130, 223, 255, 130, 190, 255, 130, 158, 255, 130, 130, 255, 130, 130, 255, 158, 130, 255, 190, 130, 255, 223, 130, 255, 255, 130, 223, 255, 130, 190, 255, 130, 158, 255, 186, 186, 255, 202, 186, 255, 223, 186, 255, 239, 186, 255, 254, 186, 255, 254, 186, 239, 255, 186, 223, 255, 186, 202, 255, 186, 186, 255, 202, 186, 255, 223, 186, 255, 239, 186, 255, 255, 186, 239, 255, 186, 223, 255, 186, 202, 255, 187, 186, 255, 186, 186, 255, 202, 186, 255, 223, 186, 255, 239, 186, 255, 255, 186, 239, 255, 186, 223, 255, 186, 202, 255, 1, 1, 113, 28, 1, 113, 57, 1, 113, 85, 0, 113, 113, 0, 113, 113, 0, 85, 113, 0, 57, 113, 0, 28, 113, 0, 1, 113, 28, 1, 113, 57, 0, 113, 85, 0, 113, 113, 0, 85, 113, 0, 57, 113, 0, 28, 113, 0, 9, 113, 0, 9, 113, 28, 6, 113, 57, 3, 113, 85, 0, 113, 113, 0, 85, 113, 0, 57, 113, 0, 28, 113, 57, 57, 113, 69, 57, 113, 85, 57, 113, 97, 57, 113, 113, 57, 113, 113, 57, 97, 113, 57, 85, 113, 57, 69, 113, 57, 57, 113, 69, 57, 113, 85, 57, 113, 97, 57, 113, 113, 57, 97, 113, 57, 85, 113, 57, 69, 113, 58, 57, 113, 57, 57, 113, 69, 57, 113, 85, 57, 113, 97, 57, 113, 113, 57, 97, 113, 57, 85, 113, 57, 69, 114, 81, 81, 113, 89, 81, 113, 97, 81, 113, 105, 81, 113, 113, 81, 113, 113, 81, 105, 113, 81, 97, 113, 81, 89, 113, 81, 81, 113, 89, 81, 113, 97, 81, 113, 105, 81, 113, 113, 81, 105, 113, 81, 97, 113, 81, 89, 113, 81, 81, 113, 81, 81, 113, 90, 81, 113, 97, 81, 113, 105, 81, 113, 113, 81, 105, 113, 81, 97, 113, 81, 89, 113, 0, 0, 66, 17, 0, 65, 32, 0, 65, 49, 0, 65, 65, 0, 65, 65, 0, 50, 65, 0, 32, 65, 0, 16, 65, 0, 0, 65, 16, 0, 65, 32, 0, 65, 49, 0, 65, 65, 0, 49, 65, 0, 32, 65, 0, 16, 65, 0, 3, 65, 0, 3, 65, 16, 2, 65, 32, 1, 65, 49, 0, 65, 65, 0, 49, 65, 0, 32, 65, 0, 16, 65, 32, 32, 65, 40, 32, 65, 49, 32, 65, 57, 32, 65, 65, 32, 65, 65, 32, 57, 65, 32, 49, 65, 32, 40, 65, 32, 32, 65, 40, 32, 65, 49, 32, 65, 57, 33, 65, 65, 32, 57, 65, 32, 49, 65, 32, 40, 65, 32, 32, 65, 32, 32, 65, 40, 32, 65, 49, 32, 65, 57, 32, 65, 65, 32, 57, 65, 32, 49, 65, 32, 40, 65, 45, 45, 65, 49, 45, 65, 53, 45, 65, 61, 45, 65, 65, 45, 65, 65, 45, 61, 65, 45, 53, 65, 45, 49, 65, 45, 45, 65, 49, 45, 65, 53, 45, 65, 61, 45, 65, 65, 45, 61, 65, 45, 53, 65, 45, 49, 65, 45, 45, 65, 45, 45, 65, 49, 45, 65, 53, 45, 65, 61, 45, 65, 65, 45, 61, 65, 45, 53, 65, 45, 49, 65, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};

static int framesize = 256*4*4; 
int truepixsize = 2;
int truecolsize = 2;

int[] colortab = new int[framesize];
int[] sparsepixels = new int[framesize];

int[] prevcolortab = new int[framesize];

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
  color c = color(vgacolors_RGB[i*3], vgacolors_RGB[(i*3)+1], vgacolors_RGB[(i*3)+2]);
  return c;
}

int palrot = 0;
int getClosestVGAColorIndex(color c) {
  float dist = 1000000.0f;
  int currentBest = 0;
  for (int i = 0; i <= 253; i++) {
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


int arearandomness(int x, int y) {
  float sum = 0.0f;

  float pr=0.0f, pg=0.0f, pb=0.0f;

  int samples = 0;
  for (int yy = y-sqs; yy<y+sqs; yy++) {
    for (int xx = x-sqs; xx<x+sqs; xx++) {
      color c = source.get(x, y);
      float r = red(c);
      float g = green(c);
      float b = blue(c);

      float rdiff = abs(r-pr); 
      float gdiff = abs(g-pg); 
      float bdiff = abs(b-pb); 

      float sdiff = (rdiff+gdiff+bdiff) / 3.0f;

      sum += sdiff;
      samples++;
      pr = r;
      pg = g;
      pb = b;
    }
  }

  int ret = int((sum / (float)(samples))*226.0f);

  return (255-(ret&255))-5;
}



void sampleSparse() {
  int x, y, i = 0;
  int ppixi = 0;
  int pcoli = 0;
  int skips=-1;
  int runcolor = 0;

  for (int ii=0; ii<framesize; ii++) {
    colortab[ii] = 0;
    sparsepixels[ii] = 0;

    prevcolortab[ii] = 0;
  }


  //  xs++;
  if (xs > 4) xs = 0;

  color prevp1 = color(0, 0, 0);
  int skippedtotal = 0;
  int i1 = 0;
  for (y = 0; y < 256; y+=sqs) {
    for (x = 0; x < 256; x+=sqs) {
      IntList il = IntList.fromRange(0, 253);
      il.shuffle(this);

      int i2 = i1;
      i1 = il.get(0);

      color p1 = source.get((x+xs + i1 % sqs)&255, (y+xs + i1 / sqs)&255); 

      int c = getClosestVGAColorIndex(p1);      
      color vgacol = getVGAColor(c);

      sparsepixels[ppixi] = i1;
      colortab[pcoli] = c;

      ppixi++;
      pcoli++;

//      sparse.fill(vgacol);
//      sparse.rect(x+xs + i1 % sqs, y+xs + i1 / sqs, sqs, sqs);
    }
  }

  sparsepixels[ppixi] = 254;

  truepixsize = 1024;
  truecolsize = 1024;
}

boolean sampled = false;

int coli = 0;
int pixi = 0;

int lastp=0;
int lastc=0;

void sampleFilled() {
  int x, y, i=0;
  int laste = 0;
  int skips = 0;
  int runcolor = 0;
  // decomp sparse pixel data to empty buffer
  int i1 = 0;
  pixi = lastp+1024;
  coli = lastc+1024;
  lastp = pixi;
  lastc = coli;
  for (y = 0; y < 256; y+=sqs) {


    for (x = 0; x < 256; x+=sqs) {
      if ((pixdata[pixi+1] & 0xFF) == 254) {
        pixi+=2;
        return;
      }

      i1 = pixdata[pixi] & 0xFF;
      if (i1 == 255 && skips == 0) {


        pixi++;

        skips = pixdata[pixi] & 0xFF;
        runcolor = coldata[coli] & 0xFF;
      }

      color p1 = color(0, 0, 0);

      if (skips > 0) {
        IntList il = IntList.fromRange(0, 64);
        il.shuffle(this);

        i1 = (byte)il.get(0);

        p1 = getVGAColor(runcolor);
      } 


      if (skips == 0) {


        p1 = getVGAColor(coldata[coli] & 0xFF);
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

      int x2 = i1%sqs;
      int y2 = i1/sqs;

      filled.set(x+x2, y+0+y2, p1);
      filled.set(x+x2, y+1+y2, p1);
      filled.set(x+x2, y+3+y2, p1);
      filled.set(x+x2, y+4+y2, p1);
      filled.set(x+x2, y+6+y2, p1);
      filled.set(x+x2, y+7+y2, p1);
    }
  }
}

void createFile(String filename) {
  Path file = Paths.get(dataPath(filename));

  File f = new File(dataPath(filename));
  if (f.exists()) {
    f.delete();
  }

  OutputStream output = null;
  try {
    output = new BufferedOutputStream(Files.newOutputStream(file, CREATE));
    output.flush();
    output.close();
  } 
  catch(Exception e) {
    System.out.println("Message: " + e);
  }
}

void setup() {
  size(256, 256);

  prevsource = createGraphics(256, 256);
  source = createGraphics(256, 256);
  sparse = createGraphics(256, 256);
  filled = createGraphics(256, 256);

  prevsource.beginDraw();
  prevsource.background(0, 0, 0);
  prevsource.endDraw();

  test = loadImage("256test.png");

  background(0, 0);

  pixdata = new byte[0];
  coldata = new byte[0];

  createFile("vpix.dat");
  createFile("vcol.dat");
  createFile("vpixc.dat");
  createFile("vcolc.dat");

  frameRate(24);

  //String[] cameras = Capture.list();

  //viteo = new Capture(this, 256, 256);
  //viteo.start();
  
  viteo = new Movie(this,"pally.mp4");
  viteo.speed(1.0);
  viteo.play();  
}


int xsd = 0;
int ff = 0;

byte[] pix = new byte[truepixsize];
byte[] cols = new byte[truecolsize];

byte[] concatByteArray(byte[] a, byte[] b) {
  byte[] c = new byte[a.length + b.length];
  System.arraycopy(a, 0, c, 0, a.length);
  System.arraycopy(b, 0, c, a.length, b.length);
  return c;
}

byte[] pixdata;
byte[] coldata;

void dumpFrameData() {
  pix = null;
  cols = null;
  pix = new byte[truepixsize];
  cols = new byte[truecolsize];

  for (int i=0; i<truepixsize; i++) {
    pix[i] = (byte)sparsepixels[i];
  }

  for (int i=0; i<truecolsize; i++) {
    cols[i] = (byte)colortab[i];
  }

  pixdata = concatByteArray(pixdata, pix);
  coldata = concatByteArray(coldata, cols);


  fwrite(dataPath("vpix.dat"), pix, true);
  fwrite(dataPath("vcol.dat"), cols, true);


  println("frame " + ff + " wrote " + truepixsize + " of pixel, " + truecolsize + " of color data");
}

int delayframe = 2;

void draw() {
  if (viteo.available()) {
    viteo.read();
  }

  prevsource.beginDraw();
  prevsource.background(0, 0, 0);
  prevsource.image(source, 0, 0);
  prevsource.endDraw();

  source.beginDraw();
  source.pushMatrix();
  source.background(0, 0, 0);
  source.image(viteo, 0, 0);
  /*
  // floyd-steinberg
  source.loadPixels();
  
  for (int y=0;y<source.height;y++) {
    for (int x=0;x<source.width;x++) {
      color oldpixel = source.get(x,y);
      color newpixel = getVGAColor(getClosestVGAColorIndex(oldpixel));
      source.pixels[y*source.width+x] = newpixel;

      float qerr_red = red(oldpixel) - red(newpixel);
      float qerr_green = green(oldpixel) - green(newpixel);
      float qerr_blue = blue(oldpixel) - blue(newpixel);
      
      float new_s1_r = red(source.get(x+1,y)+int(qerr_red * 7. / 16.));
      float new_s1_g = green(source.get(x+1,y)+int(qerr_green * 7. / 16.));
      float new_s1_b = blue(source.get(x+1,y)+int(qerr_blue * 7. / 16.));

      float new_s2_r = red(source.get(x-1,y+1)+int(qerr_red * 3. / 16.));
      float new_s2_g = green(source.get(x-1,y+1)+int(qerr_green * 3. / 16.));
      float new_s2_b = blue(source.get(x-1,y+1)+int(qerr_blue * 3. / 16.));

      float new_s3_r = red(source.get(x,y+1)+int(qerr_red * 5. / 16.));
      float new_s3_g = green(source.get(x,y+1)+int(qerr_green * 5. / 16.));
      float new_s3_b = blue(source.get(x,y+1)+int(qerr_blue * 5. / 16.));

      float new_s4_r = red(source.get(x+1,y+1)+int(qerr_red * 1. / 16.));
      float new_s4_g = green(source.get(x+1,y+1)+int(qerr_green * 1. / 16.));
      float new_s4_b = blue(source.get(x+1,y+1)+int(qerr_blue * 1. / 16.));

      if (x+1 >= source.width || y+1 >= source.height) continue;

      source.pixels[y*source.width+(x+1)] = color(new_s1_r,new_s1_g,new_s1_b);
      source.pixels[(y+1)*source.width+(x-1)] = color(new_s2_r,new_s2_g,new_s2_b);
      source.pixels[(y+1)*source.width+x] = color(new_s3_r,new_s3_g,new_s3_b);
      source.pixels[(y+1)*source.width+(x+1)] = color(new_s4_r,new_s4_g,new_s4_b);

      
    }
  }

  source.updatePixels();
  */
  source.popMatrix();
  source.endDraw();

  sparse.beginDraw();
  sparse.background(0);

  sampleSparse();
  sparse.endDraw();

  if (ff >= 0 & ff <= 1000) {
    dumpFrameData();
  }

  if (ff == 1000) {
    fwrite(dataPath("vpixc.dat"), pixdata, true);
    fwrite(dataPath("vcolc.dat"), coldata, true);

    exit();
  }

  ff++;

  filled.beginDraw();
  filled.background(0, 0);
  if (delayframe == 0)
    sampleFilled();

  delayframe--;
  if (delayframe < 0) delayframe = 0;
  filled.endDraw();

  //image(sparse,0,0,256,256);

  tint(255, 255);
  image(filled, 0, 0, 256, 256);

  palrot++;
}
