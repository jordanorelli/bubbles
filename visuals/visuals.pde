import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress inbound;
float minFreq = 140;
float maxFreq = 1600;
float[] notes;

void setup() {
  smooth();
  size(800, 600);
  oscP5 = new OscP5(this, 9000);
  oscP5.plug(this, "receiveNote", "/noteOn");
  background(0);
}

void draw() {
  noStroke();
  fill(0, 60);
  rect(0, 0, width, height);
}

void oscEvent(OscMessage m) {
  if(!m.isPlugged()){
    println("unknown message received at " + m.addrPattern() + " with type " + m.typetag());
  }
}

public void receiveNote(float freq, float pan) {
  float x = map(pan, -1.0, 1.0, 0, width);
  float y = map(freq, 140, 1600, 0, height);
  noStroke();
  fill(255);
  ellipse(x, y, 20, 20);
}
