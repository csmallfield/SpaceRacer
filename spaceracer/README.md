# Pseudo 3D Racer

A classic pseudo-3D racing game in the style of OutRun and Road Rash, built with Godot 4.4.

## Overview

This project implements a pseudo-3D road rendering engine using techniques popularized in arcade racing games of the late 1980s and early 1990s. Instead of true 3D polygon rendering, the road is drawn using projected line segments with perspective scaling, creating that distinctive "Mode 7" look.

## Features

- **Pseudo-3D Road Rendering**: Authentic retro-style road with curves and hills
- **Z-Map Based Projection**: Proper perspective with configurable draw distance
- **Segmented Track System**: Roads made of segments with individual curve/hill values
- **Roadside Scenery**: Placeholder sprites for trees, rocks, buildings, signs
- **Player Car Physics**: Speed, steering, off-road penalties, centrifugal force
- **AI Opponents**: 3 AI cars with Easy/Medium/Hard difficulty levels
- **Race HUD**: Speed, position, lap counter, race timer
- **Fog Effect**: Distance-based fog for depth perception

## Controls

| Action | Key |
|--------|-----|
| Accelerate | W / Up Arrow |
| Brake | S / Down Arrow |
| Steer Left | A / Left Arrow |
| Steer Right | D / Right Arrow |
| Reset Race | R |
| Quit | Escape |

## Project Structure

```
pseudo3d_racer/
├── project.godot           # Godot project configuration
├── icon.svg                # Project icon
├── scenes/
│   └── main.tscn           # Main game scene
└── scripts/
    ├── main.gd             # Main game orchestration
    ├── autoload/
    │   └── game_manager.gd # Race state singleton
    ├── road/
    │   ├── road_renderer.gd    # Core pseudo-3D rendering
    │   ├── track.gd            # Track data structure
    │   ├── track_segment.gd    # Individual segment data
    │   └── roadside_sprite.gd  # Roadside object data
    ├── cars/
    │   ├── player_car.gd   # Player vehicle
    │   └── ai_car.gd       # AI opponent
    └── ui/
        └── race_hud.gd     # Race information display
```

## Technical Details

### Resolution
- Internal: 960x540 (16:9)
- Window: 1920x1080 (2x scaled)
- Canvas stretch mode for pixel-perfect scaling

### Rendering Approach
The road is rendered using the "3D-projected segments" technique:

1. **Z-Map**: Each scanline has a precalculated depth value
2. **Segment Projection**: Road segments are projected to screen space
3. **Curve Application**: Horizontal offset accumulates based on segment curve values
4. **Hill Application**: Vertical offset modifies Y position based on segment hill values
5. **Painter's Algorithm**: Segments drawn back-to-front for proper occlusion

### Track Data
Tracks are built from segments, each with:
- `curve`: Horizontal bend (-ve = left, +ve = right)
- `hill`: Vertical slope (-ve = down, +ve = up)
- `length`: Segment length in world units
- `sprites`: Attached roadside objects

## Customization

### Creating New Tracks
Edit `track.gd` and use the track building methods:

```gdscript
var track = Track.new()
track.add_straight(3000.0)           # Straight section
track.add_curve_left(2000.0, 1.0)    # Left curve
track.add_hill_up(1000.0, 1.5)       # Uphill
track.add_s_curve(2000.0, 0.8)       # S-curve
```

### Adjusting Visuals
In `track.gd`, modify the color exports:
- `road_color_light/dark`: Alternating road colors
- `rumble_color_light/dark`: Rumble strip colors
- `grass_color_light/dark`: Roadside grass colors
- `sky_color`, `horizon_color`: Sky gradient

### Physics Tuning
In `player_car.gd`:
- `MAX_SPEED`: Top speed
- `ACCELERATION`: How fast car speeds up
- `STEERING_SPEED`: Turn rate
- `CENTRIFUGAL_FORCE`: How much curves push the car

In `ai_car.gd`:
- Adjust difficulty presets for AI behavior

## Placeholder Graphics

All graphics are currently placeholder rectangles. To add real graphics:

1. **Car Sprites**: Replace the `_draw()` methods in `player_car.gd` and `ai_car.gd`
2. **Roadside Sprites**: Add textures to `sprite_textures` dictionary in `road_renderer.gd`
3. **Background**: Implement parallax scrolling horizon in `road_renderer.gd`

## References

This implementation is based on techniques described in:
- [Lou's Pseudo 3D Page](http://www.extentofthejam.com/pseudo/)
- Classic games: OutRun, Road Rash, Lotus Turbo Challenge

## License

This is a prototype/educational project. Feel free to use and modify.
