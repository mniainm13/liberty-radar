# Liberty Radar

A minimalist circular radar for Helldivers 2 — you are the center, your
view is up, and everything that wants you dead is a dot.

> Screenshot coming with the first tagged release.

## Features

| Contact | Marker |
| --- | --- |
| Heavy enemy (Charger, Bile Titan, Hulk, Factory Strider, ...) | Large red dot |
| Small enemy | Small yellow dot |
| Destructible structure (bug holes, nests, shrieker towers, bot factories, Illuminate spires, warp ships, ...) | Red hollow ring |
| Samples | Green triangle |
| Ammo box | Blue triangle |
| Grenade box | Blue circle |
| Stim pack | Blue cross |
| You | Green hollow triangle with center pip |

- **Player-centered, view-rotated** — the radar turns with your camera;
  "up" is always where you look.
- **Smooth at any framerate** — contact data is sampled at 10 Hz and
  interpolated + re-projected every frame. Typical cost: 40–60 µs per
  frame (well under 1% of a frame budget).
- **Works in co-op**, as host **and** as client.
- **Read-only** — never writes game memory, never sends packets.
- **Fails safe** — a build-stamp assertion checks the game binary before
  touching any offset, so a patched game disables the radar instead of
  reading garbage.

## Installation

1. Install the [Helldivers 2 Mod Manager](https://www.nexusmods.com/helldivers2/mods/5)
   (HD2MM).
2. Download `Liberty-Radar-x.y.z.zip` from
   [Releases](../../releases) and drop it into HD2MM.
3. Enable **Liberty Radar** (and the **Bingus Shared Loader** it depends
   on — recent HD2MM installs it automatically) and deploy.

## Settings

With [Mod Options Menu](https://www.nexusmods.com/helldivers2/mods/3316)
installed, a **Liberty Radar** tab appears in the in-game MODS menu with
live controls: radar range, size, screen position, disc tilt,
perspective, dot size, max dots, scan interval, and hide-while-menu.
Settings persist to `LibertyRadar.cfg` and can also be edited by hand.

## Building from source

```
python tools/build_addon.py --name mods/libertyradar/radar \
    --entry src/radar.lua \
    --guid efc9df26-c68d-4518-b63c-d811f632b42a \
    --display-name "Liberty Radar" \
    --output Liberty-Radar-x.y.z.zip
```

Requires Python 3.8+; no third-party packages.

## Known issues

- Destroyed **bug holes** (the plain holes that stop spawning, not big
  nests) may keep their ring until the mission ends — the game exposes
  no reliable "sealed" state for them. Everything with a health bar
  (nests, towers, factories, ...) clears the moment it dies.
- Medals / Requisition / Super Credits are not marked yet.

## Credits

- **Bingus Shared Loader** and its addon format — the runtime this mod
  lives on.
- The HD2 modding community's public write-ups on entity managers and
  the GUI layer, which shaped the data path.

## License

[MIT](LICENSE)
