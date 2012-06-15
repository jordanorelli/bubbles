class MouseNote {
  int maxAge = 30;
  int maxDiameter = 600;

  float freq;
  float pan;
  float x;
  float y;
  float diameter;
  float opacity;
  int age;

  MouseNote(float f, float p) {
    age = 0;
    freq = f;
    pan = p;
    diameter = 10;

    x = map(p, -1, 1, 0, width);
    y = map(f, minFreq, maxFreq, height, 0);
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
