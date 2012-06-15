class Note {
  float freq;
  float pan;
  float x;
  float y;
  float xorigin;
  float phaseOffset;
  float maxOscAngle;
  float diameter;
  float maxDiameter;
  float maxStrokeWeight;
  float oscAmp;
  float xoffset;
  float angle;
  int age;
  
  Note(float f, float p) {
    age = 0;
    freq = f;
    pan = p;

    // higher notes oscillate more quickly
    maxOscAngle = map(freq, minFreq, maxFreq, PI, 2 * PI);

    // lower notes make larger bubbles 
    maxDiameter = map(freq, minFreq, maxFreq, 400, 80);
    maxStrokeWeight = map(freq, minFreq, maxFreq, 200, 20);

    // start each bubble with a randome phase.
    phaseOffset = random(0, TWO_PI);

    // higher notes trace tighter waveforms
    oscAmp = map(freq, minFreq, maxFreq, 30, 300);

    xorigin = map(p, -1.0, 1.0, 0, width) - oscAmp * sin(phaseOffset);
    x = xorigin;
    y = height;
  }
  
  void update() {
    angle = map(age, 0, maxNoteAge, 0, maxOscAngle) + phaseOffset;
    x = xorigin + (oscAmp * sin(angle));
    y = map(age, 0, maxNoteAge, height, 0);
    diameter = map(age, 0, maxNoteAge, 20, maxDiameter);

    noFill();
    stroke(colorFromFreq(freq), map(age, 0, maxNoteAge, 100, 0));
    strokeWeight(map(age, 0, maxNoteAge, 4, maxStrokeWeight));
    ellipse(x, y, diameter, diameter);
    age++;
  }
  
  boolean dead() {
    return age >= maxNoteAge;
  }
}
