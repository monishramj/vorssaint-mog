# vorssaint-mog

A personal fork of [vorssaint/vorssaint-utils](https://github.com/vorssaint/vorssaint-utils). Its notch looks and moves like Alcove and Droppy. Changes are kept small and marked `// mog:` so upstream merges stay easy.

## Changes so far (branch `mog`)

| Area | Before | Now |
|---|---|---|
| Open | Island grew empty for ~160 ms, then content faded in | Content blurs in while the island grows (Alcove) |
| Close | Content vanished; empty black box held ~150 ms, then shrank | Old page blurs, fades and shrinks with the island; no hold |
| Player controls | Big 5-slot transport, 44 pt row | Droppy-style compact, evenly spaced row (36 pt); island 8 pt shorter |
| Progress bar | ~8 pt thick | 5 pt (Alcove/Droppy) |
| Hover | Circle highlight | Rounded-square highlight (Droppy) |
| Equalizer | Grey | Album-art tint (Droppy waveform) |
| Nothing playing | Full player with "Nothing playing" + buttons | Just the cover row; cover opens the player |
| Bluetooth connect | Flat strip, flat SF Symbol | Same flat strip; the device's real 3D model turns in the icon slot (pre-rendered sprite sheets, ~21 MB peak). Run `Tools/fetch-device-models.sh` once; the models stay local. |
| Play/pause | Waited for Spotify's round trip | Glyph flips instantly; reverts if the player refuses |
| "Playback failed" (orange) | Shown on slow player replies | Only on real errors |
| Song switch | Hard swap, ~1 s hold | Switches as soon as the player reports the next song; title blur-swaps, cover blurs in once per song |
| No-length streams (Spotify DJ) | Empty timeline gap | Timeline row dropped; island fits |

All 6 commits are on `mog`. The `notch` and `notch-music` test suites pass.

## Plan for next session

2. Keep polishing pages against Droppy. Empty pages stay at full height (decided).
3. Keep checking idle cost after each feature. As of 2026-10-20 the fork idles at 0.8% CPU / 28 MB against upstream's 1.4% / 37 MB, both debug builds.

## Dev loop

- Build: `./build.sh --dev` (incremental, ~25 s). It runs as "Vorssaint (Developer)" (`com.vorssaint.utils.dev`), next to the real app.
- Dev prefs were copied from the real app, with `notchShowInCaptures=1` and `notchLiquidGlassEnabled=0` (solid black).
- Preview the connect card: `"build/stage.noindex/Vorssaint (Developer).app/Contents/MacOS/VorssaintDeveloper" --preview-notice "AirPods Pro"`.
- Screen captures run from the Claude Terminal panel, which has Screen Recording permission. The helper tools (`notchshot`, `burst`, `act`) are in the session scratchpad. Reference shots are in `ref/`, which is not committed.
- Update from upstream: `git fetch upstream && git merge upstream/main`.
