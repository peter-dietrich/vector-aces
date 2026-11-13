import AppKit
import SwiftUI
import SpriteKit

enum Fighter: String, CaseIterable, Identifiable {
    case mustang = "P-51D Mustang", thunderbolt = "P-47 Thunderbolt", lightning = "P-38 Lightning", warhawk = "P-40 Warhawk"
    var id: String { rawValue }
    var speed: CGFloat {
        switch self { case .mustang: return 300; case .thunderbolt: return 255; case .lightning: return 275; case .warhawk: return 315 }
    }
    var health: Int {
        switch self { case .thunderbolt: return 7; case .lightning: return 6; default: return 5 }
    }
    var color: SKColor {
        switch self { case .mustang: return .init(red: 0.85, green: 0.9, blue: 0.96, alpha: 1)
        case .thunderbolt: return .init(red: 0.57, green: 0.73, blue: 0.58, alpha: 1)
        case .lightning: return .init(red: 0.75, green: 0.84, blue: 0.88, alpha: 1)
        case .warhawk: return .init(red: 0.48, green: 0.61, blue: 0.41, alpha: 1) }
    }
}

@main struct VectorAcesApp: App {
    @State private var fighter: Fighter = .mustang
    @State private var started = false
    var body: some Scene {
        WindowGroup("Vector Aces") {
            ZStack {
                Color(red: 0.045, green: 0.065, blue: 0.12).ignoresSafeArea()
                if started {
                    GameSurface(fighter: fighter)
                        .id(fighter)
                        .overlay(alignment: .topTrailing) {
                            Button("HANGAR") { started = false }
                                .keyboardShortcut(.escape, modifiers: [])
                                .padding(14)
                        }
                } else {
                    VStack(spacing: 22) {
                        Text("FUN CITY  /  VECTOR SERIES").font(.system(size: 12, weight: .bold, design: .monospaced)).tracking(3).foregroundStyle(.orange)
                        Text("VECTOR ACES").font(.system(size: 58, weight: .black, design: .rounded)).tracking(3)
                        Text("WWII AIR COMBAT").font(.system(size: 17, weight: .bold, design: .monospaced)).tracking(5).foregroundStyle(.cyan)
                        Text("SELECT YOUR FIGHTER").font(.system(size: 12, weight: .bold, design: .monospaced)).foregroundStyle(.gray)
                        ForEach(Fighter.allCases) { choice in
                            Button {
                                fighter = choice
                            } label: {
                                HStack {
                                    Text(choice.rawValue)
                                    Spacer()
                                    if choice == fighter { Image(systemName: "checkmark.circle.fill") }
                                }
                                .font(.system(size: 18, weight: .semibold, design: .monospaced))
                                .padding(15).frame(width: 430)
                                .background(choice == fighter ? Color.cyan.opacity(0.23) : Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 9))
                            }.buttonStyle(.plain)
                        }
                        Button("START SORTIE  ↗") { started = true }
                            .font(.system(size: 19, weight: .black, design: .monospaced))
                            .padding(.horizontal, 44).padding(.vertical, 16)
                            .background(.orange, in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(.black)
                        Text("←/→ TURN   ↑ THRUST   ↓ BRAKE   SPACE FIRE   P PAUSE   RETURN RESTART")
                            .font(.system(size: 11, design: .monospaced)).foregroundStyle(.gray)
                    }.padding(25)
                }
            }
            .preferredColorScheme(.dark)
            .frame(minWidth: 900, minHeight: 620)
        }
        .defaultSize(width: 1240, height: 760)
    }
}

private struct GameSurface: NSViewRepresentable {
    let fighter: Fighter
    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.presentScene(AirBattleScene(size: CGSize(width: 1200, height: 720), fighter: fighter))
        DispatchQueue.main.async { view.window?.makeFirstResponder(view.scene) }
        return view
    }
    func updateNSView(_ nsView: SKView, context: Context) {}
}


private final class AirBattleScene: SKScene {
    private enum Tactic { case formation, intercept, attack, breakAway, regroup }
    private struct Bandit {
        let sprite: SKNode
        var position: CGPoint
        var heading: CGFloat
        var speed: CGFloat
        var health: Int
        let kind: Int  // 0 Fw 190, 1 Bf 109, 2 Ju 87
        var formationTime: CGFloat
        var fireCooldown: CGFloat
        var targetOffset: CGFloat
        var tactic: Tactic
        var tacticTime: CGFloat
        var maneuverSign: CGFloat
        var entryHeading: CGFloat
        var previousDistance: CGFloat
    }
    private struct Round {
        let sprite: SKShapeNode
        var position: CGPoint
        let velocity: CGVector
        var lifetime: CGFloat
        let hostile: Bool
    }
    private let fighter: Fighter
    private var player = SKNode()
    private var keys = Set<UInt16>()
    private var bandits: [Bandit] = []
    private var rounds: [Round] = []
    private var effects: [SKNode] = []
    private var environment = SKNode()
    private var terrainTiles: [String: SKSpriteNode] = [:]
    private var terrainOffset = CGPoint.zero
    private var cloudClusters: [SKNode] = []
    private let terrainTileSize: CGFloat = 1024
    private var lastTime: TimeInterval = 0
    private var gameTime: CGFloat = 0
    private var lastFire: CGFloat = -1
    private var lastFormation: CGFloat = -8
    private var heading: CGFloat = .pi / 2
    private var airspeed: CGFloat = 210
    private var health: Int
    private var score = 0
    private var kills = 0
    private var wave = 1
    private var pausedGame = false
    private var gameOver = false
    private var invulnerableUntil: CGFloat = 0
    private let hud = SKLabelNode(fontNamed: "Menlo-Bold")
    private let status = SKLabelNode(fontNamed: "Menlo-Bold")
    private var lastWarning: CGFloat = -10
    private var hitCombo = 0
    private var comboDeadline: CGFloat = 0
    private let threat = SKLabelNode(fontNamed: "Menlo-Bold")
    private let telemetryPanel = SKShapeNode()
    private let telemetryLines = (0..<7).map { _ in SKLabelNode(fontNamed: "Menlo-Bold") }
    private let radarPanel = SKShapeNode()
    private let radarContacts = SKNode()
    private var gunCycle = 0

