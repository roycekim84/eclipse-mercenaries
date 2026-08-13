#!/usr/bin/env python3
"""Generate deterministic, game-ready placeholder-free audio layers.

The file names are the runtime audio contract. Bespoke recordings can replace
any generated WAV later without changing Dart code.
"""

from __future__ import annotations

import math
import random
import shutil
import struct
import wave
from pathlib import Path

RATE = 22050
OUT = Path(__file__).resolve().parents[1] / "assets" / "audio"
TAU = math.tau


def envelope(t: float, duration: float, attack: float = .015, release: float = .16) -> float:
    return min(1.0, t / max(.001, attack), (duration - t) / max(.001, release))


def write(name: str, duration: float, render, stereo: bool = True) -> None:
    frames = []
    total = int(duration * RATE)
    for i in range(total):
        t = i / RATE
        value = render(t, duration)
        left, right = value if isinstance(value, tuple) else (value, value)
        frames.append(struct.pack("<hh", int(max(-.97, min(.97, left)) * 32767), int(max(-.97, min(.97, right)) * 32767)))
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / f"{name}.wav"), "wb") as wav:
        wav.setnchannels(2 if stereo else 1)
        wav.setsampwidth(2)
        wav.setframerate(RATE)
        if stereo:
            wav.writeframes(b"".join(frames))
        else:
            wav.writeframes(b"".join(frame[:2] for frame in frames))


def tone(freq: float, t: float, phase: float = 0.0) -> float:
    return math.sin(TAU * freq * t + phase)


def noise(seed: int, total: int) -> list[float]:
    rng = random.Random(seed)
    raw = [rng.uniform(-1, 1) for _ in range(total)]
    # A circular smoothing pass keeps loop boundaries continuous.
    return [sum(raw[(i + j) % total] for j in range(-3, 4)) / 7 for i in range(total)]


def make_loop(name: str, duration: float, root: float, mood: str) -> None:
    total = int(duration * RATE)
    bed = noise(sum((i + 1) * ord(ch) for i, ch in enumerate(name)), total)
    freqs = [root, root * 1.5, root * 2, root * 2.5]
    def render(t: float, _: float):
        i = min(total - 1, int(t * RATE))
        pulse = .5 - .5 * math.cos(TAU * t / duration * (4 if mood == "camp" else 8))
        # Quantize every oscillator to complete cycles so the last frame joins
        # the first without a discontinuity on Android and web loop players.
        drone = sum(
            math.sin(TAU * round(f * duration) * t / duration + n * .73)
            * (.11 / (n + 1))
            for n, f in enumerate(freqs)
        )
        if mood == "camp":
            crackle = bed[i] * (.025 + .035 * pulse)
            bell = math.sin(TAU * round(root * 4 * duration) * t / duration) * max(0.0, tone(.25, t)) ** 10 * .035
            left = drone + crackle + bell
            right = drone * .94 + bed[(i + 389) % total] * .045 - bell * .5
        elif mood == "recruit":
            shimmer = math.sin(TAU * round(root * 6 * duration) * t / duration) * (.02 + .035 * pulse)
            left = drone * .75 + shimmer + bed[i] * .018
            right = drone * .72 - shimmer + bed[(i + 521) % total] * .018
        else:
            drum = max(0.0, tone(1.0, t)) ** 18 * tone(root / 2, t) * .12
            tension = math.sin(TAU * round(root * 3 * duration) * t / duration + .1 * tone(.125, t)) * .025
            left = drone + drum + tension + bed[i] * .022
            right = drone * .9 + drum * .94 - tension + bed[(i + 733) % total] * .022
        return left, right
    write(name, duration, render)


def make_hit(name: str, color: str, seed: int) -> None:
    rng = random.Random(seed)
    duration = .24 if color != "boss" else .48
    phases = [rng.random() * TAU for _ in range(4)]
    def render(t: float, d: float):
        e = envelope(t, d, .002, d * .78) ** 1.7
        grit = sum(tone(1100 + n * 463, t, phases[n]) for n in range(4)) / 4
        if color == "slash": value = tone(310 - 170 * t / d, t) * .38 + grit * .3
        elif color == "pierce": value = tone(1450 - 620 * t / d, t) * .32 + grit * .2
        elif color == "magic": value = tone(720 + 880 * t / d, t) * .28 + tone(1540, t) * .18
        elif color == "block": value = tone(210, t) * .32 + tone(890, t) * .27 + grit * .15
        elif color == "hurt": value = tone(125, t) * .5 + grit * .16
        elif color == "critical": value = tone(92, t) * .5 + tone(1240, t) * .22 + grit * .2
        elif color == "boss": value = tone(54, t) * .58 + tone(108, t) * .27 + grit * .15
        else: value = tone(180, t) * .42 + grit * .25
        pan = .08 * tone(7, t, phases[0])
        return value * e * (1-pan), value * e * (1+pan)
    write(name, duration, render)


