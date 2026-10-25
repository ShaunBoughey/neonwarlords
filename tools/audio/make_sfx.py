"""Synthesise Neon Warlords UI/battle sound effects as 16-bit mono WAVs (pure Python, no deps).

Run:  python tools/audio/make_sfx.py   -> writes assets/audio/*.wav
"""
import math, os, random, struct, wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")
random.seed(3)


def env(i, n, a=0.005, r=0.5):
    t = i / SR
    dur = n / SR
    att = min(1.0, t / a) if a > 0 else 1.0
    rel = max(0.0, 1.0 - max(0.0, t - (dur - r * dur)) / (r * dur)) if r > 0 else 1.0
    return att * rel


def tone(freq, dur, kind="sine", vol=0.5, a=0.005, r=0.6, slide=0.0):
    n = int(SR * dur)
    out = []
    ph = 0.0
    for i in range(n):
        f = freq + slide * (i / n)
        ph += 2 * math.pi * f / SR
        if kind == "sine":
            s = math.sin(ph)
        elif kind == "square":
            s = 1.0 if math.sin(ph) > 0 else -1.0
        elif kind == "saw":
            s = 2 * ((ph / (2 * math.pi)) % 1.0) - 1
        elif kind == "tri":
            s = 2 * abs(2 * ((ph / (2 * math.pi)) % 1.0) - 1) - 1
        else:
            s = random.uniform(-1, 1)
        out.append(s * vol * env(i, n, a, r))
    return out


def noise(dur, vol=0.5, a=0.002, r=0.8, lp=0.2):
    n = int(SR * dur)
    out, y = [], 0.0
    for i in range(n):
        y += lp * (random.uniform(-1, 1) - y)
        out.append(y * vol * 3 * env(i, n, a, r))
    return out


def mix(*tracks, offsets=None):
    offsets = offsets or [0.0] * len(tracks)
    n = max(int(o * SR) + len(t) for t, o in zip(tracks, offsets))
    out = [0.0] * n
    for t, o in zip(tracks, offsets):
        k = int(o * SR)
        for i, s in enumerate(t):
            out[k + i] += s
    return out


def save(name, samples):
    os.makedirs(OUT, exist_ok=True)
    peak = max(1e-6, max(abs(s) for s in samples))
    g = min(1.0, 0.9 / peak)
    with wave.open(os.path.join(OUT, name + ".wav"), "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * g)) * 32767)) for s in samples))
    print("wrote", name)


save("click", mix(tone(1800, 0.03, "square", 0.25, r=0.9), tone(900, 0.04, "sine", 0.3, r=0.9)))
save("confirm", mix(tone(660, 0.07, "tri", 0.4), tone(990, 0.12, "tri", 0.4), offsets=[0, 0.06]))
save("back", tone(700, 0.08, "tri", 0.35, slide=-300))
save("slide", mix(noise(0.8, 0.35, a=0.1, r=0.4, lp=0.05), tone(90, 0.8, "saw", 0.12, a=0.1, r=0.3, slide=-30)))
save("latch", mix(noise(0.05, 0.6, lp=0.6), tone(2400, 0.04, "square", 0.2)))
save("open", mix(noise(0.35, 0.3, a=0.01, lp=0.15), tone(300, 0.6, "sine", 0.3, a=0.02, slide=600),
                 tone(1200, 0.6, "sine", 0.15, a=0.1, slide=400), offsets=[0, 0.05, 0.15]))
save("reveal", mix(tone(523, 0.5, "tri", 0.3), tone(659, 0.5, "tri", 0.3), tone(784, 0.7, "tri", 0.3), tone(1047, 0.9, "sine", 0.25),
                   offsets=[0, 0.08, 0.16, 0.24]))
save("legendary", mix(*[tone(f, 1.2, "tri", 0.25, a=0.02) for f in (392, 494, 587, 784, 988)], noise(1.2, 0.1, a=0.3, lp=0.02),
                      offsets=[0, 0.1, 0.2, 0.3, 0.4, 0.0]))
save("hit", mix(noise(0.12, 0.7, lp=0.4), tone(140, 0.12, "sine", 0.6, slide=-80)))
save("crit", mix(noise(0.2, 0.8, lp=0.5), tone(220, 0.2, "square", 0.3, slide=-150), tone(1600, 0.1, "square", 0.15)))
save("heal", mix(tone(880, 0.35, "sine", 0.3, a=0.05, slide=440), tone(1320, 0.35, "sine", 0.2, a=0.08, slide=440), offsets=[0, 0.05]))
save("buff", tone(600, 0.2, "tri", 0.3, a=0.02, slide=500))
save("debuff", tone(500, 0.25, "saw", 0.2, a=0.02, slide=-300))
save("death", mix(noise(0.5, 0.5, lp=0.08), tone(180, 0.6, "saw", 0.3, slide=-140)))
save("skill", mix(noise(0.25, 0.3, a=0.05, lp=0.3), tone(400, 0.25, "saw", 0.2, a=0.05, slide=900)))
save("victory", mix(*[tone(f, d, "square", 0.18, a=0.01, r=0.5) for f, d in ((523, 0.15), (659, 0.15), (784, 0.15), (1047, 0.6))],
                    offsets=[0, 0.14, 0.28, 0.42]))
save("defeat", mix(*[tone(f, 0.35, "saw", 0.2, r=0.6) for f in (392, 330, 262)], offsets=[0, 0.3, 0.6]))
save("reward", mix(tone(1047, 0.12, "sine", 0.3), tone(1319, 0.12, "sine", 0.3), tone(1568, 0.3, "sine", 0.3), offsets=[0, 0.07, 0.14]))
save("levelup", mix(*[tone(f, 0.25, "tri", 0.3) for f in (523, 698, 880, 1175)], offsets=[0, 0.07, 0.14, 0.21]))
