// red-beast

// Eric Heep
// for Manuel Lima's 2nd Year DMA Recital "Red Light Piano"
// MTIID4LIFE

public class SingleSin extends Chubgraph{

    float frq;
    float vl;
    float prev_frq;

    float phase;
    float phase_inc;
    float high, low, width, temp_val;
    1.0/12.0 => width;

    2 * pi => float two_pi;
    int num_cols;

    [-1.0, -2.0/3.0, -1.0/3.0, -1.0/6.0, 1.0/6.0, 1.0/3.0, 2.0/3.0, 1.0] @=> float pos[];
    [1.0/6.0, 1.0/6.0, 1.0/12.0, 1.0/6.0, 1.0/12.0, 1.0/6.0, 1.0/6.0] @=> float ratio[];

    // converts -1.0 to 1.0 to 0.0 to 1.0
    for (int i; i < pos.size(); i++) {
        (pos[i] + 1.0) * 0.5 => pos[i];
    }

    fun void init(int n) {
        n => num_cols;
    }

    fun void freq(float f) {
        f => frq;
    }

    fun void vol(float g) {
        g => vl;
    }

    // multiple sin stuff
    fun float[][] calc(float val[][]) {
        for (int i; i < num_cols; i++) {
            // shift
            for (val[i].size() - 2 => int j; j >= 0; j--) {
                val[i][j] => val[i][j + 1];
            }
    
            // calls only on the first pass
            if (i == 0) {
                // only calculates when needed
                if (frq != prev_frq) {
                    frq/30.0 * two_pi => phase_inc;
                    frq => prev_frq;
                }

                // adds incrment to phase and wraps
                phase_inc +=> phase;
                if (phase > two_pi) {
                    two_pi -=> phase;
                }

                (Math.sin(phase) * vl + 1.0) * 0.5 * (1.0 - width * 2) + width  => temp_val;
            }

            temp_val - width => low;
            temp_val + width => high;

            if (low >= pos[i] && low < pos[i + 1]) {  
                (low - pos[i])/ratio[i] => val[i][0]; 
            }
            else if (high > pos[i] && high <= pos[i + 1]) {  
                1.0 + (high - pos[i])/ratio[i] => val[i][0]; 
            }
            else if (low < pos[i] && high > pos[i + 1]) {
                0.00000001 => val[i][0]; 
            }
            else {
                0.0 => val[i][0];
            }
        }

        return val;
    }
}