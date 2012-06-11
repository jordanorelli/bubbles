OscSend toUI;
toUI.setHost("localhost", 9000);
140 => float minFreq;
1600 => float maxFreq;

Math.pow(2, 1.0 / 12.0) => float toneStep;

OscRecv recv;
9001 => recv.port;
recv.listen();

SinOsc mouseOsc => Pan2 mousePan => dac;
0.2 => mouseOsc.gain;
0 => mouseOsc.op;
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// handle mouse down
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
float mouseX;
float mouseY;
fun void handleMousePresses() {
    recv.event("/mousePressed", "ff") @=> OscEvent @ press;
    while(true) {
        press => now;
        while(press.nextMsg()) {
            press.getFloat() => mouseX;
            press.getFloat() => mouseY;
        }
        (1 - mouseY) * (maxFreq - minFreq) + minFreq => mouseOsc.freq;
        (mouseX * 2) - 1 => mousePan.pan;
        1 => mouseOsc.op;
    }
}
spork ~ handleMousePresses();
// -----------------------------------------------------------------------------

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// handle mouse up
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
fun void handleMouseReleased() {
    recv.event("/mouseReleased", "i") @=> OscEvent @ release;
    while(true) {
        release => now;
        while(release.nextMsg()) { } // herp derp
        0 => mouseOsc.op;
    }
}
spork ~ handleMouseReleased();
// -----------------------------------------------------------------------------

// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// handle mouse move
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
fun void handleMouseDragged() {
    recv.event("/mouseDragged", "ff") @=> OscEvent @ move;
    while(true) {
        move => now;
        while(move.nextMsg()) {
            move.getFloat() => mouseX;
            move.getFloat() => mouseY;
        }
        (1 - mouseY) * (maxFreq - minFreq) + minFreq => mouseOsc.freq;
        (mouseX * 2) - 1 => mousePan.pan;
    }
}
spork ~ handleMouseDragged();
// -----------------------------------------------------------------------------

public class Voice
{
    SinOsc osc => ADSR e => Pan2 pan => dac;
    Shred @ s;
    
    440 => osc.freq;
    0.2 => osc.gain;
    20::ms => e.attackTime;
    20::ms => e.releaseTime;
    fun void startLoop() {
        spork ~ loop() @=> s;
    }

    fun void loop() {
        while(true) {
            playNote();
        }
    }

    fun void playNote() {
        osc.freq() * Math.pow(toneStep, Math.rand2(-2, 2)) => float targetFreq;
        if (targetFreq < minFreq) {
            minFreq => osc.freq;
        } else if (targetFreq > maxFreq) {
            maxFreq => osc.freq;
        } else {
            targetFreq => osc.freq;
        }

        pan.pan() + Math.rand2f(-0.01, 0.01) => float targetPan;
        if(targetPan < -1) {
            -1 => pan.pan;
        } else if (targetPan > 1) {
            1 => pan.pan;
        } else {
            targetPan => pan.pan;
        }

        sendNote(osc.freq(), pan.pan());
        e.keyOn();
        40::ms => now;
        e.keyOff();
        40::ms => now;
    }
}

fun void sendNote(float f, float p) {
    f => toUI.addFloat;
    p => toUI.addFloat;
    toUI.startMsg("/noteOn", "ff");
}

new Voice @=> Voice @ v1;
v1.startLoop();
new Voice @=> Voice @ v2;
v2.startLoop();

while (1) { 1::second => now; }
