OscSend toUI;
toUI.setHost("localhost", 9000);
110 => float minFreq;
1760 => float maxFreq;
0 => int numVoices;

Math.pow(2, 1.0 / 12.0) => float toneStep;

OscRecv recv;
9001 => recv.port;
recv.listen();

float mouseX;
float mouseY;
0 => int mouseDown;

float validFreqs[49];
for(0 => int i; i < 49; i++) {
    minFreq * Math.pow(toneStep, i) => validFreqs[i];
}

// given a frequency, gives the nearest valid frequency.
fun int nearestFreq(float f) {
    if(f <= minFreq) {
        return 0;
    }
    if(f >= maxFreq) {
        return 48;
    }

    float top;
    float bottom;
    for(0 => int i; i < validFreqs.cap() - 1; i++) {
        if(f == validFreqs[i]) {
            return i;
        }
        if(f > validFreqs[i] && f < validFreqs[i+1]) {
            if(Math.fabs(f-validFreqs[i]) < Math.fabs(f-validFreqs[i+1])) {
                return i;
            }
            return i + 1;
        }
    }
    <<< "FUCK", f >>>;
    return 0;
}


60::ms => dur mouseRate;
TriOsc mouseOsc => ADSR mouseEnv => Pan2 mousePan => dac;
mouseEnv.set(80::ms, 20::ms, 0.8, 20::ms);
0.2 => mouseOsc.gain;
mouseEnv.keyOff();

mousePan.left => PRCRev revL => Pan2 panL => dac;
-1 => panL.pan;
mousePan.right => PRCRev revR => Pan2 panR => dac;
1 => panR.pan;
0.6 => revL.mix;
0.6 => revR.mix;

fun void mouseNotes() {
    float targetFreq;
    int toneNumber;
    while(true) {
        if(mouseDown) {
            Math.round((1.0 - mouseY) * 48.0) $ int => toneNumber;
            validFreqs[toneNumber] => mouseOsc.freq;
            (mouseX * 2) - 1 => mousePan.pan;
            mouseNote(toneNumber, mousePan.pan());
            mouseEnv.keyOn();
            1.5 * mouseRate => now;
            mouseEnv.keyOff();
            0.5 * mouseRate => now;
        } else {
            10::samp=>now;
        }
    }
}
spork ~ mouseNotes();
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// handle mouse down
// +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
fun void handleMousePresses() {
    recv.event("/mousePressed", "ff") @=> OscEvent @ press;
    while(true) {
        press => now;
        while(press.nextMsg()) {
            press.getFloat() => mouseX;
            press.getFloat() => mouseY;
        }
        1 => mouseDown;
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
        0 => mouseDown;
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
    }
}
spork ~ handleMouseDragged();
// -----------------------------------------------------------------------------

public class Voice
{
    SinOsc osc => ADSR e => Pan2 pan => dac;
    Shred @ s;
    
    440 => osc.freq;
    0.8 => osc.gain;
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

        pan.pan() + Math.rand2f(-0.1, 0.1) => float targetPan;
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

fun void mouseNote(int i, float p) {
    i => toUI.addInt;
    p => toUI.addFloat;
    toUI.startMsg("/mouseNote", "if");
}

for (0 => int i; i < numVoices; i++) {
    new Voice @=> Voice @ v;
    v.startLoop();
}

while (1) { 1::second => now; }
