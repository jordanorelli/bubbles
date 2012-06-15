class MouseNote {
  int maxAge = 30;
  int maxDiameter = 550;
  int toneNumber;

  float freq;
  float pan;
  float x;
  float y;
  float diameter;
  float opacity;
  int age;

  MouseNote(int i, float p) {
    age = 0;
    toneNumber = i;
    pan = p;
    diameter = 10;
    freq = validFreqs[i];

    x = map(p, -1, 1, 0, width);
    y = freqHeight(toneNumber);
  }

  void update() {
    age++;
    noFill();

    opacity = pow(norm(age, maxAge, 0), 3) * 100;
    diameter = (1 - pow(1 - norm(age, 0, maxAge), 3)) * maxDiameter;

    stroke(colorFromFreq(freq), opacity);
    strokeWeight(20);
    ellipse(x, y, diameter, diameter);
  }

  boolean dead() {
    return age >= maxAge;
  }
}
