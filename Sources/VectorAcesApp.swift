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
        updateLabels()
        view.window?.makeFirstResponder(self)
    }
    override func didChangeSize(_ oldSize: CGSize) {
        hud.position = CGPoint(x: 24, y: size.height - 22)
        status.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        threat.position = CGPoint(x: size.width - 25, y: size.height - 50)
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
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
        return node
    }

    private func buildGround() {
        // World-anchored ground elements scroll beneath a centered aircraft.
        for i in 0..<62 {
            let block = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 48...155), height: CGFloat.random(in: 40...115)))
            block.fillColor = i % 4 == 0 ? SKColor(red: 0.18, green: 0.28, blue: 0.22, alpha: 1) : SKColor(red: 0.23, green: 0.38, blue: 0.27, alpha: 1)
            block.strokeColor = .clear
            block.position = CGPoint(x: CGFloat.random(in: -180...1380), y: CGFloat.random(in: -150...900))
            block.zPosition = -12
            environment.addChild(block)
        }
        for i in 0..<16 {
            let field = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 75...155), height: CGFloat.random(in: 65...145)), cornerRadius: 2)
            field.fillColor = i % 2 == 0 ? SKColor(red: 0.36, green: 0.40, blue: 0.23, alpha: 0.7) : SKColor(red: 0.4, green: 0.42, blue: 0.29, alpha: 0.8)
            field.strokeColor = .white.withAlphaComponent(0.06)
            field.zRotation = CGFloat.random(in: -0.2...0.2)
            field.position = CGPoint(x: CGFloat.random(in: -140...1280), y: CGFloat.random(in: -80...850))
            field.zPosition = -10
            environment.addChild(field)
        }
        for i in 0..<14 {
            let cloud = SKNode()
            for j in 0..<4 {
                let puff = SKShapeNode(ellipseOf: CGSize(width: 105, height: 47))
                puff.fillColor = .white.withAlphaComponent(0.12)
                puff.strokeColor = .clear
                puff.position.x = CGFloat(j) * 25
                cloud.addChild(puff)
            }
            cloud.position = CGPoint(x: CGFloat.random(in: -150...1300), y: CGFloat.random(in: -100...850))
            cloud.zPosition = 28
            cloud.name = "cloud"
            environment.addChild(cloud)
        }
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
        let scroll = CGVector(dx: -velocity.dx * dt, dy: -velocity.dy * dt)
        // Keep player centered and advance the world relative to its flight vector.
        for node in environment.children {
            node.position.x += scroll.dx * (node.name == "cloud" ? 0.58 : 1)
            node.position.y += scroll.dy * (node.name == "cloud" ? 0.58 : 1)
            if node.position.x < -230 { node.position.x += size.width + 430 }
            if node.position.x > size.width + 230 { node.position.x -= size.width + 430 }
            if node.position.y < -190 { node.position.y += size.height + 380 }
            if node.position.y > size.height + 190 { node.position.y -= size.height + 380 }
        }
        if keys.contains(49) && gameTime - lastFire > 0.11 {
            fire(from: player.position, angle: heading, hostile: false)
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

    private func fire(from origin: CGPoint, angle: CGFloat, hostile: Bool) {
        let round = SKShapeNode(rectOf: CGSize(width: 4, height: hostile ? 13 : 20), cornerRadius: 2)
        round.fillColor = hostile ? .orange : .yellow
        round.strokeColor = .clear
        round.glowWidth = 3
        round.zRotation = angle - .pi / 2
        round.position = CGPoint(x: origin.x + cos(angle) * 42, y: origin.y + sin(angle) * 42)
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
    private func updateLabels() {
        hud.position = CGPoint(x: 23, y: size.height - 24)
        status.position = CGPoint(x: size.width / 2, y: size.height * 0.64)
        threat.position = CGPoint(x: size.width - 24, y: size.height - 51)
        hud.text = "VECTOR ACES  |  \(fighter.rawValue.uppercased())  |  WAVE \(wave)  |  KILLS \(kills)  |  SCORE \(score)  |  AIRFRAME \(max(0, health))/\(fighter.health)  |  SPEED \(Int(airspeed))"
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
        score = 0
        kills = 0
        wave = 1
        airspeed = 210
        heading = .pi / 2
        keys.removeAll()
        gameOver = false
        pausedGame = false
        invulnerableUntil = 0
        status.text = ""
        updateLabels()
    }
}
