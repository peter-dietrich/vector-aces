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
    private var rng = SystemRandomNumberGenerator()

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
        updateLabels()
        view.window?.makeFirstResponder(self)
    }
    override func didChangeSize(_ oldSize: CGSize) {
        hud.position = CGPoint(x: 24, y: size.height - 22)
        status.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
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
        // The fuselage points up; heading controls world orientation.
        let node = SKNode()
        let wings: CGFloat = kind == 2 ? 37 : (kind == -1 && fighter == .lightning ? 41 : 32)
        let fuselage = SKShapeNode()
        let outline = CGMutablePath()
        outline.move(to: CGPoint(x: -5, y: -35))
        outline.addLine(to: CGPoint(x: -8, y: -18))
        outline.addLine(to: CGPoint(x: -wings, y: -6))
        outline.addLine(to: CGPoint(x: -wings, y: 1))
        outline.addLine(to: CGPoint(x: -7, y: 9))
        outline.addLine(to: CGPoint(x: -6, y: 31))
        outline.addLine(to: CGPoint(x: 0, y: 40))
        outline.addLine(to: CGPoint(x: 6, y: 31))
        outline.addLine(to: CGPoint(x: 7, y: 9))
        outline.addLine(to: CGPoint(x: wings, y: 1))
        outline.addLine(to: CGPoint(x: wings, y: -6))
        outline.addLine(to: CGPoint(x: 8, y: -18))
        outline.addLine(to: CGPoint(x: 5, y: -35))
        outline.closeSubpath()
        fuselage.path = outline
        fuselage.fillColor = color
        fuselage.strokeColor = color.withAlphaComponent(0.9)
        fuselage.lineWidth = 1.7
        node.addChild(fuselage)
        let tail = SKShapeNode(rectOf: CGSize(width: 29, height: 5), cornerRadius: 1)
        tail.position.y = -27
        tail.fillColor = color.withAlphaComponent(0.88)
        tail.strokeColor = .black.withAlphaComponent(0.4)
        node.addChild(tail)
        let canopy = SKShapeNode(ellipseOf: CGSize(width: 10, height: 17))
        canopy.position.y = 8
        canopy.fillColor = SKColor(red: 0.13, green: 0.29, blue: 0.42, alpha: 1)
        canopy.strokeColor = .white.withAlphaComponent(0.75)
        node.addChild(canopy)
        for side in [-1.0, 1.0] {
            let marking = SKShapeNode(circleOfRadius: 5.5)
            marking.position = CGPoint(x: CGFloat(side) * (wings * 0.59), y: -2)
            marking.fillColor = kind == -1 ? .white : .black.withAlphaComponent(0.65)
            marking.strokeColor = kind == -1 ? .blue : .gray
            marking.lineWidth = 2
            node.addChild(marking)
        }
        if kind == -1 && fighter == .lightning {
            for side in [-1.0, 1.0] {
                let boom = SKShapeNode(rectOf: CGSize(width: 5, height: 49), cornerRadius: 1)
                boom.position = CGPoint(x: CGFloat(side) * 18, y: -3)
                boom.fillColor = color
                boom.strokeColor = .black.withAlphaComponent(0.4)
                node.addChild(boom)
            }
        }
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
        if gameTime - lastFormation > max(7, 14 - CGFloat(wave) * 0.6) {
            spawnFormation()
            lastFormation = gameTime
        }
        updateBandits(dt: dt, scrolling: scroll)
        updateRounds(dt: dt, scrolling: scroll)
        updateLabels()
    }

    private func spawnFormation() {
        let count = min(3 + wave / 2, 7)
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
        for i in 0..<count {
            let index = CGFloat(i)
            let row = CGFloat((i + 1) / 2)
            let sign: CGFloat = i % 2 == 0 ? -1 : 1
            let location = CGPoint(
                x: center.x - cos(toward) * row * 64 + cos(toward + .pi / 2) * sign * row * 63,
                y: center.y - sin(toward) * row * 64 + sin(toward + .pi / 2) * sign * row * 63
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
                                  fireCooldown: index * 0.18 + 1.5, targetOffset: CGFloat.random(in: -1.15...1.15)))
        }
        flash("INCOMING FORMATION — \(count) HOSTILES")
    }
    private func updateBandits(dt: CGFloat, scrolling: CGVector) {
        for i in bandits.indices {
            var b = bandits[i]
            b.formationTime -= dt
            b.fireCooldown -= dt
            let distance = hypot(player.position.x - b.position.x, player.position.y - b.position.y)
            let targetHeading = atan2(player.position.y - b.position.y, player.position.x - b.position.x)
            if b.formationTime <= 0 {
                // German fighters choose offsets and alternate between pursuit and break-away turns.
                let desired = targetHeading + (b.kind == 2 ? 0.65 : b.targetOffset * min(0.65, distance / 400))
                let delta = atan2(sin(desired - b.heading), cos(desired - b.heading))
                let maxTurn: CGFloat = (b.kind == 2 ? 1.05 : b.kind == 1 ? 2.15 : 1.65) * dt
                b.heading += max(-maxTurn, min(maxTurn, delta))
            }
            b.position.x += cos(b.heading) * b.speed * dt + scrolling.dx
            b.position.y += sin(b.heading) * b.speed * dt + scrolling.dy
            b.sprite.position = b.position
            b.sprite.zRotation = b.heading - .pi / 2
            // Fire only when the player is in a narrow forward cone.
            let relative = atan2(sin(targetHeading - b.heading), cos(targetHeading - b.heading))
            if b.formationTime <= 0 && b.fireCooldown <= 0 && distance < 490 && abs(relative) < 0.22 {
                fire(from: b.position, angle: b.heading, hostile: true)
                b.fireCooldown = CGFloat.random(in: 1.1...2.4)
            }
            bandits[i] = b
        }
        for i in bandits.indices.reversed() {
            let b = bandits[i]
            if b.position.x < -600 || b.position.x > size.width + 600 || b.position.y < -600 || b.position.y > size.height + 600 {
                b.sprite.removeFromParent(); bandits.remove(at: i)
            } else if hypot(b.position.x - player.position.x, b.position.y - player.position.y) < 34 && gameTime > invulnerableUntil {
                takeDamage()
            }
        }
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
                            burst(at: bandits[j].position, count: 18)
                            bandits[j].sprite.removeFromParent()
                            bandits.remove(at: j)
                            kills += 1
                            score += 100 * wave
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
        burst(at: player.position, count: 15)
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
        hud.text = "VECTOR ACES  |  \(fighter.rawValue.uppercased())  |  WAVE \(wave)  |  KILLS \(kills)  |  SCORE \(score)  |  AIRFRAME \(max(0, health))/\(fighter.health)  |  SPEED \(Int(airspeed))"
    }
    private func restart() {
        for b in bandits { b.sprite.removeFromParent() }
        for r in rounds { r.sprite.removeFromParent() }
        bandits.removeAll()
        rounds.removeAll()
        gameTime = 0
        lastFormation = -8
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
