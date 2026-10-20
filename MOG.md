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
| Bluetooth connect | Flat menu-bar strip | Drop-down card: glyph, "Connected" / name, green battery ring (Droppy) |

All 6 commits are on `mog`. The `notch` and `notch-music` test suites pass.

## Plan for next session

1. **3D AirPods in the connect card.** Droppy and Alcove show a turning 3D render, while ours is the flat SF Symbol. Look for system 3D or device art first, such as Find My / CoreTypes device models or the `connectivityModel` approach. Then the card's glyph animates the way Droppy's does.
2. **Connect card, settle phase.** After about 2 s, Droppy collapses the card into compact wings (icon on the left, small ring on the right).
3. **GitHub remote**: done; see the sync workflow in `.github/workflows/upstream-sync.yml`.
4. Keep polishing pages against Droppy. Empty pages stay at full height (decided).

## Dev loop

- Build: `./build.sh --dev` (incremental, ~25 s). It runs as "Vorssaint (Developer)" (`com.vorssaint.utils.dev`), next to the real app.
- Dev prefs were copied from the real app, with `notchShowInCaptures=1` and `notchLiquidGlassEnabled=0` (solid black).
- Preview the connect card: `"build/stage.noindex/Vorssaint (Developer).app/Contents/MacOS/VorssaintDeveloper" --preview-notice "AirPods Pro"`.
- Screen captures run from the Claude Terminal panel, which has Screen Recording permission. The helper tools (`notchshot`, `burst`, `act`) are in the session scratchpad. Reference shots are in `ref/`, which is not committed.
- Update from upstream: `git fetch upstream && git merge upstream/main`.
