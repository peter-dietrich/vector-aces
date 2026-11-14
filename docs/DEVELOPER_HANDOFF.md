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

## Latest telemetry/radar redesign (2026-11-13)
- Replaced flat seven-line telemetry with 19 data rows grouped into mission, aircraft, tactical, and flight systems sections.
- Typography mirrors Vector Drift's Menlo, cyan score and high-importance numerics, amber section headings, muted supporting text, thin lines, and vertical amber accent.
- Added saved best score, wave/kills/contacts, airframe/ammo, speed/altitude, heading/vertical speed, altitude band and health-derived engine-status label.
- Added nearest hostile clock bearing and world-space range as well as contact count within radar radius.
- Radar detection radius is 2400 game-world units (previously ~530), with nonlinear distance compression, dimmer/smaller distant contacts, preserved rotating sweep and contact decay.
- Real-world yards are intentionally **not** claimed: units represent simulated game-world distance.
- Existing attitude instrument and radar remain below the telemetry section; gameplay and top/bottom header/footer controls remain unchanged.
- Validate that the right-side instruments remain legible at the minimum scene/window size; radar and telemetry only compile-tested by CI, not runtime/visual-tested.

## Mission gameplay — Phase 1 (November 13, 2026)
- Hangar now has **Stop the Stukas** (default) and **Endless Dogfight** mode selection; Endless remains the previous arcade loop.
- Mission 01 briefing is shown over the field. Press **Return** to launch; key controls otherwise unchanged.
- Airfield is a distinct runway/hangar target anchored to the scrolling terrain, shown as a green square on radar.
- Six Ju 87 Stukas spawn as three scheduled pairs at approximately 2s, 30s, and 58s and pursue the allied airfield; escorted by Fw 190s that engage the player.
- Each Stuka reaching the airfield consumes one of three airfield defense points; the player must shoot down at least four of six before the time expires (150s) while retaining at least one airfield defense point.
- Mission ends in a clear victory/failure debrief, showing bomber kills/escapes, damage, escorts, score, and star outcome. Return retries after a result.
- Mission results have an optional local best mission score. Free-flight saved games remain separate; Save/Resume toolbar is intentionally disabled during missions.
- Telemetry remains in Vector Drift style; short mission objective status appears at the upper-left of the field during active flight.
- **Must run macOS build and gameplay QA:** verify mission spawns, actual airfield intercepts, visible radar targeting, outcomes, restart, pause, and original endless game. Mission timing and difficulty are initial tuning values and should be adjusted after user playtest.

## Phase 2 — Enemy dogfighting AI (November 13, 2026)
- Added distinct flight roles: **interceptor (Bf 109)**, **hunter (Fw 190)**, **escort (mission Fw 190)**, and **bomber (Ju 87)**, with mission bomber objective behavior retained.
- Fighters operate through formation, lead intercept, flank, firing pass, evade, breakaway and regroup. Squadron flight IDs and wing indices provide deterministic opposite-flank approaches within each group.
- Escorts stay with their bomber group outside close-combat range, then maneuver and intercept the player while bombers continue the objective run.
- Bf 109 has a higher turn rate and tighter maneuvering; Fw 190 favors faster firing passes. Ju 87 mission bombers retain their airfield run.
- Fighters react defensively when player lines up a rear attack and to nonfatal bullet hits, with cooldowns to avoid constant evasive zig-zags.
- Limit simultaneous attack slots by difficulty (Rookie 1, Veteran 2, Ace 3), adjust aim tolerances, range, and shot cooldowns; leave existing flight controls unchanged.
- Radar, telemetry, terrain, audio, mission and endless modes are intended to remain operational.
- Verify on Mac: can track a retreating Bf 109, see two Fw 190s flank rather than stack, observe evasive reactions after shooting, and complete Stop the Stukas despite escort pressure.
- **Build verification must be checked for the final commit.** Previously an intermediate commit failed an exhaustive switch check after enum expansion; later updates replaced that switch. The Xcode build/mission balancing need verification.

