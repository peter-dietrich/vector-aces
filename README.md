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
