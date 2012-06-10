OscSend toUI;
toUI.setHost("localhost", 9000);
140 => float minFreq;
1600 => float maxFreq;

public class Voice
{
    SinOsc osc => ADSR e => Pan2 pan => dac;
    Shred @ s;
    
    0.2 => osc.gain;
    20::ms => e.attackTime;
    20::ms => e.releaseTime;
    fun void startLoop() {
        spork ~ loop() @=> s;
    }

    fun void loop() {
        while(true) {
            playNote(Math.rand2f(minFreq, maxFreq));
        }
    }

    fun void playNote(float f) {
        Math.rand2f(-1, 1) => float p;
        p => pan.pan;
        f => osc.freq;
        sendNote(f, p);
        e.keyOn();
        200::ms => now;
        e.keyOff();
        200::ms => now;
    }
}

fun void sendNote(float f, float p) {
    f => toUI.addFloat;
    p => toUI.addFloat;
    toUI.startMsg("/noteOn", "ff");
}

new Voice @=> Voice @ v0;
v0.startLoop();

new Voice @=> Voice @ v1;
v1.startLoop();

while (1) { 1::second => now; }
