"""Create the original valley ambience, wind, slide scrape and heart chime."""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 24000
RNG = random.Random(101)
OUTPUT = Path(sys.argv[1])


def sound(name, seconds, sample):
    count = round(RATE * seconds)
    with wave.open(str(OUTPUT / f"{name}.wav"), "wb") as output:
        output.setparams((1, 2, RATE, count, "NONE", "not compressed"))
        output.writeframes(struct.pack(
            f"<{count}h", *(int(28000 * math.tanh(sample(i / RATE))) for i in range(count))
        ))


def chirp(t, offset, length, pitch):
    elapsed = t - offset
    if not 0 < elapsed < length:
        return 0
    p = elapsed / length
    return 0.081 * math.sin(math.tau * elapsed * (pitch + 570 * p)) * math.sin(math.pi * p) ** 2


def forest(t):
    global dark, middle
    noise = RNG.uniform(-1, 1)
    dark += (noise - dark) * .04
    middle += (noise - middle) * .21
    floor = ((middle - dark) * .23 + dark * .11) * (.49 + .22 * math.sin(math.tau * t / 6))
    notes = [(0.7, .16, 1890), (0.93, .21, 2130), (3.96, .25, 1710), (4.29, .16, 1980),
             (7.02, .18, 1980), (7.31, .25, 2190), (10.14, .18, 1780), (10.40, .22, 1980)]
    return (floor + sum(chirp(t, *note) for note in notes)) * min(1, t * 21, (12 - t) * 21)


def wind(t):
    global dark, middle
    noise = RNG.uniform(-1, 1)
    dark += (noise - dark) * .014
    middle += (noise - middle) * .09
    gust = .49 + .22 * math.sin(math.tau * t / 4) + .22 * math.sin(math.tau * t / 2)
    return (dark * 1.42 + (middle - dark) * .38) * gust * min(1, t * 25, (4 - t) * 25)


def slide(t):
    global dark, middle
    noise = RNG.uniform(-1, 1)
    dark += (noise - dark) * .035
    middle += (noise - middle) * .41
    grain = (middle - dark) * (0.33 + 0.19 * math.sin(math.tau * 38 * t))
    return (grain + dark * .22) * min(1, 38 * t) * (1 - t / .66) ** 1.48


def heart(t):
    tone = 0
    for start, frequency in [(0, 523.25), (.076, 659.25), (.152, 784), (.244, 1046.5)]:
        delta = t - start
        if delta >= 0:
            onset = min(1, delta * 125)
            wave_t = math.tau * delta * frequency
            tone += (math.sin(wave_t) + .23 * math.sin(2.01 * wave_t)) * onset * math.exp(-delta * 14.8)
    return tone * .22 * min(1, (0.76 - t) * 24)


def time_chime(t):
    soft = math.sin(math.tau * (1045 * t - 237 * t * t))
    contra = math.sin(math.tau * (537 * t - 103 * t * t))
    return (soft * .32 + contra * .38) * math.exp(-3.1 * t) * min(1, 78 * t, (0.68 - t) * 16)


def hover(t):
    global dark
    dark += (RNG.uniform(-1, 1) - dark) * .056
    swell = math.sin(math.pi * t / 0.84) ** 2
    engine = math.sin(math.tau * (175 * t - 43 * t * t))
    return (dark * 1.34 + engine * .12) * swell


def neon_air(t):
    global dark
    dark += (RNG.uniform(-1, 1) - dark) * .04
    traffic = (.32 + .24 * math.sin(math.tau * t / 4)) * dark
    hum = .028 * math.sin(math.tau * 58 * t) + .020 * math.sin(math.tau * 81 * t)
    return (traffic + hum) * min(1, 24 * t, (12 - t) * 24)


for name, duration, sample in [("forest-air", 12, forest), ("speed-wind", 4, wind),
                               ("slide-grit", .66, slide), ("heart-chime", .76, heart), ("neon-air", 12, neon_air),
                               ("hover-pass", .84, hover), ("time-chime", .68, time_chime)]:
    dark = middle = 0
    sound(name, duration, sample)
