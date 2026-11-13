# Vector Aces — Fun City WWII Air Combat

First playable native macOS prototype, built using SwiftUI and SpriteKit. A 360-degree, top-down aerial dogfight with original code-drawn aircraft, countryside, cloud shadows, tracer fire and impact debris.

## Play
- Choose between P-51 Mustang, P-47 Thunderbolt, P-38 Lightning and P-40 Warhawk.
- **Left/Right or A/D**: turn; **Up/W**: accelerate; **Down/S**: brake. **Space**: fire. **P**: pause. **Return**: restart after losing. **Escape**: hangar.
- German fighter formations enter from any edge, break formation and pursue the player. Enemy aircraft fire when lined up; survive waves and build your score.
- Intentionally simplified arcade controls, not a simulator.

## Build (macOS 13+, Xcode 16+)
```sh
git clone https://github.com/peter-dietrich/vector-aces.git
cd vector-aces
open VectorAces.xcodeproj
# Choose VectorAces / My Mac, then Command-R.
# Or: xcodebuild -project VectorAces.xcodeproj -scheme VectorAces -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

GitHub feature branch: `feature/vector-aces-initial`. This early prototype has procedural silhouettes rather than final historically detailed models. Historically distinctive German aircraft artwork, sound design, mission variety, advanced telemetry and release packaging are subsequent development phases. The companion Fun City feature branch adds the built-in cabinet; install the built app locally and use LOCATE GAME.

No third-party artwork, trademarks as game artwork, audio recordings, or unlicensed assets have been incorporated. The game is intended as original arcade software inspired by WWII aviation history.

## Combat AI pass (development branch)

Enemy formations now use V, echelon, and paired-flight layouts. After formation flight, fighters intercept the player's path, line up shots, break away and regroup for additional attacks. Fw 190s and Bf 109s have different turn rates; Ju 87s remain slower and less maneuverable. A six-o'clock warning shows nearby rear threats. Multiple kills in quick succession earn combo bonuses. Aircraft silhouettes have extra visual detail, and destruction effects are larger.

This is unverified source until compiled and play-tested locally on macOS. Historical appearance, detailed sound design and full missions remain work to be done.

## Visual and camera pass (November 13, 2026)

- The fighter traverses the screen under its own velocity, with a soft-follow camera that pans only when it reaches an outer margin.
- Aerial terrain has an original offline procedural raster inspired by overhead satellite photography (fields, vegetation, rivers and grain). **This is not licensed real satellite imagery**. A true NASA/USGS photographic texture is a future asset-provenance task.
- Clouds now form irregular banks with soft radial opacity, varying scale and offsets; their shadows drift below.
- Aircraft have additional panel lines, engines, exhaust details, wing control markings, and relative size differences between fighters and dive bombers.
- No third-party map service or asset usage authorization is implied by this work.
- macOS compilation and frame-rate verification still require local testing in Xcode.

## Continuous ground terrain (latest development pass)

The earlier four repeated terrain textures have been replaced by a 3×3 streamed tile neighborhood. Tile keys are absolute world coordinates, so each tile uses unique world-sampled multiscale noise, field parcel colors, forests, roads, riverbeds, gravel verges, rural buildings and microtextures. Tiles are recreated deterministically when revisited, and tiles far outside the camera are discarded to control memory. The game continues to run without internet. This is generated aerial-style terrain **not actual satellite photographs**. Clouds, aircraft and controls were not intentionally changed in this pass.

**Testing note:** Texture creation is currently CPU-heavy and synchronous. Test macOS launch and sustained traversal for loading stutter and seams. True photographic imagery still requires separately cleared imagery data. The world coordinate fields are deterministic but do not correspond to a real geographic location.

## Geographically coherent terrain and HUD pass

- Corrects north/south raster row orientation so world-coordinate roads and rivers connect across texture tile boundaries.
- Replaces arbitrary isolated river/road patterns with a continuous winding main channel, a tributary, a river-parallel road, periodic crossing roads and explicit bridge crossings.
- Rural hamlets are now placed near dry-land road junctions with surrounding agricultural clearings rather than everywhere a road grid crosses.
- All scenery is still deterministic **procedural terrain**, not literal satellite photography.
- Fire origins now depend on aircraft: paired wing guns for P-51, P-47 and P-40; concentrated nose fire for P-38. Simplified arcade bursts represent historically inspired installations rather than a simulation of every individual barrel.
- Moves the compact translucent flight readout to the upper-right and adds a heading-up proximity radar to the lower-right. The six-o'clock alert sits below the telemetry.
- No additional flight-control keys. Xcode compile, screenshot validation and sustained frame-rate tests are still required.
