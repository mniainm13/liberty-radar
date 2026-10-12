# Changelog

## 1.1.0 (2026-10-12)

First public release.

- Circular bottom-center radar: player-centered, view-rotated, 60 fps
  rendering with 10 Hz sampling + per-frame interpolation.
- Enemy contacts: heavy units as large red dots, small units as yellow
  dots (hash-classified).
- Destructible structures (bug holes, nests, shrieker towers, bot
  factories, Illuminate structures, warp ships) as red hollow rings;
  health-tracked structures clear the moment they die.
- Samples (green triangle), ammo boxes (blue triangle), grenade boxes
  (blue circle), stim packs (blue cross).
- Co-op support: renders correctly as host and as client (replicated
  health table fallback for the client's mirror roster).
- Mod Options Menu integration: 10 live settings, persisted to
  `LibertyRadar.cfg`.
- Performance: ~40–60 µs per frame; static layers refresh at 500 ms,
  frame-scoped color cache.
- Read-only memory access with a game build-stamp assertion.
