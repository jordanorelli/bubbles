SinOsc s => ADSR e => Pan2 pan => dac;
OscSend toUI;
toUI.setHost("localhost", 9000);
20::ms => e.attackTime;
20::ms => e.releaseTime;
e.keyOff();

140 => float minFreq;
1600 => float maxFreq;

fun void playNote(float f) {
    Math.rand2f(-1, 1) => float p;
    p => pan.pan;
    f => s.freq;
    sendNote(f, p);
    e.keyOn();
    100::ms => now;
    e.keyOff();
    100::ms => now;
}

fun void sendNote(float f, float p) {
    f => toUI.addFloat;
    p => toUI.addFloat;
    toUI.startMsg("/noteOn", "ff");
}

while (1) {
    playNote(Math.rand2f(minFreq, maxFreq));
}
