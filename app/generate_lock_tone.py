#!/usr/bin/env python3
# generate_lock_tone.py — SAFE//SPIT
# Generates a synthetic tactical lock-tone MP3-compatible WAV file.
# Used when a proper audio asset is not available (D-18 fallback).
# Run from the app/ directory: python generate_lock_tone.py

import wave
import struct
import math
import os

def generate_lock_tone(filename: str, duration_sec: float = 0.5,
                        sample_rate: int = 44100):
    """Generate a tactical beep sequence: two short rising tones."""
    num_frames = int(sample_rate * duration_sec)
    
    def tone_frame(t, freq, amplitude=0.6):
        return amplitude * math.sin(2 * math.pi * freq * t)
    
    frames = []
    for i in range(num_frames):
        t = i / sample_rate
        # Two-tone rising sequence (tactical lock sound)
        if t < 0.15:
            # First tone: 880 Hz (A5)
            val = tone_frame(t, 880)
        elif t < 0.20:
            # Brief silence
            val = 0.0
        elif t < 0.35:
            # Second tone: 1320 Hz (E6) — higher = "locked"
            val = tone_frame(t, 1320)
        elif t < 0.40:
            val = 0.0
        else:
            # Final confirmation tone: 1760 Hz (A6)
            val = tone_frame(t, 1760) * (1.0 - (t - 0.40) / 0.10)
        
        # Apply fade-in/out
        fade_samples = int(0.01 * sample_rate)
        if i < fade_samples:
            val *= i / fade_samples
        elif i > num_frames - fade_samples:
            val *= (num_frames - i) / fade_samples
        
        # Convert to 16-bit signed int
        sample = int(val * 32767)
        sample = max(-32768, min(32767, sample))
        frames.append(struct.pack('<h', sample))
    
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with wave.open(filename, 'w') as wav:
        wav.setnchannels(1)  # Mono
        wav.setsampwidth(2)  # 16-bit
        wav.setframerate(sample_rate)
        wav.writeframes(b''.join(frames))
    
    print(f"Generated: {filename} ({os.path.getsize(filename)} bytes)")

if __name__ == '__main__':
    generate_lock_tone('assets/audio/lock_tone.wav')
    print("Note: Rename to lock_tone.mp3 or update pubspec.yaml to reference .wav")
    print("For production, replace with a properly mastered audio asset.")
