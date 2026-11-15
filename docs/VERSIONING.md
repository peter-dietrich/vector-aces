# Vector Aces release versioning

## Source of truth
The Xcode project file (`VectorAces.xcodeproj/project.pbxproj`) defines **MARKETING_VERSION** and **CURRENT_PROJECT_VERSION** in BOTH the Debug and Release configurations. The SwiftUI game header reads `CFBundleShortVersionString` and `CFBundleVersion` from the app bundle rather than hardcoding a version number.

The current version is **2026.11.15 (3)**. A new release day increments the calendar-based marketing version `YYYY.MM.DD` (leading zeros permitted); further builds on that same day increment the integer build number. When a new marketing version is published, its build counter may reset to 1. Keep the two configurations identical.

## Release process
1. Complete gameplay/graphics changes on the working branch.
2. Update both `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `VectorAces.xcodeproj/project.pbxproj`.
3. Commit and push. Confirm the latest macOS GitHub Actions build is successful.
4. On the Mac: `git pull --ff-only origin feature/vector-aces-initial`, build/run in Xcode, and verify the header version matches.
5. Merge after visual and mission-flow testing. Do not infer gameplay correctness from compiler success alone.

## Tempo and early-warning changes introduced with build 3
- Global flight/AI/combat movement simulation uses a **1.20×** rate multiplier, preserving the user-visible real-time mission clock. The speed tape displays the correspondingly scaled simulated speed.
- Strategic radar sees to **12,500 world units**, distinguishes bombers and other contacts and shows their relative flight direction.
- The active mission's targeting now shows clock-bearing and range; the early-warning panel reports the number of inbound bomber flights, strike ETA and next scheduled flight countdown.
- Predicted contacts appear at the radar perimeter shortly before new bomber pairs arrive; bomber symbols and priority rings remain distinguishable between sweeps.
- The hangar uses original three-view, sepia technical aircraft drawings, not linked photos. Mission briefings use portrait-era operations orders with period typography, routing and stamps.

## QA priorities
- At different window sizes, verify briefing page remains readable and result debrief resets extra briefing lines and stamps.
- Verify all four aircraft have distinct technical plate illustrations, with the small original plane icon in the lower corner.
- Check radar bearings and objective strike ETA against a Stuka formation's actual course; expect some rounding because this is arcade distance.
- Test Easy, Medium and Hard for pace and mission viability, since faster AI may require tuning.
