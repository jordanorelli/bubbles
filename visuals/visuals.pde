import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress outbound;

PFont font;
float minFreq = 110;
float maxFreq = 1760;
int maxNoteAge = 20;
boolean controlDown = false; // I don't know if this is necessary...

static final int normalMode = 0;
static final int exMode = 1;
int currentMode = normalMode;
char[] exBuffer = new char[200];
int exIndex = 0;

ArrayList queued; // notes that have been added, but have not yet been drawn.
ArrayList active; // notes that are currently active.

ArrayList mouseQueue; 
ArrayList mouseActive;

color colorFromFreq(float freq) {
  colorMode(HSB, 100);
  return color(map(freq, minFreq, maxFreq, 0, 100), 100, 100);
}

void setup() {
  size(1440, 900);
  frameRate(30);
  smooth();
  font = loadFont("Inconsolata-16.vlw");
  textFont(font, 14);
  oscP5 = new OscP5(this, 9000);
  outbound = new NetAddress("127.0.0.1", 9001);
  oscP5.plug(this, "receiveNote", "/noteOn");
  oscP5.plug(this, "mouseNote", "/mouseNote");
  queued = new ArrayList();
  active = new ArrayList();
  mouseQueue = new ArrayList();
  mouseActive = new ArrayList();
  background(0);
}

void mousePressed() {
  if(mouseButton == LEFT) {
    OscMessage m = new OscMessage("/mousePressed");    
    m.add(norm(mouseX, 0, width));
    m.add(norm(mouseY, 0, height));
    oscP5.send(m, outbound);
  }
}

void mouseReleased() {
  OscMessage m = new OscMessage("/mouseReleased");
  m.add(1);
  oscP5.send(m, outbound);
}

void mouseDragged() {
  OscMessage m = new OscMessage("/mouseDragged");    
  m.add(norm(mouseX, 0, width));
  m.add(norm(mouseY, 0, height));
  oscP5.send(m, outbound);
}

void draw(){
  background(0);
  if(mousePressed) {
    noCursor();
  } else {
    cursor(CROSS);
  }

  // add all the queed items.
  for(int i = queued.size() - 1; i >=0; i--) {
    active.add(queued.get(i));
    queued.remove(i);
  }

  // update all the existing items
  for(int i = active.size() - 1; i >= 0; i--) {
    Note note = (Note)active.get(i);
    note.update();
    if(note.dead()) {
      active.remove(i);
    }
  }

  for(int i = mouseQueue.size() - 1; i >= 0; i--) {
    mouseActive.add(mouseQueue.get(i));
    mouseQueue.remove(i);
  }

  for(int i = mouseActive.size() - 1; i >= 0; i--) {
    MouseNote note = (MouseNote)mouseActive.get(i);
    note.update();
    if(note.dead()) {
      mouseActive.remove(i);
    }
  }

  renderExBuffer();
}

void oscEvent(OscMessage m) {
  if(!m.isPlugged()){
    println("unknown message received at " + m.addrPattern() + " with type " + m.typetag());
  }
}

void keyPressed() {
  switch(currentMode) {
    case exMode:
      exKey();
      break;
    case normalMode:
      normalKey();
      break;
  }
}

// triggered when a key is pressed while in normal mode
void normalKey() {
  switch(key) {
    case ESC:
      key = 0;
      break;
    case ':':
      currentMode = exMode;
      initExBuffer();
      break;
  }
}

void initExBuffer() {
  exBuffer = new char[200];
  exBuffer[0] = ':';
  exIndex = 1;
}

// triggered when a key is pressed while in exMode
void exKey() {
  if(key != CODED) {
    if(controlDown) {
      exCtrlKey();
      return;
    }

    switch(key) {
      case ESC:
        currentMode = normalMode;
        key = 0;
        return;
      case ENTER:
      case RETURN:
        currentMode = normalMode;
        return;
      case BACKSPACE:
      case DELETE:
        if(exIndex > 0 && exIndex < exBuffer.length) {
          exIndex = max(exIndex - 1, 1);
          exBuffer[exIndex] = '\0';
        }
        return;
    }

  } else {
    switch(keyCode) {
      case CONTROL:
        controlDown = true;
        return;
    }
  }
  exBuffer[exIndex] = key;
  exIndex++;
}

// triggered when a key is pressed in ex mode while control is held
void exCtrlKey() {
  switch(key) {
    case 'u':
      initExBuffer();
      return;
  }
}

void renderExBuffer() {
  if(currentMode == exMode) {
    textAlign(LEFT);
    text(exBuffer, 0, exBuffer.length - 1, 0, height - 6);
  }
}

public void receiveNote(float freq, float pan) {
  queued.add(new Note(freq, pan));
}

public void mouseNote(float freq, float pan) {
  mouseQueue.add(new MouseNote(freq, pan));
}
