# TRAJECTORY SPECIFICATION

## Overview
The trajectory model is a mathematical estimation of where the spit will land based on vehicle speed, spit velocity, and wind.

## Status
[OPTIONAL] - Do not let this block the core hackathon demo.

## Implementation
If implemented, use simple parabolic physics:
- `Vx = Vehicle_Speed + Spit_Speed * cos(Pitch) - Wind_Speed`
- `Vy = Spit_Speed * sin(Pitch) - Gravity * t`

This is purely for visual flair in the HUD and score calculation.
