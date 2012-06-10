import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress inbound;
float minFreq = 140;
float maxFreq = 1600;
int maxNoteAge = 50;

ArrayList queued; // notes that have been added, but have not yet been drawn.
ArrayList active; // notes that are currently active.

class Note {
  float freq, pan, x, y;
  int age;
  
  Note(float f, float p) {
    age = 0;
    freq = f;
    pan = p;
    x = map(p, -1.0, 1.0, 0, width);
    y = map(f, minFreq, maxFreq, 0, height);
  }
  
  void update() {
    noFill();
    stroke(255, map(age, 0, maxNoteAge, 255, 0));
    strokeWeight(4);
    float d = map(age, 0, maxNoteAge, 20, 400);
    ellipse(x, y, d, d);
    age++;
  }
  
  boolean dead() {
    return age >= maxNoteAge;
  }
}

void setup() {
  smooth();
  size(800, 600);
  oscP5 = new OscP5(this, 9000);
  oscP5.plug(this, "receiveNote", "/noteOn");
  queued = new ArrayList();
  active = new ArrayList();
  background(0);
}

void draw() {
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
