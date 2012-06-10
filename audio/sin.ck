SinOsc s => ADSR e => Pan2 pan => dac;
OscSend toUI;
toUI.setHost("localhost", 9000);
100::ms => e.attackTime;
100::ms => e.releaseTime;
e.keyOff();

140 => float minFreq;
1600 => float maxFreq;

fun void playNote(float f) {
    Std.rand2f(-1, 1) => float p;
    p => pan.pan;
    f => s.freq;
    e.keyOn();
    f => toUI.addFloat;
    p => toUI.addFloat;
    toUI.startMsg("/noteOn", "ff");
    100::ms => now;
    e.keyOff();
    100::ms => now;
}

while (1) {
    playNote(Math.rand2f(minFreq, maxFreq));
}
