part of tui;

/// Note frequencies in Hz, 12-tone equal temperament (A4 = 440 Hz).
/// Sharps use 's' suffix: `Cs4` = C#4.
abstract class Note {
  // --- Octave 0 ---
  static const double C0 = 16.3516;
  static const double Cs0 = 17.3239;
  static const double D0 = 18.3540;
  static const double Ds0 = 19.4454;
  static const double E0 = 20.6017;
  static const double F0 = 21.8268;
  static const double Fs0 = 23.1247;
  static const double G0 = 24.4997;
  static const double Gs0 = 25.9565;
  static const double A0 = 27.5000;
  static const double As0 = 29.1352;
  static const double B0 = 30.8677;

  // --- Octave 1 ---
  static const double C1 = 32.7032;
  static const double Cs1 = 34.6478;
  static const double D1 = 36.7081;
  static const double Ds1 = 38.8909;
  static const double E1 = 41.2034;
  static const double F1 = 43.6535;
  static const double Fs1 = 46.2493;
  static const double G1 = 48.9994;
  static const double Gs1 = 51.9131;
  static const double A1 = 55.0000;
  static const double As1 = 58.2705;
  static const double B1 = 61.7354;

  // --- Octave 2 ---
  static const double C2 = 65.4064;
  static const double Cs2 = 69.2957;
  static const double D2 = 73.4162;
  static const double Ds2 = 77.7817;
  static const double E2 = 82.4069;
  static const double F2 = 87.3071;
  static const double Fs2 = 92.4986;
  static const double G2 = 97.9989;
  static const double Gs2 = 103.826;
  static const double A2 = 110.000;
  static const double As2 = 116.541;
  static const double B2 = 123.471;

  // --- Octave 3 ---
  static const double C3 = 130.813;
  static const double Cs3 = 138.591;
  static const double D3 = 146.832;
  static const double Ds3 = 155.563;
  static const double E3 = 164.814;
  static const double F3 = 174.614;
  static const double Fs3 = 184.997;
  static const double G3 = 195.998;
  static const double Gs3 = 207.652;
  static const double A3 = 220.000;
  static const double As3 = 233.082;
  static const double B3 = 246.942;

  // --- Octave 4 (Middle C) ---
  static const double C4 = 261.626;
  static const double Cs4 = 277.183;
  static const double D4 = 293.665;
  static const double Ds4 = 311.127;
  static const double E4 = 329.628;
  static const double F4 = 349.228;
  static const double Fs4 = 369.994;
  static const double G4 = 391.995;
  static const double Gs4 = 415.305;
  static const double A4 = 440.000;
  static const double As4 = 466.164;
  static const double B4 = 493.883;

  // --- Octave 5 ---
  static const double C5 = 523.251;
  static const double Cs5 = 554.365;
  static const double D5 = 587.330;
  static const double Ds5 = 622.254;
  static const double E5 = 659.255;
  static const double F5 = 698.456;
  static const double Fs5 = 739.989;
  static const double G5 = 783.991;
  static const double Gs5 = 830.609;
  static const double A5 = 880.000;
  static const double As5 = 932.328;
  static const double B5 = 987.767;

  // --- Octave 6 ---
  static const double C6 = 1046.50;
  static const double Cs6 = 1108.73;
  static const double D6 = 1174.66;
  static const double Ds6 = 1244.51;
  static const double E6 = 1318.51;
  static const double F6 = 1396.91;
  static const double Fs6 = 1479.98;
  static const double G6 = 1567.98;
  static const double Gs6 = 1661.22;
  static const double A6 = 1760.00;
  static const double As6 = 1864.66;
  static const double B6 = 1975.53;

  // --- Octave 7 ---
  static const double C7 = 2093.00;
  static const double Cs7 = 2217.46;
  static const double D7 = 2349.32;
  static const double Ds7 = 2489.02;
  static const double E7 = 2637.02;
  static const double F7 = 2793.83;
  static const double Fs7 = 2959.96;
  static const double G7 = 3135.96;
  static const double Gs7 = 3322.44;
  static const double A7 = 3520.00;
  static const double As7 = 3729.31;
  static const double B7 = 3951.07;

  // --- Octave 8 ---
  static const double C8 = 4186.01;

  static const Map<String, int> _semitones = {
    'C': 0,
    'Cs': 1,
    'D': 2,
    'Ds': 3,
    'E': 4,
    'F': 5,
    'Fs': 6,
    'G': 7,
    'Gs': 8,
    'A': 9,
    'As': 10,
    'B': 11,
  };

  static double frequency(String name, int octave) => noteFrequency(name, octave);
}

/// Compute frequency from note name and octave: `noteFrequency('A', 4) == 440.0`
double noteFrequency(String name, int octave) {
  final semitone = Note._semitones[name];
  if (semitone == null) throw ArgumentError('Unknown note name: $name');
  if (octave < 0 || octave > 8) throw ArgumentError('Octave must be 0-8, got: $octave');
  if (octave == 8 && semitone > 0) throw ArgumentError('Only C8 is supported in octave 8');
  final midi = 12 + octave * 12 + semitone;
  return 440.0 * pow(2.0, (midi - 69) / 12.0);
}

/// Beat duration constants (quarter note = 1 beat).
abstract class Dur {
  static const double whole = 4.0;
  static const double dottedHalf = 3.0;
  static const double half = 2.0;
  static const double dottedQuarter = 1.5;
  static const double quarter = 1.0;
  static const double dottedEighth = 0.75;
  static const double eighth = 0.5;
  static const double dottedSixteenth = 0.375;
  static const double sixteenth = 0.25;
  static const double thirtySecond = 0.125;
  static const double triplet = 1.0 / 3.0;

  static double quarterAt(int bpm) => 60.0 / bpm;
  static double toSeconds(double beats, int bpm) => beats * 60.0 / bpm;
}
