import oscP5.*;
import netP5.*;

OscP5 oscP5;
NetAddress outbound;

PFont font;
float minFreq = 110;
float maxFreq = 1760;
float toneStep = pow(2, 1.0/12.0);
float toneHeight; // y-distance in the display between semitones
float[] validFreqs = new float[49];

int maxNoteAge = 20;
boolean controlDown = false; // I don't know if this is necessary...
boolean guide = false; // whether or not to show horizontal guide lines

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
  toneHeight = (float)height / (validFreqs.length - 1);
  println(height);
  println(validFreqs.length);
  println(toneHeight);

  for(int i = 0; i < 49; i++) {
    validFreqs[i] = minFreq * pow(toneStep, i);
  }

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
  drawGuides();

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

// clears the ex-mode command line.  It dangerously makes a 200-character
// buffer, which we could quite easily type off the end of.
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
        runExCommand(exBuffer);
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

// parses the ex-mode line command.  Takes in a raw character array, splits on
// whitespace, and finds applicable commands.
void runExCommand(char[] raw) {
  String s = new String(subset(raw, 1));
  String args[] = s.trim().split(" ");
  if (args[0].equals("set")) {
    runSetCommand(subset(args, 1));
  }
}

// dispatches whatever :set commands are used.
void runSetCommand(String[] args) {
  if(args.length < 1) {
    return;
  }
  if(args[0].equals("guide")) {
    setGuide();
  } else if(args[0].equals("noguide")) {
    clearGuide();
  } else {
    println("unknown SET arg: '" + args[0]);
  }
}

// turns on frequency guide lines
void setGuide() {
  guide = true;
}

// turns off frequency guide lines
void clearGuide() {
  guide = false;
}

// triggered when a key is pressed in ex mode while control is held
void exCtrlKey() {
  switch(key) {
    case 'u':
      initExBuffer();
      return;
  }
}

// writes out the current ex-mode command line, if currently in ex mode.
void renderExBuffer() {
  if(currentMode == exMode) {
    textAlign(LEFT);
    text(exBuffer, 0, exBuffer.length - 1, 0, height - 6);
  }
}

void drawGuides() {
  if(guide) {
    stroke(40);
    strokeWeight(2);
    for(int i = 0; i < validFreqs.length; i++) {
      line(0, freqHeight(i), width, freqHeight(i));
    }
    float y = freqHeight(nearestNote());
    stroke(200);
    strokeWeight(3);
    line(0, y, width, y);
  }
}

float freqHeight(int freqNum) {
  return height - (toneHeight * freqNum);
}

int nearestNote() {
  return round(map(mouseY, 0, height, validFreqs.length, 0));
}

// handles the processing of OSC messages from the ChucK end of things.  These
// particular messages represent the notes from the acommpaniment, which I'll
// probably remove.
public void receiveNote(float freq, float pan) {
  queued.add(new Note(freq, pan));
}

// handles the processing of OSC message from ChucK.  These particular messages
// represent the notes that follow the mouse movement.
public void mouseNote(int toneNumber, float pan) {
  mouseQueue.add(new MouseNote(toneNumber, pan));
}
