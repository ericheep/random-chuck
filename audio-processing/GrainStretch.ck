// Eric Heep
// March 25th, 2017
// GrainStretch.ck

// Basic grain strech that elongates a buffer of
// audio while retaining its pitch, the more grains,
// the more coherent the message.

// This version constantly listens and overwrites two audio buffers.
// Switching between the two to ensure a constant signal.

public class GrainStretch extends Chubgraph {

    LiSa mic[2];
    ADSR env;

    inlet => mic[0] => env => outlet;
    inlet => mic[1] => env => outlet;

    0 => int m_stretching;
    32 => int m_grains;
    1.0 => float m_rate;

    1.0::second => dur m_bufferLength;
    maxLength(8::second);

    fun void stretch(int s) {
        if (s == 1) {
            1 => m_stretching;
            spork ~ stretching();
        }
        else {
            0 => m_stretching;
        }
    }

    fun void maxLength(dur m) {
        mic[0].duration(m);
        mic[1].duration(m);
    }

    fun void length(dur l) {
        l => m_bufferLength;
    }

    fun void rate(float r) {
        r => m_rate;
    }

    fun void grains(int g) {
        g => m_grains;
    }

    fun void stretching() {
        0 => int idx;

        recordVoice(mic[idx], m_bufferLength);

        // switches between audio buffers, ensuring a constant processed signal
        while (m_stretching) {
            spork ~ recordVoice(mic[(idx + 1) % 2], m_bufferLength);
            (idx + 1) % 2 => idx;
            stretchVoice(mic[idx], m_bufferLength, m_rate, m_grains);
        }
    }

    fun void recordVoice(LiSa mic, dur bufferLength) {
        mic.clear();
        mic.recPos(0::samp);
        mic.record(1);
        bufferLength => now;
        mic.record(0);
    }

    // all the sound stuff we're doing
    fun void stretchVoice(LiSa mic, dur duration, float rate, int grains) {
        (duration * 1.0/rate)/grains => dur grain;
        grain/32.0 => dur grainEnv;
        grain * 0.5 => dur halfGrain;

        // for some reason if you try to put a sample
        // at a fraction of samp, it will silence ChucK
        // but not crash it?
        if (halfGrain < samp) {
            <<< "Your grains are too small to produce audio.", "" >>>;
            return;
        }

        // envelope parameters
        env.attackTime(grainEnv);
        env.releaseTime(grainEnv);

        halfGrain/samp => float halfGrainSamples;
        ((duration/samp)$int)/grains=> int sampleIncrement;

        mic.play(1);

        // bulk of the time stretching
        for (0 => int i; i < grains; i++) {
            mic.playPos((i * sampleIncrement)::samp);
            (i * sampleIncrement)::samp + grain => dur end;

            // only fade if there will be no discontinuity errors
            if (duration > end) {
                env.keyOn();
                halfGrain => now;
                env.keyOff();
                halfGrain - grainEnv => now;
            }
            else {
                (grain - (end - duration)) => dur endGrain;
                env.keyOn();
                endGrain * 0.5 => now;
                env.keyOff();
                endGrain * 0.5 - grainEnv => now;
            }
        }

        mic.play(0);
    }
}

adc => GrainStretch g => dac;
// adc => Gain gr => dac;

g.stretch(1);
g.rate(0.5);
g.length(2000::ms);
g.grains(100);

while(true) {
    samp => now;
}
