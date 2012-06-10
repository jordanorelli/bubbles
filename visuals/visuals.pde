import oscP5.*;
import netP5.*;

PGraphics pg;
OscP5 oscP5;
NetAddress inbound;
float minFreq = 140;
float maxFreq = 1600;
float[] notes;

void setup() {
  size(800, 600);
  oscP5 = new OscP5(this, 9000);
  oscP5.plug(this, "getNote", "/noteOn");
  background(0);
  pg = createGraphics(width, height, JAVA2D);
}

void draw() {
}

void oscEvent(OscMessage m) {
  if(!m.isPlugged()){
    println("unknown message received at " + m.addrPattern() + " with type " + m.typetag());
  }
}

public void getNote(float freq, float pan) {
  float x = map(pan, -1.0, 1.0, 0, width);
  float y = map(freq, 140, 1600, 0, height);
  pg.beginDraw();
  pg.background(0);
  pg.stroke(255);
  pg.strokeWeight(4);
  pg.ellipse(x, y, 20, 20);
  pg.endDraw();
  image(pg, 0, 0);
}