def make_chime(name: str, notes: list[float], duration: float = .8, dark: bool = False) -> None:
    def render(t: float, d: float):
        value = 0.0
        step = d / (len(notes) + .5)
        for n, freq in enumerate(notes):
            local = t - n * step
            if local >= 0:
                e = math.exp(-local * (5 if dark else 3.8))
                value += (tone(freq, local) + .35 * tone(freq * 2.01, local)) * e * .22
        low = tone(notes[0] / 2, t) * math.exp(-t * 3) * (.24 if dark else .08)
        return value + low, value * .92 - low * .2
    write(name, duration, render)


def make_whoosh(name: str, root: float, duration: float, impact: bool = False) -> None:
    total = int(duration * RATE)
    bed = noise(sum((i + 1) * ord(ch) for i, ch in enumerate(name)), total)
    def render(t: float, d: float):
        x = t / d
        sweep = tone(root + root * 5 * x * x, t) * .25
        air = bed[min(total - 1, int(t * RATE))] * (.12 + .34 * x)
        e = envelope(t, d, .04, .18)
        boom = tone(root / 2, t) * math.exp(-t * 8) * (.5 if impact else .12)
        return (sweep + air) * e + boom, (sweep - air * .7) * e + boom
    write(name, duration, render)


def main() -> None:
    make_loop("camp_loop", 16, 55, "camp")
    make_loop("recruitment_loop", 16, 65.4, "recruit")
    for name, root in {
        "battle_gate_loop": 49,
        "battle_ash_loop": 52,
        "battle_forest_loop": 43.65,
        "battle_siege_loop": 46.25,
        "battle_fortress_loop": 41.2,
    }.items():
        make_loop(name, 16, root, "battle")

    for i in range(1, 4): make_hit(f"hit_slash_{i}", "slash", i * 17)
    make_hit("hit_blunt", "blunt", 81)
    make_hit("hit_pierce", "pierce", 82)
    make_hit("hit_magic", "magic", 83)
    make_hit("shield_block", "block", 84)
    make_hit("player_hurt", "hurt", 85)
    make_hit("critical_hit", "critical", 86)
    make_hit("boss_impact", "boss", 87)
    make_hit("enemy_defeat", "blunt", 88)

    make_chime("ui_click", [740], .14)
    make_chime("ui_back", [620, 420], .22, True)
    make_chime("confirm", [440, 660], .38)
    make_chime("ui_error", [220, 174], .42, True)
    make_chime("reward_claim", [523, 659, 784], .72)
    make_chime("purchase", [392, 523, 659], .62)
    make_chime("equip", [330, 495], .46)
    make_hit("forge", "block", 113)
    make_chime("level_up", [392, 523, 659, 784], .9)
    make_chime("choice_select", [523, 784], .34)
    make_chime("loot_rare", [659, 988, 1318], .9)
    make_chime("event_common", [330, 392], .5)
    make_chime("event_special", [392, 587, 784], .72)
    make_chime("event_rare", [523, 784, 1047], .82)
    make_chime("event_legendary", [392, 587, 880, 1175], 1.05)
    make_hit("boss_phase", "boss", 131)
    make_chime("victory", [261, 329, 392, 523], 2.2)
    make_chime("defeat", [220, 185, 147, 110], 2.1, True)
    make_chime("retreat", [294, 261, 220], 1.6, True)

    make_whoosh("recruit_contract", 90, .48)
    make_hit("recruit_seal", "block", 151)
    make_whoosh("recruit_rarity", 180, .72)
    make_chime("recruit_reveal", [392, 587, 784, 1175], 1.15)
    make_chime("recruit_featured", [523, 659, 784, 1047, 1318], 1.55)
    make_chime("duplicate_convert", [784, 659, 523], .7)

    roots = {"luna": 92, "kael": 65, "sera": 130, "nyra": 165, "aurel": 73,
             "vesta": 110, "rask": 58, "iris": 138}
    for name, root in roots.items():
        make_whoosh(f"ultimate_{name}_charge", root, .95)
        make_whoosh(f"ultimate_{name}_impact", root * .72, 1.15, True)

    # Compatibility aliases retained for older saves/tests and cached web
    # builds. Runtime code uses the semantic assets above.
    shutil.copyfile(OUT / "hit_slash_1.wav", OUT / "battle_hit.wav")
    shutil.copyfile(OUT / "ultimate_luna_impact.wav", OUT / "ultimate.wav")
    shutil.copyfile(OUT / "battle_gate_loop.wav", OUT / "battle_loop.wav")


if __name__ == "__main__":
    main()