    init(size: CGSize, fighter: Fighter) {
        self.fighter = fighter
        self.health = fighter.health
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
    }
    required init?(coder: NSCoder) { fatalError("Not supported") }
    override var acceptsFirstResponder: Bool { true }
    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.16, green: 0.31, blue: 0.32, alpha: 1)
        addChild(environment)
        buildGround()
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        player.zPosition = 20
        player.addChild(drawAircraft(kind: -1, color: fighter.color))
        player.zRotation = heading - .pi / 2
        addChild(player)
        hud.fontSize = 14
        hud.horizontalAlignmentMode = .left
        hud.verticalAlignmentMode = .top
        hud.zPosition = 100
        addChild(hud)
        status.fontSize = 29
        status.zPosition = 100
        addChild(status)
        threat.fontSize = 14
        threat.fontColor = .orange
        threat.horizontalAlignmentMode = .right
        threat.zPosition = 101
        addChild(threat)
        installTelemetry()
        updateLabels()
        view.window?.makeFirstResponder(self)
    }
    override func didChangeSize(_ oldSize: CGSize) {
        hud.position = CGPoint(x: 24, y: size.height - 22)
        status.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        threat.position = CGPoint(x: size.width - 25, y: size.height - 50)
        layoutTelemetry()
        if player.position == .zero { player.position = CGPoint(x: size.width / 2, y: size.height / 2) }
    }
    override func keyDown(with event: NSEvent) {
        keys.insert(event.keyCode)
        if event.keyCode == 35 && !event.isARepeat && !gameOver {
            pausedGame.toggle()
            status.text = pausedGame ? "PAUSED — P TO RESUME" : ""
        }
        if event.keyCode == 36 && gameOver { restart() }
    }
    override func keyUp(with event: NSEvent) { keys.remove(event.keyCode) }
    override func resignFirstResponder() -> Bool {
        keys.removeAll()
        return super.resignFirstResponder()
    }

    private func drawAircraft(kind: Int, color: SKColor) -> SKNode {
        // Original top-down silhouettes: -1 = selected US fighter, 0 = Fw 190,
        // 1 = Bf 109, 2 = Ju 87 Stuka with identifiable gull wings.
        let node = SKNode()
        let isStuka = kind == 2
        let isLightning = kind == -1 && fighter == .lightning
        let isThunderbolt = kind == -1 && fighter == .thunderbolt
        let span: CGFloat = isLightning ? 48 : isStuka ? 45 : isThunderbolt ? 39 : 35
        let body = CGMutablePath()
        body.move(to: CGPoint(x: -4.5, y: -42))
        body.addLine(to: CGPoint(x: -6, y: -24))
        body.addLine(to: CGPoint(x: -span * 0.8, y: -9))
        if isStuka {
            body.addLine(to: CGPoint(x: -span, y: -16))
            body.addLine(to: CGPoint(x: -span, y: -6))
            body.addLine(to: CGPoint(x: -12, y: 10))
        } else {
            body.addLine(to: CGPoint(x: -span, y: 0))
            body.addLine(to: CGPoint(x: -span * 0.91, y: 6))
            body.addLine(to: CGPoint(x: -9, y: 12))
        }
        body.addLine(to: CGPoint(x: -5.8, y: 34))
        body.addLine(to: CGPoint(x: -2, y: 45))
        body.addLine(to: CGPoint(x: 2, y: 45))
        body.addLine(to: CGPoint(x: 5.8, y: 34))
        body.addLine(to: CGPoint(x: 9, y: 12))
        if isStuka {
            body.addLine(to: CGPoint(x: span, y: -6))
            body.addLine(to: CGPoint(x: span, y: -16))
            body.addLine(to: CGPoint(x: span * 0.8, y: -9))
        } else {
            body.addLine(to: CGPoint(x: span * 0.91, y: 6))
            body.addLine(to: CGPoint(x: span, y: 0))
            body.addLine(to: CGPoint(x: span * 0.8, y: -9))
        }
        body.addLine(to: CGPoint(x: 6, y: -24))
        body.addLine(to: CGPoint(x: 4.5, y: -42))
        body.closeSubpath()
        let fuselage = SKShapeNode(path: body)
        fuselage.fillColor = color
        fuselage.strokeColor = SKColor(white: 0.9, alpha: 0.85)
        fuselage.lineWidth = 1.1
        node.addChild(fuselage)
        let wingPanel = SKShapeNode(rectOf: CGSize(width: span * 1.5, height: 2))
        wingPanel.position.y = 0
        wingPanel.fillColor = .black.withAlphaComponent(0.26)
        wingPanel.strokeColor = .clear
        node.addChild(wingPanel)
        let tail = SKShapeNode(rectOf: CGSize(width: isLightning ? 49 : 28, height: 5), cornerRadius: 1)
        tail.position.y = -29
        tail.fillColor = color.withAlphaComponent(0.94)
        tail.strokeColor = .black.withAlphaComponent(0.48)
        node.addChild(tail)
        let canopy = SKShapeNode(ellipseOf: CGSize(width: 11, height: isStuka ? 28 : 19))
        canopy.position.y = isStuka ? 7 : 11
        canopy.fillColor = SKColor(red: 0.10, green: 0.25, blue: 0.34, alpha: 1)
        canopy.strokeColor = .white.withAlphaComponent(0.7)
        node.addChild(canopy)
        for side in [-1.0, 1.0] {
            let sign = CGFloat(side)
            let marking = SKShapeNode(circleOfRadius: kind == -1 ? 6.5 : 5.2)
            marking.position = CGPoint(x: sign * span * 0.66, y: -1)
            marking.fillColor = kind == -1 ? .white : .black.withAlphaComponent(0.83)
            marking.strokeColor = kind == -1 ? .blue : .white.withAlphaComponent(0.75)
            marking.lineWidth = 1.8
            node.addChild(marking)
            if isLightning {
                let boom = SKShapeNode(rectOf: CGSize(width: 6, height: 63), cornerRadius: 2)
                boom.position = CGPoint(x: sign * 22, y: -2)
                boom.fillColor = color
                boom.strokeColor = .black.withAlphaComponent(0.45)
                node.addChild(boom)
            }
            if kind == 0 {
                let cannon = SKShapeNode(rectOf: CGSize(width: 2.4, height: 14))
                cannon.position = CGPoint(x: sign * 20, y: 13)
                cannon.fillColor = .darkGray
                cannon.strokeColor = .clear
                node.addChild(cannon)
            }
        }
        // Animated propeller disc rather than a stationary vertical bar.
        let prop = SKShapeNode(ellipseOf: CGSize(width: isLightning ? 16 : 24, height: 5))
        prop.fillColor = .white.withAlphaComponent(0.28)
        prop.strokeColor = .white.withAlphaComponent(0.22)
        prop.position.y = 43
        prop.name = "prop"
        prop.run(.repeatForever(.sequence([.scaleX(to: 0.35, duration: 0.07),
                                            .scaleX(to: 1.1, duration: 0.07)])))
        node.addChild(prop)
        // Panel lines, gun ports, cowling and exhaust details scale with the wing.
        let spine = SKShapeNode(rectOf: CGSize(width: 2, height: 42), cornerRadius: 1)
        spine.position.y = -1
        spine.fillColor = .black.withAlphaComponent(0.20)
        spine.strokeColor = .clear
        node.addChild(spine)
        let engine = SKShapeNode(circleOfRadius: isThunderbolt ? 8 : 6)
        engine.position.y = 30
        engine.fillColor = color.withAlphaComponent(0.8)
        engine.strokeColor = .black.withAlphaComponent(0.65)
        engine.lineWidth = 1.2
        node.addChild(engine)
        for side in [-1.0, 1.0] {
            let direction = CGFloat(side)
            let aileron = SKShapeNode(rectOf: CGSize(width: span * 0.49, height: 2), cornerRadius: 0.5)
            aileron.position = CGPoint(x: direction * span * 0.68, y: -6)
            aileron.zRotation = direction * 0.06
            aileron.fillColor = .black.withAlphaComponent(0.37)
            aileron.strokeColor = .clear
            node.addChild(aileron)
            for j in 0..<3 {
                let panel = SKShapeNode(rectOf: CGSize(width: 2.1, height: 5), cornerRadius: 0.3)
                panel.position = CGPoint(x: direction * CGFloat(11 + j * 7), y: 9 - CGFloat(j) * 2)
                panel.fillColor = .black.withAlphaComponent(0.58)
                panel.strokeColor = .clear
                node.addChild(panel)
            }
            let exhaust = SKShapeNode(rectOf: CGSize(width: 2.5, height: 8), cornerRadius: 1)
            exhaust.position = CGPoint(x: direction * 8, y: 22)
            exhaust.fillColor = SKColor(white: 0.16, alpha: 0.92)
            exhaust.strokeColor = .clear
            node.addChild(exhaust)
        }
        return node
    }

    private func buildGround() {
        // Satellite-style terrain is rendered locally and needs no network connection.
        // A real geo-referenced texture can later replace this tile source with
        // properly credited public-domain NASA/USGS imagery.
        // Stream individually unique tiles from absolute world coordinates.
        // Each neighboring tile samples the same continuous landscape function.
        updateTerrainTiles(initial: true)

        // Organize cloud populations into fronts, broken banks and isolated puffs;
        // shadow layers give them height without obscuring dogfight visibility.
        let shapes = (0..<4).map { cloudTexture(seed: $0) }
        for bank in 0..<4 {
            let orientation: CGFloat = bank % 2 == 0 ? -0.25 : 0.31
            for cluster in 0..<7 {
                let spread = CGFloat(cluster - 3)
                let drift = CGFloat(bank) * 350
                let x = CGFloat.random(in: -210...210) + drift + spread * 155
                let y = CGFloat.random(in: -95...95) + CGFloat(bank) * 290 +
                        spread * (bank % 2 == 0 ? 48 : -65)
                let cloud = SKSpriteNode(texture: shapes[(bank + cluster) % shapes.count])
                let scale = CGFloat.random(in: 0.68...1.45)
                cloud.size = CGSize(width: 450 * scale, height: 200 * scale)
                cloud.alpha = CGFloat.random(in: 0.53...0.83)
                cloud.position = CGPoint(x: x, y: y)
                cloud.zRotation = orientation + CGFloat.random(in: -0.12...0.12)
                cloud.name = "cloud"
                cloud.zPosition = 37
                environment.addChild(cloud)
                cloudClusters.append(cloud)

                let shadow = SKSpriteNode(texture: shapes[(bank + cluster) % shapes.count])
                shadow.color = SKColor.black
                shadow.colorBlendFactor = 1
                shadow.alpha = 0.15
                shadow.size = CGSize(width: 440 * scale, height: 180 * scale)
                shadow.position = CGPoint(x: x + 58, y: y - 72)
                shadow.zRotation = cloud.zRotation
                shadow.zPosition = -4
                shadow.name = "shadow"
                environment.addChild(shadow)
            }
        }
    }

    private func terrainKey(_ x: Int, _ y: Int) -> String { "\(x):\(y)" }

    private func updateTerrainTiles(initial: Bool = false) {
        let tile = terrainTileSize
        // Terrain world position plus camera offset = screen position.
        let cameraX = Double(-terrainOffset.x + size.width * 0.5)
        let cameraY = Double(-terrainOffset.y + size.height * 0.5)
        let centerX = Int(floor(cameraX / Double(tile)))
        let centerY = Int(floor(cameraY / Double(tile)))
        var expected = Set<String>()
        for row in (centerY - 1)...(centerY + 1) {
            for col in (centerX - 1)...(centerX + 1) {
                expected.insert(terrainKey(col, row))
            }
        }
        // Remove old tiles first, so memory remains bounded on long flights.
        for (key, sprite) in terrainTiles where !expected.contains(key) {
            sprite.removeFromParent()
            terrainTiles.removeValue(forKey: key)
        }
        var generated = 0
        for row in (centerY - 1)...(centerY + 1) {
            for col in (centerX - 1)...(centerX + 1) {
                let key = terrainKey(col, row)
                if let sprite = terrainTiles[key] {
                    sprite.position = CGPoint(x: CGFloat(col) * tile + tile / 2 + terrainOffset.x,
                                              y: CGFloat(row) * tile + tile / 2 + terrainOffset.y)
                    continue
                }
                // Generate up to two new textures in a frame after startup.
                if !initial && generated >= 2 { continue }
                let sprite = SKSpriteNode(texture: terrainTexture(tileX: col, tileY: row),
                                          size: CGSize(width: tile, height: tile))
                sprite.name = "terrain"
                sprite.zPosition = -20
                sprite.position = CGPoint(x: CGFloat(col) * tile + tile / 2 + terrainOffset.x,
                                          y: CGFloat(row) * tile + tile / 2 + terrainOffset.y)
                environment.addChild(sprite)
                terrainTiles[key] = sprite
                generated += 1
            }
        }
    }

    private func terrainHash(_ x: Int, _ y: Int, _ seed: Int) -> Double {
        // Integer coordinate hash: stable across tiles and revisits.
        var v = UInt64(bitPattern: Int64(x)) &* 0x9E3779B185EBCA87
        v ^= UInt64(bitPattern: Int64(y)) &* 0xC2B2AE3D27D4EB4F
        v ^= UInt64(seed) &* 0x165667B19E3779F9
        v ^= v >> 30
        v = v &* 0xBF58476D1CE4E5B9
        v ^= v >> 27
        v = v &* 0x94D049BB133111EB
        v ^= v >> 31
        return Double(v & 0xFFFFFF) / Double(0xFFFFFF)
    }
    private func terrainNoise(_ x: Double, _ y: Double, _ scale: Double, _ seed: Int) -> Double {
        let sx = x / scale, sy = y / scale
        let xi = Int(floor(sx)), yi = Int(floor(sy))
        let fx = sx - floor(sx), fy = sy - floor(sy)
        let u = fx * fx * (3 - 2 * fx), v = fy * fy * (3 - 2 * fy)
        let a = terrainHash(xi, yi, seed)
        let b = terrainHash(xi + 1, yi, seed)
        let c = terrainHash(xi, yi + 1, seed)
        let d = terrainHash(xi + 1, yi + 1, seed)
        return (a + (b-a) * u) * (1-v) + (c + (d-c) * u) * v
    }
    private func terrainTexture(tileX: Int, tileY: Int) -> SKTexture {
        // Entirely procedural, high-detail offline aerial landscape.
        // World-space sampling removes tile-edge noise discontinuities.
        let n = 512
        guard let bmp = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: n,
                                          pixelsHigh: n, bitsPerSample: 8,
                                          samplesPerPixel: 4, hasAlpha: true,
                                          isPlanar: false, colorSpaceName: .deviceRGB,
                                          bytesPerRow: n * 4, bitsPerPixel: 32),
              let data = bmp.bitmapData else {
            return SKTexture(image: NSImage(size: CGSize(width: 2, height: 2)))
        }
        let stride = bmp.bytesPerRow
        let originX = Double(tileX) * 1024
        let originY = Double(tileY) * 1024
        for py in 0..<n {
            for px in 0..<n {
                let x = originX + Double(px) * 2
                let y = originY + Double(py) * 2
                let regional = terrainNoise(x, y, 2400, 3)
                let ridge = terrainNoise(x, y, 680, 7)
                let foliage = terrainNoise(x, y, 190, 11)
                let thicket = terrainNoise(x, y, 49, 13)
                let grit = terrainNoise(x, y, 9, 17)
                let flecks = terrainHash(Int(x), Int(y), 23)
                let vegetation = 0.32 * regional + 0.27 * ridge +
                                 0.26 * foliage + 0.13 * thicket + 0.02 * grit
                let villageRegionX = Int(floor(x / 1800))
                let villageRegionY = Int(floor(y / 1800))
                let farmland = terrainHash(villageRegionX, villageRegionY, 33) > 0.35
                let parcelX = Int(floor((x + sin(y / 420) * 140) / 210))
                let parcelY = Int(floor((y + cos(x / 390) * 110) / 155))
                let parcel = terrainHash(parcelX, parcelY, 31)
                let band = 0.82 + 0.2 * terrainNoise(x, y, 31, 41)
                let woodland = vegetation > (farmland ? 0.52 : 0.43)
                // Rivers continue globally across tiles; narrow winding side streams vary.
                let river = 750 + sin(y / 525) * 350 + sin(y / 163) * 85 +
                            sin(y / 59) * 19
                let waterDist = abs(x - river)
                let tributary = 1850 + cos(y / 700 + 1.7) * 290 +
                                sin(y / 127) * 58
                let tributaryDist = abs(x - tributary)
                // Gravel routes snake through fields; road junctions create hamlets.
                let roadV = Double(Int(floor((x + sin(y / 600) * 65) / 1050))) * 1050 +
                            520 - sin(y / 600) * 65
                let roadH = Double(Int(floor((y + sin(x / 490) * 52) / 1250))) * 1250 +
                            630 - sin(x / 490) * 52
                let roadDistance = min(abs(x - roadV), abs(y - roadH))
                let roadJunction = abs(x - roadV) < 95 && abs(y - roadH) < 115
                let houseX = Int(floor(x / 23))
                let houseY = Int(floor(y / 22))
                let roof = roadJunction && terrainHash(houseX, houseY, 99) > 0.73 &&
                           abs((x.truncatingRemainder(dividingBy: 23)) - 11.5) < 8 &&
                           abs((y.truncatingRemainder(dividingBy: 22)) - 11) < 6
                var red: Double
                var green: Double
                var blue: Double
                if waterDist < 15 || tributaryDist < 7 {
                    red = 39 + ridge * 21
                    green = 74 + ridge * 32
                    blue = 83 + foliage * 29
                } else if waterDist < 30 || tributaryDist < 17 {
                    red = 112 + ridge * 32
                    green = 114 + ridge * 29
                    blue = 90 + ridge * 18
                } else if roof {
                    red = 142 + flecks * 32
                    green = 91 + flecks * 26
                    blue = 63 + flecks * 18
                } else if roadDistance < 5 {
                    red = 143 + grit * 21
                    green = 136 + grit * 20
                    blue = 109 + grit * 17
                } else if woodland {
                    red = 32 + thicket * 30
                    green = 55 + thicket * 48
                    blue = 29 + thicket * 22
                } else if farmland {
                    red = (88 + parcel * 79) * band
                    green = (97 + parcel * 65) * band
                    blue = (48 + parcel * 48) * band
                } else {
                    red = 79 + foliage * 58
                    green = 99 + foliage * 62
                    blue = 52 + foliage * 43
                }
                // Microtexture and low-angle relief make the ground read like
                // photographed terrain rather than flat colored rectangles.
                let relief = (grit - 0.5) * 21 + (flecks - 0.5) * 13
                let pixel = py * stride + px * 4
                data[pixel] = UInt8(max(0, min(255, Int(red + relief))))
                data[pixel+1] = UInt8(max(0, min(255, Int(green + relief))))
                data[pixel+2] = UInt8(max(0, min(255, Int(blue + relief))))
                data[pixel+3] = 255
            }
        }
        let image = NSImage(size: NSSize(width: n, height: n))
        image.addRepresentation(bmp)
        let tex = SKTexture(image: image)
        tex.filteringMode = .linear
        return tex
    }

    private func cloudTexture(seed: Int) -> SKTexture {
        // Feathered radial-gradient cloudlets form coherent, uneven cumuliform
        // banks instead of circles arranged in perfectly repeated rows.
        let width = 512, height = 256
        let image = NSImage(size: NSSize(width: width, height: height), flipped: false) { _ in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            ctx.clear(CGRect(x: 0, y: 0, width: width, height: height))
            let space = CGColorSpaceCreateDeviceRGB()
            for i in 0..<50 {
                let centerX = CGFloat(i % 10) * 42 + 56 +
                              sin(CGFloat(i * 13 + seed * 9)) * 24
                let centerY = 125 + CGFloat(i / 10 - 2) * 21 +
                              cos(CGFloat(i * 7 + seed * 11)) * 29
                let radius = CGFloat(29 + (i * 19 + seed * 13) % 37)
                let tone: CGFloat = CGFloat((i * 17 + seed * 5) % 10) / 100
                let inner = CGColor(colorSpace: space, components: [1, 1, 1, 0.45 + tone])!
                let outer = CGColor(colorSpace: space, components: [0.82, 0.88, 0.92, 0])!
                guard let grad = CGGradient(colorsSpace: space, colors: [inner, outer] as CFArray,
                                            locations: [0, 1]) else { continue }
                ctx.drawRadialGradient(grad,
                                       startCenter: CGPoint(x: centerX - 9, y: centerY + 8), startRadius: 2,
                                       endCenter: CGPoint(x: centerX, y: centerY), endRadius: radius,
                                       options: [])
            }
            return true
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        return texture
    }

    override func update(_ currentTime: TimeInterval) {
        if lastTime == 0 { lastTime = currentTime; return }
        let dt = CGFloat(min(currentTime - lastTime, 0.04))
        lastTime = currentTime
        if pausedGame || gameOver { return }
        gameTime += dt
        wave = 1 + Int(gameTime / 36)
        let left = keys.contains(123) || keys.contains(0)
        let right = keys.contains(124) || keys.contains(2)
        let thrust = keys.contains(126) || keys.contains(13)
        let brake = keys.contains(125) || keys.contains(1)
        let turnRate: CGFloat = fighter == .thunderbolt ? 2.25 : 2.8
        if left { heading += turnRate * dt }
        if right { heading -= turnRate * dt }
        if thrust { airspeed += 205 * dt }
        if brake { airspeed -= 235 * dt }
        airspeed = max(105, min(fighter.speed + 95, airspeed))
        player.zRotation = heading - .pi / 2
        let velocity = CGVector(dx: cos(heading) * airspeed, dy: sin(heading) * airspeed)
        // Free flight with a generous camera dead-zone. The aircraft crosses the
        // screen naturally, and only then does the camera pan to follow it.
        let next = CGPoint(x: player.position.x + velocity.dx * dt,
                           y: player.position.y + velocity.dy * dt)
        let marginX = size.width * 0.22
        let marginY = size.height * 0.24
        let cameraX = max(0, next.x - (size.width - marginX)) + min(0, next.x - marginX)
        let cameraY = max(0, next.y - (size.height - marginY)) + min(0, next.y - marginY)
        let scroll = CGVector(dx: -cameraX, dy: -cameraY)
        player.position = CGPoint(x: next.x + scroll.dx, y: next.y + scroll.dy)
        // Camera-relative world streaming; terrain tiles are keyed by coordinates.
        terrainOffset.x += scroll.dx
        terrainOffset.y += scroll.dy
        updateTerrainTiles()
        for node in environment.children where node.name != "terrain" {
            let parallax: CGFloat = node.name == "cloud" ? 0.77 : 1
            node.position.x += scroll.dx * parallax
            node.position.y += scroll.dy * parallax
            if node.name == "cloud" || node.name == "shadow" {
                let wind: CGFloat = 8 * dt
                node.position.x += wind
                if node.position.x < -460 { node.position.x += size.width + 980 }
                if node.position.x > size.width + 480 { node.position.x -= size.width + 980 }
                if node.position.y < -330 { node.position.y += size.height + 640 }
                if node.position.y > size.height + 330 { node.position.y -= size.height + 640 }
            }
        }
        if keys.contains(49) && gameTime - lastFire > 0.115 {
            firePlayerWeapons()
            lastFire = gameTime
        }
        if gameTime - lastFormation > max(8, 13.5 - CGFloat(wave) * 0.35) && bandits.count < 15 {
            spawnFormation()
            lastFormation = gameTime
        }
        updateBandits(dt: dt, scrolling: scroll)
        updateRounds(dt: dt, scrolling: scroll)
        // Give a reliable threat direction for attacks approaching outside the view.
        updateLabels()
    }

    private func spawnFormation() {
        let count = min(3 + wave / 2, 6)
        let edge = Int.random(in: 0..<4)
        let center: CGPoint
        switch edge {
        case 0: center = CGPoint(x: -120, y: CGFloat.random(in: 110...(size.height - 100)))
        case 1: center = CGPoint(x: size.width + 120, y: CGFloat.random(in: 110...(size.height - 100)))
        case 2: center = CGPoint(x: CGFloat.random(in: 100...(size.width - 100)), y: -120)
        default: center = CGPoint(x: CGFloat.random(in: 100...(size.width - 100)), y: size.height + 120)
        }
        let toward = atan2(player.position.y - center.y, player.position.x - center.x)
        let kind = Int.random(in: 0...(wave >= 3 ? 2 : 1))
        let style = Int.random(in: 0...2) // V, echelon, or paired flights
        for i in 0..<count {
            let index = CGFloat(i)
            let row = CGFloat((i + 1) / 2)
            let sign: CGFloat = i % 2 == 0 ? -1 : 1
            let leadLag = style == 0 ? row * 66 : style == 1 ? index * 47 : CGFloat(i / 2) * 88
            let sideOffset = style == 0 ? sign * row * 65 : style == 1 ? index * 22 : sign * 44
            let location = CGPoint(
                x: center.x - cos(toward) * leadLag + cos(toward + .pi / 2) * sideOffset,
                y: center.y - sin(toward) * leadLag + sin(toward + .pi / 2) * sideOffset
            )
            let sprite = SKNode()
            sprite.position = location
            sprite.zRotation = toward - .pi / 2
            sprite.zPosition = 15
            let color = kind == 2 ? SKColor(red: 0.43, green: 0.45, blue: 0.33, alpha: 1) : SKColor(red: 0.45, green: 0.47, blue: 0.43, alpha: 1)
            sprite.addChild(drawAircraft(kind: kind, color: color))
            sprite.setScale(kind == 2 ? 1.17 : kind == 1 ? 0.87 : 0.96)
            addChild(sprite)
            bandits.append(Bandit(sprite: sprite, position: location, heading: toward, speed: kind == 2 ? 150 : CGFloat.random(in: 180...240),
                                  health: kind == 2 ? 5 : (wave >= 3 ? 3 : 2), kind: kind, formationTime: CGFloat.random(in: 1.7...3.7) + row * 0.25,
                                  fireCooldown: index * 0.18 + 1.3, targetOffset: CGFloat.random(in: -1.15...1.15),
                                  tactic: .formation, tacticTime: 0, maneuverSign: sign,
                                  entryHeading: toward, previousDistance: 1000))
        }
        flash("INCOMING FORMATION — \(count) HOSTILES")
    }
    private func updateBandits(dt: CGFloat, scrolling: CGVector) {
        // Four-state combat behavior: line up, attack, break away, and re-engage.
        // Changing tactics prevents the old permanent "fly toward the player" behavior.
        for i in bandits.indices {
            var b = bandits[i]
            b.formationTime -= dt
            b.tacticTime -= dt
            b.fireCooldown -= dt
            let dx = player.position.x - b.position.x
            let dy = player.position.y - b.position.y
            let distance = hypot(dx, dy)
            let bearing = atan2(dy, dx)
            let playerForward = CGVector(dx: cos(heading), dy: sin(heading))
            let inRear = (b.position.x - player.position.x) * playerForward.dx +
                         (b.position.y - player.position.y) * playerForward.dy < -45

            if b.tactic == .formation && b.formationTime <= 0 {
                b.tactic = .intercept
                b.tacticTime = CGFloat.random(in: 0.7...1.6)
            }
            if b.tactic == .intercept && (distance < 330 || b.tacticTime <= 0) {
                b.tactic = .attack
                b.tacticTime = CGFloat.random(in: 2...3.4)
            }
            if b.tactic == .attack && (distance < 100 || b.tacticTime <= 0) {
                b.tactic = .breakAway
                b.tacticTime = CGFloat.random(in: 1.3...2.7)
                b.maneuverSign = Bool.random() ? 1 : -1
            }
            if b.tactic == .breakAway && b.tacticTime <= 0 {
                b.tactic = .regroup
                b.tacticTime = CGFloat.random(in: 0.8...2)
            }
            if b.tactic == .regroup && (b.tacticTime <= 0 || distance > 470) {
                b.tactic = .intercept
                b.tacticTime = CGFloat.random(in: 0.6...1.3)
            }
            let desired: CGFloat
            switch b.tactic {
            case .formation: desired = b.entryHeading
            case .intercept:
                // Lead the moving player instead of steering toward its present position.
                let lead = min(1.05, distance / 450)
                desired = atan2(dy + playerForward.dy * airspeed * lead,
                                dx + playerForward.dx * airspeed * lead)
            case .attack:
                desired = bearing + b.targetOffset * (inRear ? 0.12 : 0.32)
            case .breakAway:
                // Keep moving, cross the opponent's flight path, then arc outward.
                desired = b.heading + b.maneuverSign * 0.85
            case .regroup:
                desired = bearing + b.maneuverSign * 1.3
            }
            let turnDelta = atan2(sin(desired - b.heading), cos(desired - b.heading))
            let turnRate: CGFloat = b.kind == 2 ? 0.95 : (b.kind == 1 ? 2.25 : 1.85)
            let boundedTurn = max(-turnRate * dt, min(turnRate * dt, turnDelta))
            b.heading += boundedTurn
            let speedGoal: CGFloat = b.tactic == .breakAway ? (b.kind == 2 ? 205 : 315)
                                    : b.tactic == .formation ? (b.kind == 2 ? 160 : 230)
                                    : (b.kind == 2 ? 170 : 255)
            b.speed += max(-95 * dt, min(95 * dt, speedGoal - b.speed))
            b.position.x += cos(b.heading) * b.speed * dt + scrolling.dx
            b.position.y += sin(b.heading) * b.speed * dt + scrolling.dy
            b.sprite.position = b.position
            b.sprite.zRotation = b.heading - .pi / 2
            let aimError = abs(atan2(sin(bearing - b.heading), cos(bearing - b.heading)))
            if b.tactic == .attack && b.fireCooldown <= 0 && distance < 440 && aimError < 0.19 {
                fire(from: b.position, angle: b.heading, hostile: true)
                b.fireCooldown = CGFloat.random(in: 0.9...1.75)
            }
            b.previousDistance = distance
            bandits[i] = b
        }
        // Ensure aircraft departing the screen have time to circle back, but
        // eventually despawn a runaway pursuit to cap difficulty and workload.
        for i in bandits.indices.reversed() {
            let b = bandits[i]
            if b.position.x < -900 || b.position.x > size.width + 900 ||
               b.position.y < -900 || b.position.y > size.height + 900 {
                b.sprite.removeFromParent()
                bandits.remove(at: i)
            } else if hypot(b.position.x - player.position.x,
                            b.position.y - player.position.y) < 31 && gameTime > invulnerableUntil {
                takeDamage()
            }
        }
        // Screen-edge threat alert for an opponent closing in from behind.
        var rearThreat = false
        for b in bandits {
            let offsetX = b.position.x - player.position.x
            let offsetY = b.position.y - player.position.y
            let aft = offsetX * cos(heading) + offsetY * sin(heading)
            let bearingToEnemy = atan2(offsetY, offsetX)
            let relative = abs(atan2(sin(bearingToEnemy - heading), cos(bearingToEnemy - heading)))
            if aft < -80 && relative > 2.4 && hypot(offsetX, offsetY) < 530 {
                rearThreat = true
                break
            }
        }
        threat.text = rearThreat ? "⚠ SIX O'CLOCK — BANDIT BEHIND" : ""
    }

    private func firePlayerWeapons() {
        // Wing-mounted .50-caliber guns on P-51, P-47 and P-40;
        // P-38 concentrates its cannon and machine guns in the nose.
        gunCycle += 1
        let barrelX: CGFloat
        switch fighter {
        case .mustang: barrelX = [18, 25, 31][gunCycle % 3]
        case .thunderbolt: barrelX = [19, 24, 29, 34][gunCycle % 4]
        case .warhawk: barrelX = [17, 24, 30][gunCycle % 3]
        case .lightning: barrelX = 4
        }
        if fighter == .lightning {
            fire(from: player.position, angle: heading, hostile: false, lateral: 0, forward: 3)
            fire(from: player.position, angle: heading, hostile: false, lateral: gunCycle % 2 == 0 ? -4 : 4, forward: -1)
        } else {
            fire(from: player.position, angle: heading, hostile: false, lateral: -barrelX, forward: -26)
            fire(from: player.position, angle: heading, hostile: false, lateral: barrelX, forward: -26)
        }
    }

    private func fire(from origin: CGPoint, angle: CGFloat, hostile: Bool,
                      lateral: CGFloat = 0, forward: CGFloat = 0) {
        let round = SKShapeNode(rectOf: CGSize(width: 4, height: hostile ? 13 : 20), cornerRadius: 2)
        round.fillColor = hostile ? .orange : .yellow
        round.strokeColor = .clear
        round.glowWidth = 3
        round.zRotation = angle - .pi / 2
        round.position = CGPoint(x: origin.x + cos(angle) * (42 + forward) - sin(angle) * lateral,
                                 y: origin.y + sin(angle) * (42 + forward) + cos(angle) * lateral)
        round.zPosition = 22
        addChild(round)
        let speed: CGFloat = hostile ? 420 : 790
        rounds.append(Round(sprite: round, position: round.position,
                            velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                            lifetime: hostile ? 1.8 : 1.3, hostile: hostile))
    }
    private func updateRounds(dt: CGFloat, scrolling: CGVector) {
        for i in rounds.indices.reversed() {
            var bullet = rounds[i]
            bullet.lifetime -= dt
            bullet.position.x += bullet.velocity.dx * dt + scrolling.dx
            bullet.position.y += bullet.velocity.dy * dt + scrolling.dy
            bullet.sprite.position = bullet.position
            var consumed = false
            if bullet.hostile {
                if gameTime > invulnerableUntil && hypot(bullet.position.x - player.position.x, bullet.position.y - player.position.y) < 25 {
                    takeDamage()
                    consumed = true
                }
            } else {
                for j in bandits.indices.reversed() {
                    if hypot(bullet.position.x - bandits[j].position.x, bullet.position.y - bandits[j].position.y) < 35 {
                        bandits[j].health -= 1
                        burst(at: bullet.position, count: 5)
                        consumed = true
                        if bandits[j].health <= 0 {
                            burst(at: bandits[j].position, count: 30)
                            bandits[j].sprite.removeFromParent()
                            bandits.remove(at: j)
                            kills += 1
                            if gameTime < comboDeadline { hitCombo += 1 } else { hitCombo = 1 }
                            comboDeadline = gameTime + 3.6
                            let award = 100 * wave * min(hitCombo, 4)
                            score += award
                            if hitCombo > 1 { flash("COMBO ×\(hitCombo)   +\(award)") } else { flash("SPLASH ONE   +\(award)") }
                        }
                        break
                    }
                }
            }
            if consumed || bullet.lifetime <= 0 {
                bullet.sprite.removeFromParent()
                rounds.remove(at: i)
            } else {
                rounds[i] = bullet
            }
        }
    }
    private func takeDamage() {
        health -= 1
        invulnerableUntil = gameTime + 0.75
        burst(at: player.position, count: 24)
        player.run(.sequence([.fadeAlpha(to: 0.25, duration: 0.1), .fadeAlpha(to: 1, duration: 0.25)]))
        if health <= 0 {
            gameOver = true
            status.text = "SHOT DOWN — RETURN TO RESTART"
        } else {
            flash("HIT! AIRFRAME DAMAGED")
        }
    }
    private func burst(at point: CGPoint, count: Int) {
        for _ in 0..<count {
            let dot = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            dot.position = point
            dot.fillColor = Bool.random() ? .orange : .yellow
            dot.strokeColor = .clear
            dot.zPosition = 40
            addChild(dot)
            dot.run(.sequence([.group([
                .moveBy(x: CGFloat.random(in: -75...75), y: CGFloat.random(in: -75...75), duration: 0.4),
                .fadeOut(withDuration: 0.4)
            ]), .removeFromParent()]))
        }
    }
    private func flash(_ text: String) {
        if gameOver || pausedGame { return }
        status.text = text
        status.removeAllActions()
        status.run(.sequence([.wait(forDuration: 1.7), .run { [weak self] in
            if self?.gameOver == false && self?.pausedGame == false { self?.status.text = "" }
        }]))
    }
    private func installTelemetry() {
        hud.fontSize = 12
        hud.fontColor = .white.withAlphaComponent(0.82)
        telemetryPanel.fillColor = .black.withAlphaComponent(0.31)
        telemetryPanel.strokeColor = .cyan.withAlphaComponent(0.32)
        telemetryPanel.lineWidth = 1
        telemetryPanel.zPosition = 90
        addChild(telemetryPanel)
        for (i, label) in telemetryLines.enumerated() {
            label.fontSize = i == 0 ? 13 : 11
            label.fontColor = i == 0 ? .cyan : .white.withAlphaComponent(0.95)
            label.horizontalAlignmentMode = .left
            label.verticalAlignmentMode = .center
            label.zPosition = 92
            addChild(label)
        }
        radarPanel.fillColor = .black.withAlphaComponent(0.33)
        radarPanel.strokeColor = .cyan.withAlphaComponent(0.4)
        radarPanel.lineWidth = 1
        radarPanel.zPosition = 91
        addChild(radarPanel)
        radarContacts.zPosition = 93
        addChild(radarContacts)
        layoutTelemetry()
    }
    private func layoutTelemetry() {
        let right = size.width - 18
        let panelWidth: CGFloat = 238
        let panelHeight: CGFloat = 191
        let top = size.height - 65
        let panel = CGRect(x: right - panelWidth, y: top - panelHeight,
                           width: panelWidth, height: panelHeight)
        telemetryPanel.path = CGPath(roundedRect: panel, cornerWidth: 10, cornerHeight: 10, transform: nil)
        for (i, label) in telemetryLines.enumerated() {
            label.position = CGPoint(x: panel.minX + 13, y: panel.maxY - 18 - CGFloat(i) * 25)
        }
        let radarFrame = CGRect(x: right - panelWidth, y: 19, width: panelWidth, height: 222)
        radarPanel.path = CGPath(roundedRect: radarFrame, cornerWidth: 10, cornerHeight: 10, transform: nil)
        radarContacts.position = CGPoint(x: radarFrame.midX, y: radarFrame.midY - 5)
    }
    private func updateRadar() {
        radarContacts.removeAllChildren()
        let radius: CGFloat = 89
        for fraction in [CGFloat(0.33), 0.66, 1] {
            let ring = SKShapeNode(circleOfRadius: radius * fraction)
            ring.strokeColor = .cyan.withAlphaComponent(0.17)
            ring.fillColor = .clear
            ring.lineWidth = 1
            radarContacts.addChild(ring)
        }
        let north = SKShapeNode(rectOf: CGSize(width: 1, height: radius * 2))
        north.fillColor = .cyan.withAlphaComponent(0.17)
        north.strokeColor = .clear
        radarContacts.addChild(north)
        let east = SKShapeNode(rectOf: CGSize(width: radius * 2, height: 1))
        east.fillColor = .cyan.withAlphaComponent(0.17)
        east.strokeColor = .clear
        radarContacts.addChild(east)
        let center = SKShapeNode(circleOfRadius: 4)
        center.fillColor = .cyan
        center.strokeColor = .clear
        radarContacts.addChild(center)
        for bandit in bandits {
            let dx = bandit.position.x - player.position.x
            let dy = bandit.position.y - player.position.y
            // Player-forward is always up on the radar.
            let lateral = -sin(heading) * dx + cos(heading) * dy
            let ahead = cos(heading) * dx + sin(heading) * dy
            let px = lateral * 0.16
            let py = ahead * 0.16
            let distance = hypot(px, py)
            if distance > radius { continue }
            let blip = SKShapeNode(circleOfRadius: bandit.kind == 2 ? 4.2 : 3.3)
            blip.position = CGPoint(x: px, y: py)
            blip.fillColor = .orange
            blip.strokeColor = .red
            blip.glowWidth = 1.5
            radarContacts.addChild(blip)
        }
    }

    private func updateLabels() {
        hud.position = CGPoint(x: 23, y: size.height - 24)
        status.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        threat.position = CGPoint(x: size.width - 24, y: size.height - 51)
        hud.text = "VECTOR ACES  /  WWII AIR COMBAT"
        let rows = [
            "FLIGHT TELEMETRY",
            fighter.rawValue.uppercased(),
            String(format: "AIRSPEED  %03d MPH", Int(airspeed)),
            String(format: "HEADING   %03d DEG", Int((90 - heading * 180 / .pi).truncatingRemainder(dividingBy: 360) + 360) % 360),
            "AIRFRAME  \(max(0, health))/\(fighter.health)",
            "WAVE \(wave)   KILLS \(kills)",
            "SCORE  \(score)"
        ]
        for (index, label) in telemetryLines.enumerated() { label.text = rows[index] }
        updateRadar()
    }
    private func restart() {
        for b in bandits { b.sprite.removeFromParent() }
        for r in rounds { r.sprite.removeFromParent() }
        bandits.removeAll()
        rounds.removeAll()
        gameTime = 0
        lastFormation = -8
        lastWarning = -10
        hitCombo = 0
        comboDeadline = 0
        threat.text = ""
        lastFire = -1
        health = fighter.health
        gunCycle = 0
        score = 0
        kills = 0
        wave = 1
        airspeed = 210
        heading = .pi / 2
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        keys.removeAll()
        gameOver = false
        pausedGame = false
        invulnerableUntil = 0
        status.text = ""
        updateLabels()
    }
}
