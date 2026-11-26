"""Render the original 16-bar game loop as an uncompressed WAV."""
import math
import random
import struct
import sys
import wave

RATE = 32000
NEON = "--neon" in sys.argv[2:]
HARBOR = "--harbor" in sys.argv[2:]
FOREST = "--forest" in sys.argv[2:]
BEAT = 60 / (154 if NEON else (146 if FOREST else (134 if HARBOR else 122)))
LENGTH = round(BEAT * 64 * RATE)
mix = [0.0] * LENGTH
noise = random.Random(0)


def add(beat, duration, note, level, voice):
    root = math.tau * 440 * 2 ** ((note - 69) / 12)
    for sample in range(int(duration * BEAT * RATE)):
        t = sample / RATE
        p = root * t
        env = min(1, t * 160) * min(1, (duration * BEAT - t) * 38)
        if voice == "bell":
            signal = (math.sin(p) + 0.33 * math.sin(2.01*p) * math.exp(-t*7) + 0.18 * math.sin(3.99*p) * math.exp(-t*15)) * math.exp(-t*5)
        elif voice == "bass":
            signal = (math.sin(p) + 0.17 * math.sin(2*p)) * math.exp(-t*3)
        elif voice == "kick":
            signal = math.sin(math.tau * (47*t + 3*(1-math.exp(-22*t)))) * math.exp(-t*22)
        else:
            signal = (noise.random() * 2 - 1) * math.exp(-t*41)
        index = (round(beat * BEAT * RATE) + sample) % LENGTH
        mix[index] += level * env * signal


chords = [(60, 64, 67, 74), (57, 60, 64, 71), (53, 57, 60, 67), (55, 59, 62, 69)]
melodies = [
    (76, 79, 84, 81, 79, 76), (76, 72, 74, 76, 81, 79),
    (77, 76, 72, 74, 77, 81), (79, 74, 71, 74, 79, 83),
    (84, 83, 79, 76, 79, 81), (81, 84, 88, 86, 84, 81),
    (81, 77, 79, 81, 84, 86), (86, 83, 79, 76, 74, 79),
]
if HARBOR:
    chords = [(57, 61, 64, 71), (54, 57, 61, 68), (50, 54, 57, 64), (52, 56, 59, 66)]
    melodies = [
        (76, 81, 83, 85, 81, 76), (76, 80, 78, 73, 76, 78),
        (78, 81, 86, 83, 81, 78), (80, 78, 76, 71, 76, 80),
        (81, 88, 85, 83, 85, 81), (81, 80, 76, 73, 76, 81),
        (86, 85, 81, 78, 81, 86), (83, 80, 76, 78, 80, 83),
    ]
if FOREST:
    chords = [(62, 65, 69, 72), (58, 62, 65, 69), (65, 69, 72, 79), (60, 64, 67, 74)]
    melodies = [
        (74, 77, 81, 79, 77, 74), (74, 77, 82, 81, 77, 74),
        (77, 81, 84, 86, 84, 81), (79, 76, 74, 76, 79, 84),
        (86, 84, 81, 77, 81, 84), (82, 81, 77, 74, 77, 81),
        (84, 89, 88, 84, 81, 84), (84, 79, 76, 79, 83, 84),
    ]
if NEON:
    chords = [(57, 60, 64, 71), (53, 57, 60, 67), (60, 64, 67, 74), (55, 59, 62, 69)]
    melodies = [
        (69, 76, 79, 83, 79, 76), (77, 81, 84, 83, 81, 76),
        (76, 79, 84, 88, 86, 79), (74, 79, 83, 86, 83, 79),
        (84, 83, 79, 76, 79, 88), (84, 81, 77, 72, 77, 84),
        (86, 84, 81, 79, 83, 86), (83, 79, 74, 71, 74, 79),
    ]
for bar in range(16):
    chord = chords[bar % 4]
    start = bar * 4
    for i, offset in enumerate((0, 0.67, 1.5, 2.0, 2.67, 3.5) if HARBOR else (0, 0.75, 1.5, 2, 2.75, 3.5)):
        add(start + offset, 0.68, melodies[bar % 8][i], 0.19 if bar >= 4 else 0.17, "bell")
        add(start + offset + 0.375, 0.56, melodies[bar % 8][i], 0.037, "bell")
    for i, offset in enumerate((0.25, 1.25, 2.25, 3.25)):
        add(start + offset, 0.7, chord[(i*3) % 4], 0.075, "bell")
    for i, offset in enumerate((0, 1.5, 2, 3.25)):
        add(start + offset, 0.72, chord[i % 2] - 24, 0.28 if NEON else 0.22, "bass")
    for beat in range(4):
        if beat % 2 == 0:
            add(start + beat, 0.36, 36, 0.26, "kick")
        add(start + beat + 0.5, 0.24, 72, 0.061, "hat")
        if beat % 2 == 1:
            add(start + beat, 0.3, 60, 0.14, "hat")

with wave.open(sys.argv[1], "wb") as output:
    output.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
    output.writeframes(struct.pack("<" + "h" * LENGTH, *(int(29000 * math.tanh(sample)) for sample in mix)))
