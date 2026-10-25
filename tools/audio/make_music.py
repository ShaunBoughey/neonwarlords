"""Synthesise Neon Warlords music loops (synthwave) as 16-bit mono WAVs - pure Python, no deps.

Run:  python tools/audio/make_music.py   -> writes assets/audio/music_city.wav, music_battle.wav
The loops are seamless: every voice is rendered into a circular buffer so tails wrap to the start.
"""
import math, os, random, struct, wave

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


class Track:
    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.buf = [0.0] * self.n

    def add(self, start, samples):
        k = int(start * SR)
        n = self.n
        for i, s in enumerate(samples):
            self.buf[(k + i) % n] += s


def osc(kind, freq, dur, vol, a=0.01, d=0.0, s=1.0, r=0.1, detune=0.0, cutoff=1.0, vib=0.0):
    n = int(dur * SR)
    tail = int(r * SR)
    out = []
    ph1 = random.random()
    ph2 = random.random()
    y = 0.0
    for i in range(n + tail):
        t = i / SR
        if i < n:
            e = min(1.0, t / a) if a > 0 else 1.0
            if d > 0 and t > a:
                e = max(s, 1.0 - (1.0 - s) * (t - a) / d)
        else:
            e = s * max(0.0, 1.0 - (i - n) / max(1, tail))
        f = freq * (1 + vib * math.sin(2 * math.pi * 5.5 * t))
        ph1 = (ph1 + f / SR) % 1.0
        ph2 = (ph2 + f * (1 + detune) / SR) % 1.0
        if kind == "saw":
            v = (2 * ph1 - 1) + ((2 * ph2 - 1) if detune else 0)
            v *= 0.5 if detune else 1.0
        elif kind == "square":
            v = 1.0 if ph1 < 0.5 else -1.0
        elif kind == "tri":
            v = 4 * abs(ph1 - 0.5) - 1
        else:
            v = math.sin(2 * math.pi * ph1)
        y += cutoff * (v - y)
        out.append(y * e * vol)
    return out


def kick(vol=0.9):
    out, ph = [], 0.0
    for i in range(int(0.22 * SR)):
        t = i / SR
        f = 45 + 110 * math.exp(-t * 30)
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * math.exp(-t * 14) * vol)
    return out


def snare(vol=0.5):
    out, y = [], 0.0
    for i in range(int(0.2 * SR)):
        t = i / SR
        y += 0.5 * (random.uniform(-1, 1) - y)
        out.append((y * 0.9 + 0.3 * math.sin(2 * math.pi * 185 * t)) * math.exp(-t * 18) * vol)
    return out


def hat(vol=0.18, length=0.05):
    out, lp = [], 0.0
    for i in range(int(length * SR)):
        t = i / SR
        w = random.uniform(-1, 1)
        lp += 0.3 * (w - lp)
        out.append((w - lp) * math.exp(-t * 60) * vol)
    return out


def echo(track, delay, fb, mix):
    d = int(delay * SR)
    src = track.buf[:]
    out = [0.0] * track.n
    for rep in range(1, 5):
        g = mix * (fb ** (rep - 1))
        k = d * rep
        for i in range(track.n):
            out[(i + k) % track.n] += src[i] * g
    for i in range(track.n):
        track.buf[i] += out[i]


def save(name, tracks):
    n = tracks[0].n
    mixb = [sum(t.buf[i] for t in tracks) for i in range(n)]
    peak = max(1e-6, max(abs(s) for s in mixb))
    g = 0.85 / peak
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, math.tanh(s * g * 1.2) / math.tanh(1.2))) * 32767)) for s in mixb))
    print("wrote", name, "%.1fs" % (n / SR))