## Phase 3 — Tactical Flight (Nov 13, 2026)
- Q climbs, E descends. Climbing now costs airspeed and maneuver energy; diving restores speed and can unlock **BOOM & ZOOM** score rewards for successful kills. Fast flight improves turning response without making slow turns impossible.
- Player and German aircraft have individual altitudes. Fw 190 and Bf 109 adjust their altitude toward the player; mission Stukas gradually descend toward their airfield objective. Projectile impacts and aircraft collision require compatible altitude rather than a 2D screen overlap alone.
- Original visual cloud banks now define altitude bands: near matching altitude and position, cloud concealment prevents long-range AI attacks and suppresses precise lead-aiming cues; close-range gunfights remain possible.
- Predictive cyan lead reticle appears on a close, forward, altitude-matched and unobscured hostile. It is a gunnery aid, not auto-aim.
- Below 700 feet the game warns about terrain; an unrecovered descent below the ground threshold starts player crash. User should test whether this feels fair.
- Fighters have different turn, climb and dive profiles. The Thunderbolt has the strongest dive; the Warhawk turns fastest in this arcade interpretation.
- A discreet tactical prompt indicates cloud cover, climbing energy drain, dive-attack opportunity and low-altitude warning; existing Vector Drift-styled telemetry now reports ENERGY and COVER.
- Endless run save/restore preserves flight energy alongside altitude, speed and heading. Mission 01 and Endless controls and selection remain unchanged.
- **Runtime QA required:** assess Q/E responsiveness, climb versus dive tradeoff, altitude-mismatch combat fairness, radar/lead cues, cloud concealment, terrain warning, bombers/escorts at mission altitudes and Mac audio performance. CI compilation checks do not validate gameplay feel.

## Phase 4 — Campaign & progression (November 13, 2026)
- Four selectable campaign missions in the hangar; missions 2–4 unlock sequentially after successful preceding missions. Endless Dogfight remains separate.
  1. **Stop the Stukas:** existing six Ju 87 airfield-defense mission, four kills required.
  2. **Bomber Escort:** three allied B-17 stand-ins visually use distinct light-colored multi-engine silhouette; four waves of German interceptors target allied formation; keep two of three allies alive until 95-second extraction.
  3. **Hunt the Ace:** red elite Fw 190 with high durability and two wingmen, defeat before 125 seconds.
  4. **Defend the Bridge:** river/bridge objective rendered distinctly, eight Stukas over four waves; destroy five and preserve bridge before 155-second limit.
- New **Pilot Record** panel shows lifetime sorties, victories, kills, score, rank, per-mission star awards, personal best scores and earned/locked medals. Pilot progress uses local UserDefaults and is not network/cloud-synced.
- Ranks: Flight Officer -> Lieutenant -> Captain -> Major -> Squadron Leader; medals include First Victory, Guardian, Ace Hunter, Campaign Veteran, Perfect Sortie.
- Mission debrief records success/failure, score, damage, progress, and new award. Mission selection stores the last mission; locked missions are disabled.
- Mission scores are deliberately arcade/approximate; not historically sourced aircraft performance metrics.
- **Mac gameplay QA required:** test missions one by one, verify unlocks, stars, medal awards, ace kill, allied bomber survival under escort attacks, bridge damage and win/loss. Validate that switching to Endless preserves the older experience and save/resume.
- GitHub Actions macOS Xcode CI compiles code, but cannot validate gameplay balance, mission pacing, precise AI tactics or visuals.

## Graphical HUD refactor — November 13, 2026
- Replaced the old text-heavy right telemetry and duplicated attitude/radar blocks with two independent SpriteKit HUD node classes in `Sources/VectorAcesApp.swift`: `LeftFlightHUDNode` and `RightCombatHUDNode`.
- Left: large bank/pitch horizon, airspeed dial and energy arc, moving altimeter tape/vertical speed indicator, aircraft silhouette with damage-based color and condition pips.
- Right: prominently displayed score, wave and kill/contact count; target-bearing compass with rear-threat pulse, ammo counter and ammo bar, mission progress pips/objective health shield, countdown arc, enlarged long-range 2400-unit radar showing enemy fighters, bombers, ace, allies and mission objective.
- Graphical primitives use reusable `AcesHUDVisual` helpers. Values from live scene state are delivered via `AcesFlightHUDValue` and `AcesCombatHUDValue`. Persistent nodes and refreshed radar contacts avoid rebuilding every panel each frame.
- Original top SwiftUI header and bottom control footer retained. Gameplay and mission/Endless state unchanged; mission status moved to upper center for clearance.
- Inspect Mac screenshots at 1000×670 minimum and full screen, tune HUD transparency and gauge sizing. Confirm radar, targets, mission progress and alerts are understandable visually.
- **Important:** macOS CI build must be checked on latest commit; several intermediate commits failed Swift syntax and were repaired. Do not claim a passing build until latest successful check.
