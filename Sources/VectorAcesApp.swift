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
                        Text("ARROWS / WASD  MOVE     SPACE  FIRE     P  PAUSE     RETURN  RESTART")
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
    private let fighter: Fighter
    private var aircraft = SKNode()
    private var hull: SKShapeNode!
    private var keys = Set<UInt16>()
    private var shots: [SKNode] = []
    private var enemies: [SKNode] = []
    private var enemyHP: [ObjectIdentifier: Int] = [:]
    private var particles: [(SKNode, TimeInterval)] = []
    private var lastUpdate: TimeInterval = 0
    private var elapsed: TimeInterval = 0
    private var lastShot: TimeInterval = -1
    private var lastSpawn: TimeInterval = 0
    private var score = 0
    private var kills = 0
    private var wave = 1
    private var hp = 5
    private var stopped = false
    private var lost = false
    private let info = SKLabelNode(fontNamed: "Menlo-Bold")
    private let warning = SKLabelNode(fontNamed: "Menlo-Bold")
    private var clouds: [SKNode] = []
    private var terrain: [SKShapeNode] = []

    init(size: CGSize, fighter: Fighter) {
        self.fighter = fighter
        self.hp = fighter.health
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
    }
    required init?(coder: NSCoder) { fatalError("No storyboard") }

    override func didMove(to view: SKView) {
        backgroundColor = .init(red: 0.22, green: 0.39, blue: 0.53, alpha: 1)
        makeBackdrop()
        aircraft.position = CGPoint(x: size.width * 0.26, y: size.height * 0.51)
        let body = plane(color: fighter.color, enemy: false, kind: 0)
        aircraft.addChild(body); hull = body
        addChild(aircraft)
        info.fontSize = 15; info.horizontalAlignmentMode = .left
        info.position = CGPoint(x: 22, y: size.height - 36)
        info.zPosition = 50; addChild(info)
        warning.fontSize = 28; warning.position = CGPoint(x: size.width / 2, y: size.height / 2)
        warning.zPosition = 60; addChild(warning)
        updateHUD()
        view.window?.makeFirstResponder(self)
    }
    override var acceptsFirstResponder: Bool { true }
    override func keyDown(with event: NSEvent) {
        keys.insert(event.keyCode)
        if event.keyCode == 35 && !event.isARepeat && !lost { stopped.toggle(); warning.text = stopped ? "PAUSED  /  P TO RESUME" : "" }
        if event.keyCode == 36 && lost { reset() }
    }
    override func keyUp(with event: NSEvent) { keys.remove(event.keyCode) }
    override func resignFirstResponder() { keys.removeAll() }

    private func makeBackdrop() {
        for layer in 0..<3 {
            let ridge = SKShapeNode()
            var path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: 0))
            for i in 0...40 {
                let x = CGFloat(i) * size.width / 40
                let height = 85 + CGFloat(layer) * 28 + sin(CGFloat(i) * 0.77 + CGFloat(layer)) * 24 + cos(CGFloat(i) * 0.33) * 36
                path.addLine(to: CGPoint(x: x, y: height))
            }
            path.addLine(to: CGPoint(x: size.width, y: 0)); path.closeSubpath()
            ridge.path = path
            ridge.fillColor = layer == 2 ? .init(red: 0.16, green: 0.28, blue: 0.31, alpha: 1) : .init(red: 0.22, green: 0.38, blue: 0.37, alpha: 1)
            ridge.strokeColor = .init(white: 0.9, alpha: 0.14)
            ridge.zPosition = CGFloat(layer) - 12
            addChild(ridge); terrain.append(ridge)
        }
        let sun = SKShapeNode(circleOfRadius: 44)
        sun.position = CGPoint(x: size.width * 0.77, y: size.height * 0.77)
        sun.fillColor = .init(red: 1, green: 0.82, blue: 0.51, alpha: 0.72)
        sun.strokeColor = .clear; sun.glowWidth = 26
        sun.zPosition = -20; addChild(sun)
        for i in 0..<15 {
            let cloud = SKNode()
            let x = CGFloat(i % 5) * 255 - 80
            let y = size.height * 0.31 + CGFloat(i / 5) * 135 + CGFloat.random(in: -45...45)
            cloud.position = CGPoint(x: x, y: y); cloud.zPosition = -5
            for j in 0..<5 {
                let puff = SKShapeNode(ellipseOf: CGSize(width: CGFloat.random(in: 65...135), height: CGFloat.random(in: 18...38)))
                puff.position.x = CGFloat(j) * 36
                puff.fillColor = SKColor(white: 0.96, alpha: CGFloat.random(in: 0.12...0.3))
                puff.strokeColor = .clear
                cloud.addChild(puff)
            }
            addChild(cloud); clouds.append(cloud)
        }
    }

    private func plane(color: SKColor, enemy: Bool, kind: Int) -> SKShapeNode {
        // Original vector aircraft silhouettes: wing, cockpit, tail, nose and propeller.
        let path = CGMutablePath()
        let coords: [CGPoint] = [
            .init(x: -38,y: -5), .init(x: -22,y: -8), .init(x: -16,y: -21),
            .init(x: 2,y: -21), .init(x: 13,y: -7), .init(x: 37,y: -4),
            .init(x: 41,y: 0), .init(x: 37,y: 4), .init(x: 13,y: 7),
            .init(x: 2,y: 21), .init(x: -16,y: 21), .init(x: -22,y: 8),
            .init(x: -38,y: 5), .init(x: -37,y: 1)
        ]
        path.addLines(between: coords); path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = color
        node.strokeColor = enemy ? .init(red: 1, green: 0.51, blue: 0.32, alpha: 1) : .white
        node.lineWidth = 1.5
        let cockpit = SKShapeNode(ellipseOf: CGSize(width: 17, height: 9))
        cockpit.position.x = 4
        cockpit.fillColor = .init(red: 0.15, green: 0.37, blue: 0.5, alpha: 1)
        cockpit.strokeColor = .white.withAlphaComponent(0.6)
        node.addChild(cockpit)
        let prop = SKShapeNode(rectOf: CGSize(width: 3, height: 24), cornerRadius: 1)
        prop.position.x = 42
        prop.fillColor = .white.withAlphaComponent(0.65); prop.strokeColor = .clear
        node.addChild(prop)
        if enemy { node.xScale = -1 }
        if kind == 1 { node.setScale(1.3) }
        return node
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdate == 0 { lastUpdate = currentTime; return }
        let dt = min(currentTime - lastUpdate, 1.0 / 20.0)
        lastUpdate = currentTime
        if stopped || lost { return }
        elapsed += dt
        wave = max(1, Int(elapsed / 27) + 1)
        let dx: CGFloat = (keys.contains(124) || keys.contains(2) ? 1 : 0) - (keys.contains(123) || keys.contains(0) ? 1 : 0)
        let dy: CGFloat = (keys.contains(126) || keys.contains(13) ? 1 : 0) - (keys.contains(125) || keys.contains(1) ? 1 : 0)
        let diagonal = dx != 0 && dy != 0 ? CGFloat(0.7071) : 1
        aircraft.position.x = max(56, min(size.width - 74, aircraft.position.x + dx * diagonal * fighter.speed * dt))
        aircraft.position.y = max(125, min(size.height - 68, aircraft.position.y + dy * diagonal * fighter.speed * dt))
        hull.zRotation = dy * 0.14
        if keys.contains(49) && elapsed - lastShot > 0.14 { fire(); lastShot = elapsed }
        if elapsed - lastSpawn > max(0.45, 2.1 - Double(wave) * 0.12) { spawnEnemy(); lastSpawn = elapsed }
        for cloud in clouds { cloud.position.x -= 9 * dt; if cloud.position.x < -290 { cloud.position.x = size.width + 180 } }
        for shot in shots { shot.position.x += 760 * dt }
        for enemy in enemies {
            enemy.position.x -= (165 + CGFloat(wave * 9)) * dt
            enemy.position.y += sin(CGFloat(elapsed) * 2.5 + CGFloat(enemy.hash)) * 22 * dt
        }
        // Resolve each bullet against each aircraft at most once per frame.
        var spent = Set<ObjectIdentifier>()
        var destroyed = Set<ObjectIdentifier>()
        for shot in shots {
            for enemy in enemies where !destroyed.contains(ObjectIdentifier(enemy)) && !spent.contains(ObjectIdentifier(shot)) {
                if hypot(shot.position.x - enemy.position.x, shot.position.y - enemy.position.y) < 32 {
                    spent.insert(ObjectIdentifier(shot))
                    let key = ObjectIdentifier(enemy)
                    enemyHP[key, default: 1] -= 1
                    spark(at: shot.position, bright: true)
                    if enemyHP[key, default: 0] <= 0 {
                        destroyed.insert(key); kills += 1; score += 100 * wave
                        spark(at: enemy.position, bright: false)
                    }
                }
            }
        }
        shots.removeAll { shot in
            let remove = spent.contains(ObjectIdentifier(shot)) || shot.position.x > size.width + 20
            if remove { shot.removeFromParent() }; return remove
        }
        enemies.removeAll { enemy in
            let key = ObjectIdentifier(enemy)
            let hit = hypot(enemy.position.x - aircraft.position.x, enemy.position.y - aircraft.position.y) < 46
            let offscreen = enemy.position.x < -80
            if hit {
                hp -= 1; spark(at: aircraft.position, bright: false)
                aircraft.run(.sequence([.fadeAlpha(to: 0.25, duration: 0.09), .fadeAlpha(to: 1, duration: 0.16)]))
            }
            if hit || offscreen || destroyed.contains(key) {
                enemyHP.removeValue(forKey: key); enemy.removeFromParent()
                return true
            }
            return false
        }
        particles.removeAll { item in
            if elapsed > item.1 { item.0.removeFromParent(); return true }; return false
        }
        if hp <= 0 { lost = true; warning.text = "AIRCRAFT LOST  /  RETURN TO RESTART" }
        updateHUD()
    }

    private func fire() {
        let bullet = SKShapeNode(rectOf: CGSize(width: 23, height: 3), cornerRadius: 1)
        bullet.fillColor = .yellow; bullet.strokeColor = .orange
        bullet.glowWidth = 4; bullet.zPosition = 8
        bullet.position = CGPoint(x: aircraft.position.x + 47, y: aircraft.position.y)
        addChild(bullet); shots.append(bullet)
    }
    private func spawnEnemy() {
        let bomber = wave > 2 && Int.random(in: 0...5) == 0
        let enemy = SKNode()
        enemy.position = CGPoint(x: size.width + 60, y: CGFloat.random(in: 170...(size.height - 65)))
        enemy.zPosition = 4
        enemy.addChild(plane(color: bomber ? .init(red: 0.39, green: 0.44, blue: 0.37, alpha: 1) : .init(red: 0.37, green: 0.44, blue: 0.43, alpha: 1), enemy: true, kind: bomber ? 1 : 0))
        addChild(enemy); enemies.append(enemy)
        enemyHP[ObjectIdentifier(enemy)] = bomber ? 4 : (wave > 3 ? 2 : 1)
    }
    private func spark(at point: CGPoint, bright: Bool) {
        for _ in 0..<12 {
            let piece = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            piece.position = point; piece.zPosition = 15
            piece.fillColor = bright ? .yellow : .orange; piece.strokeColor = .clear
            let vx = CGFloat.random(in: -90...90), vy = CGFloat.random(in: -85...85)
            piece.run(.group([.moveBy(x: vx, y: vy, duration: 0.42), .fadeOut(withDuration: 0.42), .scale(to: 0.2, duration: 0.42)]))
            addChild(piece); particles.append((piece, elapsed + 0.43))
        }
    }
    private func updateHUD() {
        info.text = "VECTOR ACES  /  \(fighter.rawValue.uppercased())     WAVE \(wave)     SCORE \(score)     KILLS \(kills)     AIRFRAME \(max(0,hp))/\(fighter.health)"
    }
    private func reset() {
        for enemy in enemies { enemy.removeFromParent() }
        for shot in shots { shot.removeFromParent() }
        for item in particles { item.0.removeFromParent() }
        enemies.removeAll(); shots.removeAll(); particles.removeAll(); enemyHP.removeAll()
        elapsed = 0; lastSpawn = 0; lastShot = -1; score = 0; kills = 0; wave = 1
        hp = fighter.health; stopped = false; lost = false; keys.removeAll()
        aircraft.position = CGPoint(x: size.width * 0.26, y: size.height * 0.51)
        warning.text = ""; updateHUD()
    }
}