def song(name, bpm, chords, bars_per_chord, bass_pattern, arp_steps, lead, drums, cutoff_pad=0.05):
    random.seed(11)
    beat = 60.0 / bpm
    bar = beat * 4
    total_bars = len(chords) * bars_per_chord
    length = total_bars * bar
    pad, bass, arp, ld, dr = Track(length), Track(length), Track(length), Track(length), Track(length)
    for ci, ch in enumerate(chords):
        t0 = ci * bars_per_chord * bar
        dur = bars_per_chord * bar
        for m in ch:
            pad.add(t0, osc("saw", mtof(m), dur, 0.05, a=0.6, r=0.6, detune=0.006, cutoff=cutoff_pad))
        root = ch[0] - 12
        steps = int(bars_per_chord * 4 * len(bass_pattern) / 4)
        step = beat * 4 / len(bass_pattern)
        for k in range(bars_per_chord * len(bass_pattern)):
            off = bass_pattern[k % len(bass_pattern)]
            if off is None:
                continue
            bass.add(t0 + k * step, osc("saw", mtof(root + off), step * 0.8, 0.22, a=0.004, d=0.12, s=0.4, r=0.03, cutoff=0.18))
        tones = sorted(ch) + [ch[0] + 12]
        astep = beat / arp_steps
        for k in range(int(bars_per_chord * 4 * arp_steps)):
            m = tones[k % len(tones)] + 12
            arp.add(t0 + k * astep, osc("square", mtof(m), astep * 0.5, 0.05, a=0.002, d=0.08, s=0.2, r=0.02, cutoff=0.35))
    echo(arp, beat * 0.75, 0.4, 0.35)
    for (bt, m, d) in lead:
        ld.add(bt * beat, osc("saw", mtof(m), d * beat, 0.08, a=0.03, r=0.25, detune=0.004, cutoff=0.12, vib=0.004))
    echo(ld, beat * 0.5, 0.35, 0.3)
    for b in range(total_bars):
        drums(dr, b * bar, beat, b)
    save(name, [pad, bass, arp, ld, dr])


def city_drums(dr, t, beat, b):
    for q in range(4):
        if q in (0, 2):
            dr.add(t + q * beat, kick(0.8))
        if q in (1, 3):
            dr.add(t + q * beat, snare(0.4))
        dr.add(t + q * beat + beat / 2, hat(0.14))


def battle_drums(dr, t, beat, b):
    for q in range(4):
        dr.add(t + q * beat, kick(0.9))
        if q in (1, 3):
            dr.add(t + q * beat, snare(0.55))
        for s in range(4):
            dr.add(t + q * beat + s * beat / 4, hat(0.16 if s == 2 else 0.08, 0.035))
    if b % 4 == 3:
        for s in range(4):
            dr.add(t + 3 * beat + s * beat / 4, snare(0.3 + 0.08 * s))


# City: Am - F - C - G, 2 bars each (16 bars at 100 bpm)
A, F, C, G = [57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]
city_lead = []
phrase = [(0, 76, 1.5), (1.5, 74, 0.5), (2, 72, 1), (3, 71, 1), (4, 72, 3), (8, 69, 1.5), (9.5, 71, 0.5), (10, 72, 1), (11, 74, 1), (12, 76, 3),
          (16, 79, 1.5), (17.5, 77, 0.5), (18, 76, 2), (20, 74, 2), (24, 74, 1), (25, 72, 1), (26, 71, 2), (28, 69, 3)]
for rep in (0, 32):
    city_lead += [(t + rep, m, d) for (t, m, d) in phrase]
song("music_city", 100, [A, F, C, G, A, F, C, G], 2, [0, None, 12, 0, 7, None, 12, 0], 4, city_lead, city_drums)

# Battle: Em - C - D - B, driving 16ths (16 bars at 128 bpm)
E, Cb, D, B = [52, 55, 59], [48, 52, 55], [50, 54, 57], [47, 51, 54]
battle_lead = []
riff = [(0, 76, 0.75), (0.75, 74, 0.75), (1.5, 71, 0.5), (2, 72, 1), (3, 71, 1), (4, 76, 0.75), (4.75, 78, 0.75), (5.5, 79, 0.5), (6, 78, 2)]
for rep in range(0, 64, 8):
    if rep % 16 == 8 or rep >= 32:
        battle_lead += [(t + rep, m, d) for (t, m, d) in riff]
song("music_battle", 128, [E, Cb, D, B, E, Cb, D, B], 2, [0, 0, 12, 0, 0, 7, 0, 12, 0, 0, 12, 0, 10, 0, 7, 0], 4, battle_lead, battle_drums, cutoff_pad=0.04)
