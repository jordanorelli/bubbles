import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress inbound;
float minFreq = 140;
float maxFreq = 1600;
int maxNoteAge = 40;

ArrayList queued; // notes that have been added, but have not yet been drawn.
ArrayList active; // notes that are currently active.

color colorFromFreq(float freq) {
  colorMode(HSB, 100);
  return color(map(freq, minFreq, maxFreq, 0, 100), 100, 100);
}

class Note {
  float freq, pan, x, y, xorigin, phaseOffset, maxOscAngle, maxDiameter, maxStrokeWeight, oscAmp;
  int age;
  
  Note(float f, float p) {
    age = 0;
    freq = f;
    pan = p;
    x = map(p, -1.0, 1.0, 0, width);
    xorigin = x;
    y = height;
    phaseOffset = random(0, TWO_PI); // start each bubble with a randome phase.
    maxOscAngle = map(freq, minFreq, maxFreq, PI, 2 * PI); // higher notes oscillate more quickly
    maxDiameter = map(freq, minFreq, maxFreq, 400, 80); // lower notes make larger bubbles 
    maxStrokeWeight = map(freq, minFreq, maxFreq, 200, 20);
    oscAmp = map(freq, minFreq, maxFreq, 30, 300); // higher notes trace tighter waveforms
  }
  
  void updatePosition() {
    x = xorigin + oscAmp * sin(map(age, 0, maxNoteAge, 0, maxOscAngle) + phaseOffset);
    y = map(age, 0, maxNoteAge, height, 0);
  }
  
  void update() {
    updatePosition();
    noFill();
    stroke(colorFromFreq(freq), map(age, 0, maxNoteAge, 100, 0));
    strokeWeight(map(age, 0, maxNoteAge, 4, maxStrokeWeight));
    float d = map(age, 0, maxNoteAge, 20, maxDiameter);
    ellipse(x, y, d, d);
    age++;
  }
  
  boolean dead() {
    return age >= maxNoteAge;
  }
}

void setup() {
  size(1440, 900);
  oscP5 = new OscP5(this, 9000);
  oscP5.plug(this, "receiveNote", "/noteOn");
  queued = new ArrayList();
  active = new ArrayList();
  background(0);
}

void draw(){
  background(0);

  // add all the queed items.
  for(int i = 0; i < queued.size(); i++) {
    active.add(queued.get(i));
    queued.remove(i);
  }

  // update all the existing items
  for(int i = 0; i < active.size(); i++) {
    Note note = (Note)active.get(i);
    note.update();
    if(note.dead()) {
      active.remove(i);
    }
  }
}

void oscEvent(OscMessage m) {
  if(!m.isPlugged()){
    println("unknown message received at " + m.addrPattern() + " with type " + m.typetag());
  }
}

public void receiveNote(float freq, float pan) {
  queued.add(new Note(freq, pan));
}
