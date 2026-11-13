# Vector Aces — Fun City WWII Air Combat

First playable native macOS prototype, built using SwiftUI and SpriteKit. A hybrid cinematic 2D side-view dogfight with original code-drawn aircraft, clouds, mountain silhouettes, tracer fire and impact debris.

## Play
- Choose between P-51 Mustang, P-47 Thunderbolt, P-38 Lightning and P-40 Warhawk.
- **Arrow keys or WASD**: move. **Space**: shoot. **P**: pause. **Return**: restart after losing. **Escape**: hangar.
- Enemy aircraft stream in from the right. Survive waves, shoot down fighters and tougher bombers, and build your score.
- Intentionally simplified arcade controls, not a simulator.

## Build (macOS 13+, Xcode 16+)
```sh
git clone https://github.com/peter-dietrich/vector-aces.git
cd vector-aces
open VectorAces.xcodeproj
# Choose VectorAces / My Mac, then Command-R.
# Or: xcodebuild -project VectorAces.xcodeproj -scheme VectorAces -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
```

GitHub feature branch: `feature/vector-aces-initial`. This early prototype has procedural silhouettes rather than final historically detailed models. German aircraft types, audio, enemy weapons, missions, telemetry, and release packaging are subsequent development phases. The companion Fun City feature branch adds the built-in cabinet; install the built app locally and use LOCATE GAME.

No third-party artwork, trademarks as game artwork, audio recordings, or unlicensed assets have been incorporated. The game is intended as original arcade software inspired by WWII aviation history.
