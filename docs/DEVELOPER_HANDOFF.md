# VECTOR ACES — DEVELOPER HANDOFF (2026-11-13)

## Project and Git
- Standalone native macOS arcade game, SwiftUI + SpriteKit, in `peter-dietrich/vector-aces`.
- Work is on `feature/vector-aces-initial`; PR #1 to `main` remains unmerged.
- `peter-dietrich/fun-city` has separate integration PR #10 (same branch name) adding the Vector Aces cabinet and release mapping. Do not merge or modify other games without a separate request.
- Game bundle ID: `io.vectoraces.game`.
- Run: `git fetch origin && git switch feature/vector-aces-initial && git pull --ff-only origin feature/vector-aces-initial && open VectorAces.xcodeproj`.
- Validate with `xcodebuild -project VectorAces.xcodeproj -scheme VectorAces -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build`.
- A GitHub Actions macOS compilation workflow was added at `.github/workflows/macos-build.yml`; check latest run status before accepting build success.

## User-approved design
- Fun City arcade family with Vector Drift-inspired presentation, top-down 360-degree WWII dogfights.
- Only basic keys: left/right or A/D turn, up/W speed up, down/S slow down, Space fires, Q climb, E descend, P pause, Return restart after loss.
- Four American selectable fighters: P-51D Mustang, P-47 Thunderbolt, P-38 Lightning, P-40 Warhawk.
- German enemies include Fw 190, Bf 109, Ju 87; formations arrive from different directions, break into individual intercept, attack, breakaway and regroup tactics.
- Enemy airframe scale should remain proportional to the player; all aircraft reduced 10% from previous version.
- Aircraft-specific wing guns and P-38 center-nose battery.
- Moving camera with generous free flight, unique deterministic procedurally rendered terrain, connected rivers/roads, villages near road junctions. Cloud banks acceptable for now. No actual satellite images used.
- Shot-down aircraft descend/spiral, smoke, explode with debris and screen shake; both player and enemy.
- Vector Drift-inspired right-side translucent Menlo telemetry; artificial horizon/attitude dial above fading rotating radar.
- New premium hangar catalog: selectable fighters on left; detailed schematic and strengths, performance bars and explanatory descriptions on right.
- User wants playable fun and visual detail, not a realistic simulator.

## Implemented in feature branch (code review and Mac runtime still needed)
- Aircraft catalog profiles and technical-style vector illustrations.
- UserDefaults custom settings form: difficulty, enemy/cloud density, starting wave, unlimited ammo, radar/telemetry, sound volumes and shake intensity.
- Autosaved sortie snapshot + Resume Sortie action, fighter selection persisted.
- Climb/descend altitude with mild energy tradeoff.
- Aircraft-specific finite ammunition and telemetry counter.
- Two-stage spiraling fatal plane animations with particle smoke/debris and scene shake.
- Radar rotating sweep, dimming trail and blip persistence; aircraft attitude instrument.
- Synthesized looping engine, shot, damage, explosion, threat and selection sounds.
- macOS GitHub Actions compilation job was added. Check its latest status; a previous compiler failure due to a duplicate `else` was corrected in a follow-up commit.

## Follow-up QA and expected polish
1. **Check GitHub Actions first**. Do not claim compilation success without a passing run.
2. On Mac, test all four aircraft selection, flight controls and wings/nose muzzle origins, radar alignment, attitude change, altitude, ammo depletion and unlimited ammo mode.
3. Shoot down an enemy and lose player plane: validate timed animation, explosion, smoke, screen shake, and Return restart (including reattaching player node).
4. Test long flights for terrain tile seams/stutter and reentry to old areas; terrain generation is synchronous and may need asynchronous tile creation.
5. Test catalog on 1000x670 minimum window and larger; ensure no clipped stats.
6. Test custom settings persistence, autosave and resume with the same fighter, close/reopen behavior and no resume after game-over.
7. Sound placeholders are original synthesizer effects, not recorded airplane engines. Realistic WW2 sounds need licensed or newly created audio.
8. Hero aircraft illustration is code-drawn, not a high-resolution photorealistic aircraft image; refine distinct P-47/P-40/P-38/P-51 silhouettes.
9. Higher confidence realism would require properly licensed high-resolution aerial imagery (NASA/USGS or independently sourced) and aircraft reference art.
10. Keep changes on PR #1 until reviewed and Mac runtime-validated, then merge only with approval.

## Known technical cautions
- Xcode build may reveal additional Swift type-checking errors; the assistant cannot run macOS apps in its environment.
- Existing radar is redrawn periodically; monitor performance on sustained waves.
- UserDefaults stores settings and flight snapshots, not cloud state or live enemies.
- Original `vector-aces` repository is public; avoid committing licensed third-party media or secrets.

## Developer interaction style
- Apply code edits directly through the connected GitHub tool, then give precise `git pull` and `open`/Xcode commands.
- Keep brief phase/status updates grounded in actual changes.
- User prefers early warning when a thread is approaching capacity and complete copy-forward prompts into new conversations.
