import AppKit
import SwiftUI
import SpriteKit
import AVFoundation

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

extension Fighter {
    var role: String {
        switch self {
        case .mustang: return "LONG-RANGE ESCORT FIGHTER"
        case .thunderbolt: return "HEAVY GUNFIGHTER"
        case .lightning: return "TWIN-ENGINE INTERCEPTOR"
        case .warhawk: return "AGILE PURSUIT FIGHTER"
        }
    }
    var catalogDescription: String {
        switch self {
        case .mustang: return "The Mustang is a versatile escort fighter with tremendous speed and excellent high-altitude performance. A balanced choice for turning engagements, pursuit and sustained combat."
        case .thunderbolt: return "The Thunderbolt brings a rugged radial engine, formidable eight-gun armament and exceptional durability. Best used in powerful attack runs and extended firing passes."
        case .lightning: return "The Lightning's distinctive twin booms, twin engines and tightly grouped nose guns make it a stable long-range interceptor with devastating concentrated fire."
        case .warhawk: return "The Warhawk offers responsive handling and a direct, aggressive fighting style. Its rugged construction and wing-mounted guns favor close-range engagements."
        }
    }
    var armament: String {
        switch self {
        case .mustang: return "6 × .50 CAL WING MACHINE GUNS"
        case .thunderbolt: return "8 × .50 CAL WING MACHINE GUNS"
        case .lightning: return "1 × 20 MM CANNON + 4 × .50 CAL NOSE GUNS"
        case .warhawk: return "6 × .50 CAL WING MACHINE GUNS"
        }
    }
    var stats: [(String, Int)] {
        switch self {
        case .mustang: return [("SPEED",9),("ACCELERATION",8),("TURN",8),("CLIMB",8),("DURABILITY",6),("FIREPOWER",7),("AMMO",7)]
        case .thunderbolt: return [("SPEED",7),("ACCELERATION",6),("TURN",5),("CLIMB",6),("DURABILITY",10),("FIREPOWER",9),("AMMO",10)]
        case .lightning: return [("SPEED",8),("ACCELERATION",7),("TURN",7),("CLIMB",7),("DURABILITY",7),("FIREPOWER",9),("AMMO",8)]
        case .warhawk: return [("SPEED",7),("ACCELERATION",7),("TURN",8),("CLIMB",6),("DURABILITY",5),("FIREPOWER",7),("AMMO",6)]
        }
    }
    var ammunition: Int {
        switch self {
        case .mustang: return 1800
        case .thunderbolt: return 2720
        case .lightning: return 1100
        case .warhawk: return 1400
        }
    }
}
private enum AcesStyle {
    static let ice = Color(red: 0.5, green: 0.88, blue: 0.98)
    static let amber = Color(red: 1, green: 0.72, blue: 0.37)
    static let panel = Color(red: 0.065, green: 0.115, blue: 0.17)
}
private struct FighterIllustration: View {
    var fighter: Fighter
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let unit = min(size.width / 175, size.height / 170)
            // High contrast overhead technical illustration, drawn from
            // original paths rather than unlicensed historical imagery.
            var outline = Path()
            let wing: CGFloat = fighter == .lightning ? 72 : fighter == .thunderbolt ? 67 : fighter == .mustang ? 59 : 55
            let tipY: CGFloat = fighter == .mustang ? -1 : fighter == .thunderbolt ? 9 : fighter == .lightning ? 2 : 14
            let rootY: CGFloat = fighter == .mustang ? 11 : fighter == .thunderbolt ? 6 : 16
            let noseY: CGFloat = fighter == .thunderbolt ? 77 : 90
            let pts: [CGPoint] = [
                .init(x:-7,y:noseY-12),.init(x:-11,y:38),
                .init(x:-wing*0.85,y:rootY),.init(x:-wing,y:tipY+5),
                .init(x:-wing,y:tipY-11),.init(x:-13,y:-23),
                .init(x:-9,y:-65),.init(x:-4,y:-80),
                .init(x:4,y:-80),.init(x:9,y:-65),
                .init(x:13,y:-23),.init(x:wing,y:tipY-11),
                .init(x:wing,y:tipY+5),.init(x:wing*0.85,y:rootY),
                .init(x:11,y:38),.init(x:7,y:noseY-12),.init(x:0,y:noseY)
            ]
            for (i,p) in pts.enumerated() {
                let q = CGPoint(x:center.x+p.x*unit,y:center.y-p.y*unit)
                if i == 0 { outline.move(to:q) } else { outline.addLine(to:q) }
            }
            outline.closeSubpath()
            context.fill(outline, with: .color(Color(red: 0.54, green: 0.69, blue: 0.7).opacity(0.93)))
            context.stroke(outline, with: .color(AcesStyle.ice), lineWidth: 2)
            for side in [CGFloat(-1), CGFloat(1)] {
                let x = center.x + side * wing * 0.63 * unit
                let circle = Path(ellipseIn:CGRect(x:x-9*unit,y:center.y-9*unit,width:18*unit,height:18*unit))
                context.fill(circle, with:.color(.white.opacity(0.94)))
                context.stroke(circle, with:.color(.blue), lineWidth:3)
                if fighter == .lightning {
                    let boom = CGRect(x:center.x+side*30*unit-4*unit,y:center.y-45*unit,width:8*unit,height:98*unit)
                    context.fill(Path(roundedRect:boom,cornerRadius:3),with:.color(Color(red:0.36,green:0.53,blue:0.59)))
                    context.stroke(Path(roundedRect:boom,cornerRadius:3),with:.color(AcesStyle.ice),lineWidth:1.2)
                }
            }
            let canopy = Path(ellipseIn:CGRect(x:center.x-8*unit,y:center.y-36*unit,width:16*unit,height:32*unit))
            context.fill(canopy, with:.color(Color(red:0.10,green:0.24,blue:0.37)))
            context.stroke(canopy, with:.color(AcesStyle.ice),lineWidth:1.8)
            // Aerodynamic and engineering details: engine, ailerons, gun ports.
            let cowling = Path(ellipseIn:CGRect(x:center.x-9*unit,y:center.y-70*unit,width:18*unit,height:15*unit))
            context.stroke(cowling,with:.color(AcesStyle.ice.opacity(0.57)),lineWidth:1.6)
            for side in [CGFloat(-1),CGFloat(1)] {
                var aileron = Path()
                aileron.move(to:CGPoint(x:center.x+side*wing*0.46*unit,
                                        y:center.y-tipY*unit+4*unit))
                aileron.addLine(to:CGPoint(x:center.x+side*wing*0.89*unit,
                                            y:center.y-tipY*unit+7*unit))
                context.stroke(aileron,with:.color(AcesStyle.ice.opacity(0.43)),lineWidth:1)
                for port in 0..<(fighter == .thunderbolt ? 4 : fighter == .lightning ? 0 : 3) {
                    let barrel = Path(ellipseIn:CGRect(x:center.x+side*CGFloat(22+port*8)*unit-1.4*unit,
                                                        y:center.y-(rootY+1)*unit,
                                                        width:2.8*unit,height:5*unit))
                    context.fill(barrel,with:.color(.black.opacity(0.75)))
                }
            }
            let tail = CGRect(x:center.x-25*unit,y:center.y+61*unit,width:50*unit,height:5*unit)
            context.fill(Path(tail),with:.color(AcesStyle.ice.opacity(0.7)))
            for delta in [-0.42,0.42] {
                var line = Path()
                line.move(to:CGPoint(x:center.x+delta*wing*unit,y:center.y-10*unit))
                line.addLine(to:CGPoint(x:center.x+delta*wing*unit,y:center.y+12*unit))
                context.stroke(line,with:.color(.black.opacity(0.4)),lineWidth:1)
            }
            let technical = fighter == .lightning ? "TWIN BOOM / NOSE BATTERY" :
                fighter == .thunderbolt ? "RADIAL ENGINE / 8-GUN WINGS" :
                fighter == .mustang ? "LAMINAR WING / LONG RANGE" :
                "INLINE ENGINE / PURSUIT"
            context.draw(Text("TOP VIEW / SCHEMATIC").font(.system(size:10,weight:.medium,design:.monospaced)).foregroundColor(AcesStyle.ice.opacity(0.65)),at:CGPoint(x:112,y:15))
            context.draw(Text(technical).font(.system(size:10,weight:.medium,design:.monospaced)).foregroundColor(AcesStyle.amber.opacity(0.8)),at:CGPoint(x:size.width-125,y:size.height-17))
        }
        .background {
            GeometryReader { geometry in
                Path { p in
                    for x in stride(from:CGFloat(0),through:geometry.size.width,by:30) {
                        p.move(to:CGPoint(x:x,y:0));p.addLine(to:CGPoint(x:x,y:geometry.size.height))
                    }
                    for y in stride(from:CGFloat(0),through:geometry.size.height,by:30) {
                        p.move(to:CGPoint(x:0,y:y));p.addLine(to:CGPoint(x:geometry.size.width,y:y))
                    }
                }.stroke(AcesStyle.ice.opacity(0.07),lineWidth:0.7)
            }
        }
    }
}
private struct AcesSettings: View {
    @AppStorage("aces.effectsVolume") private var effectsVolume = 0.7
    @AppStorage("aces.musicVolume") private var musicVolume = 0.35
    @AppStorage("aces.telemetryOpacity") private var telemetryOpacity = 0.35
    @AppStorage("aces.radarBrightness") private var radarBrightness = 0.75
    @AppStorage("aces.screenShake") private var screenShake = 0.7
    @AppStorage("aces.difficulty") private var difficulty = 1
    @AppStorage("aces.enemyDensity") private var enemyDensity = 1.0
    @AppStorage("aces.cloudDensity") private var cloudDensity = 1.0
    @AppStorage("aces.startWave") private var startWave = 1
    @AppStorage("aces.unlimitedAmmo") private var unlimitedAmmo = false
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section("COMBAT") {
                Picker("Difficulty", selection:$difficulty) {
                    Text("Rookie").tag(0);Text("Veteran").tag(1);Text("Ace").tag(2)
                }
                .pickerStyle(.segmented)
                HStack { Text("Enemy density"); Slider(value:$enemyDensity,in:0.6...1.6) }
                Stepper("Starting wave: \(startWave)",value:$startWave,in:1...10)
                Toggle("Unlimited ammunition",isOn:$unlimitedAmmo)
            }
            Section("DISPLAY") {
                HStack { Text("Telemetry opacity"); Slider(value:$telemetryOpacity,in:0.12...0.85) }
                HStack { Text("Radar brightness"); Slider(value:$radarBrightness,in:0.3...1) }
                HStack { Text("Cloud density"); Slider(value:$cloudDensity,in:0.3...1.5) }
                HStack { Text("Screen shake"); Slider(value:$screenShake,in:0...1) }
            }
            Section("AUDIO") {
                HStack { Text("Effects volume"); Slider(value:$effectsVolume,in:0...1) }
                HStack { Text("Music volume (reserved)"); Slider(value:$musicVolume,in:0...1) }
            }
            Button("DONE") { dismiss() }.frame(maxWidth:.infinity)
        }
        .formStyle(.grouped)
        .frame(minWidth:540,minHeight:560)
    }
}
@main struct VectorAcesApp: App {
    @AppStorage("aces.selectedFighter") private var selectedFighter = Fighter.mustang.rawValue
    @State private var started = false
    @State private var showingSettings = false
    @AppStorage("aces.hasSave") private var hasSave = false
    private var fighter: Fighter { Fighter(rawValue:selectedFighter) ?? .mustang }
    var body: some Scene {
        WindowGroup("Vector Aces") {
            ZStack {
                Color(red:0.025,green:0.045,blue:0.077).ignoresSafeArea()
                if started {
                    GameSurface(fighter:fighter)
                        .id(fighter)
                        .overlay(alignment:.topTrailing) {
                            Button("HANGAR") { started = false }
                                .keyboardShortcut(.escape,modifiers:[])
                                .padding(14)
                        }
                } else {
                    ScrollView {
                        VStack(alignment:.leading,spacing:22) {
                            HStack {
                                VStack(alignment:.leading,spacing:5) {
                                    Text("FUN CITY  /  VECTOR SERIES  /  HANGAR")
                                        .font(.system(size:11,weight:.bold,design:.monospaced))
                                        .tracking(2).foregroundStyle(AcesStyle.ice)
                                    Text("VECTOR ACES")
                                        .font(.system(size:42,weight:.black,design:.rounded))
                                    Text("WORLD WAR II  •  AIRCRAFT CATALOG")
                                        .font(.system(size:12,weight:.medium,design:.monospaced))
                                        .tracking(3).foregroundStyle(AcesStyle.amber)
                                }
                                Spacer()
                                Button("CUSTOM SETTINGS") { showingSettings = true }
                                    .buttonStyle(.bordered).tint(AcesStyle.ice)
                            }
                            HStack(alignment:.top,spacing:18) {
                                VStack(alignment:.leading,spacing:13) {
                                    Text("SELECT AIRCRAFT").font(.system(size:12,weight:.bold,design:.monospaced))
                                        .tracking(2).foregroundStyle(AcesStyle.ice)
                                    ForEach(Fighter.allCases) { choice in
                                        Button {
                                            selectedFighter = choice.rawValue
                                            CombatAudio.shared.play(.menu,volume:0.16)
                                        } label: {
                                            VStack(alignment:.leading,spacing:7) {
                                                HStack {
                                                    Text(choice.rawValue.uppercased())
                                                        .font(.system(size:15,weight:.bold,design:.monospaced))
                                                    Spacer()
                                                    if choice == fighter { Image(systemName:"checkmark.circle.fill") }
                                                }
                                                Text(choice.role).font(.system(size:9,design:.monospaced))
                                                    .foregroundStyle(.white.opacity(0.58))
                                            }
                                            .padding(15)
                                            .frame(maxWidth:.infinity,alignment:.leading)
                                            .background(choice == fighter ? AcesStyle.ice.opacity(0.19) : .white.opacity(0.055),
                                                        in:RoundedRectangle(cornerRadius:8))
                                            .overlay(RoundedRectangle(cornerRadius:8).stroke(choice == fighter ? AcesStyle.ice : .white.opacity(0.08)))
                                        }.buttonStyle(.plain)
                                    }
                                    Spacer(minLength:12)
                                    if hasSave {
                                        Button("RESUME SORTIE") {
                                            UserDefaults.standard.set(true, forKey: "aces.resumeRequested")
                                            started = true
                                        }
                                        .font(.system(size:13,weight:.bold,design:.monospaced))
                                        .frame(maxWidth:.infinity).padding(12)
                                        .background(AcesStyle.ice.opacity(0.22),in:RoundedRectangle(cornerRadius:8))
                                    }
                                    Button("START NEW SORTIE") {
                                        CombatAudio.shared.play(.menu,volume:0.18)
                                        UserDefaults.standard.set(false, forKey: "aces.resumeRequested")
                                        started = true
                                    }
                                        .font(.system(size:17,weight:.black,design:.monospaced))
                                        .frame(maxWidth:.infinity).padding(14)
                                        .background(AcesStyle.amber,in:RoundedRectangle(cornerRadius:8))
                                        .foregroundStyle(.black)
                                    Text("← → TURN  •  ↑ ↓ SPEED  •  Q/E ALTITUDE\nSPACE FIRE  •  P PAUSE  •  RETURN RESTART")
                                        .font(.system(size:10,design:.monospaced))
                                        .foregroundStyle(.white.opacity(0.55))
                                        .fixedSize(horizontal:false,vertical:true)
                                }
                                .padding(18)
                                .frame(width:330).frame(minHeight:570)
                                .background(AcesStyle.panel,in:RoundedRectangle(cornerRadius:14))
                                VStack(alignment:.leading,spacing:12) {
                                    HStack {
                                        VStack(alignment:.leading,spacing:4) {
                                            Text(fighter.rawValue.uppercased())
                                                .font(.system(size:24,weight:.black,design:.monospaced))
                                            Text(fighter.role)
                                                .font(.system(size:11,weight:.semibold,design:.monospaced))
                                                .foregroundStyle(AcesStyle.amber)
                                        }
                                        Spacer()
                                        Text("AIRCRAFT FILE  /  1940s")
                                            .font(.system(size:10,design:.monospaced))
                                            .foregroundStyle(AcesStyle.ice.opacity(0.7))
                                    }
                                    FighterIllustration(fighter:fighter)
                                        .frame(height:226)
                                        .background(.black.opacity(0.18),in:RoundedRectangle(cornerRadius:8))
                                    LazyVGrid(columns:[GridItem(.flexible()),GridItem(.flexible())],spacing:10) {
                                        ForEach(0..<fighter.stats.count,id:\.self) { index in
                                            let stat = fighter.stats[index]
                                            VStack(alignment:.leading,spacing:5) {
                                                HStack {
                                                    Text(stat.0).font(.system(size:10,weight:.bold,design:.monospaced))
                                                    Spacer()
                                                    Text("\(stat.1)/10").font(.system(size:10,design:.monospaced))
                                                }.foregroundStyle(.white.opacity(0.85))
                                                GeometryReader { geo in
                                                    ZStack(alignment:.leading) {
                                                        Capsule().fill(.white.opacity(0.08))
                                                        Capsule().fill(AcesStyle.ice)
                                                            .frame(width:geo.size.width * CGFloat(stat.1) / 10)
                                                    }
                                                }.frame(height:5)
                                            }
                                        }
                                    }
                                    Text(fighter.catalogDescription)
                                        .font(.system(size:13))
                                        .foregroundStyle(.white.opacity(0.78))
                                        .fixedSize(horizontal:false,vertical:true)
                                    Text("ARMAMENT  /  \(fighter.armament)")
                                        .font(.system(size:10,weight:.bold,design:.monospaced))
                                        .foregroundStyle(AcesStyle.amber)
                                }
                                .padding(20)
                                .frame(maxWidth:.infinity,alignment:.leading)
                                .background(AcesStyle.panel,in:RoundedRectangle(cornerRadius:14))
                            }
                        }
                        .padding(25)
                        .frame(maxWidth:1280)
                        .frame(maxWidth:.infinity)
                    }
                }
            }
            .preferredColorScheme(.dark)
            .frame(minWidth:1000,minHeight:670)
            .sheet(isPresented:$showingSettings) { AcesSettings() }
        }
        .defaultSize(width:1250,height:820)
    }
}
private struct GameSurface: NSViewRepresentable {
    let fighter: Fighter
    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.presentScene(AirBattleScene(size:CGSize(width:1200,height:720),fighter:fighter))
        DispatchQueue.main.async { view.window?.makeFirstResponder(view.scene) }
        return view
    }
    func updateNSView(_ nsView: SKView,context: Context) {}
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
    private var ammo: Int
    private var altitude: CGFloat = 7600
    private var climbRate: CGFloat = 0
    private var bankAngle: CGFloat = 0
    private var deathStarted = false
    private var radarSweep: CGFloat = 0
    private var lastRadarRender: CGFloat = -1
    private let attitude = SKNode()
    private let attitudePanel = SKShapeNode()
    private let radarSweepNode = SKNode()
    private let sounds = CombatAudio.shared
    private let prefs = UserDefaults.standard

    init(size: CGSize, fighter: Fighter) {
        self.fighter = fighter
        self.health = fighter.health
        self.ammo = fighter.ammunition
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
        player.setScale(0.9)
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
        if prefs.bool(forKey: "aces.resumeRequested") { loadRun() }
        prefs.set(false, forKey: "aces.resumeRequested")
        updateLabels()
        sounds.startEngine(volume:effectsVolume * 0.18)
        view.window?.makeFirstResponder(self)
    }
    override func willMove(from view: SKView) {
        if !gameOver && !deathStarted { saveRun() }
        sounds.stopEngine()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        hud.position = CGPoint(x: 24, y: size.height - 22)
        status.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        threat.position = CGPoint(x: size.width - 24, y: size.height - 306)
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
                cloud.alpha = CGFloat.random(in: 0.53...0.83) *
                    CGFloat(prefs.object(forKey:"aces.cloudDensity") as? Double ?? 1.0)
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
                // NSBitmapImageRep's first row is the TOP; SpriteKit's scene
                // coordinates increase UP. Flip sample Y to keep adjacent
                // north/south tiles geographically seamless.
                let y = originY + Double(n - 1 - py) * 2
                let regional = terrainNoise(x, y, 2800, 3)
                let ridge = terrainNoise(x, y, 670, 7)
                let foliage = terrainNoise(x, y, 165, 11)
                let thicket = terrainNoise(x, y, 47, 13)
                let grit = terrainNoise(x, y, 8, 17)
                let flecks = terrainHash(Int(x), Int(y), 23)
                let vegetation = 0.32 * regional + 0.28 * ridge +
                                 0.24 * foliage + 0.14 * thicket + 0.02 * grit

                // A WORLD-SPACE RIVER: one smoothly winding continuous channel.
                // Small streams converge toward its floodplain.
                let river = 750 + sin(y / 525) * 350 + sin(y / 163) * 85 +
                            sin(y / 59) * 19
                let waterDist = abs(x - river)
                let tributary = river + 510 + sin(y / 320 + 1.7) * 72
                let tributaryDist = abs(x - tributary)
                let channel = waterDist < 17 || (tributaryDist < 6 && y.truncatingRemainder(dividingBy: 2100) > 760)
                let floodplain = waterDist < 75 || tributaryDist < 22

                // One road follows the high, dry east bank. Periodic crossing
                // roads connect it to farms and villages, using an explicit
                // bridge at the river rather than terminating at the water.
                let roadX = river + 122 + sin(y / 360) * 13
                let northRoadDistance = abs(x - roadX)
                let crossingIndex = Int(floor((y - 470) / 1450))
                let crossingY = Double(crossingIndex) * 1450 + 470 +
                                sin(x / 370) * 21
                let nextCrossingY = Double(crossingIndex + 1) * 1450 + 470 +
                                    sin(x / 370) * 21
                let crossDistance = min(abs(y - crossingY), abs(y - nextCrossingY))
                let bridge = crossDistance < 7 && waterDist < 24
                let roadDistance = min(northRoadDistance, crossDistance)
                // Road shoulders appear on dry land; only an explicit bridge
                // is allowed to overwrite river water.
                let gravelRoad = roadDistance < 5 && (!channel || bridge)

                // Settlements emerge beside road junctions, not at random
                // intersections in a repeating grid.
                let hamletY = Double(Int(floor((y - 470) / 1450 + 0.5))) * 1450 + 470
                let hamletRiver = 750 + sin(hamletY / 525) * 350 +
                                  sin(hamletY / 163) * 85 + sin(hamletY / 59) * 19
                let hamletX = hamletRiver + 145 + sin(hamletY / 360) * 13
                let villageDistance = hypot((x - hamletX) / 150,
                                            (y - hamletY) / 135)
                let settlement = villageDistance < 1.0 &&
                                 !floodplain && roadDistance < 155
                let lotX = Int(floor((x - hamletX) / 25))
                let lotY = Int(floor((y - hamletY) / 30))
                let roof = settlement && terrainHash(lotX, lotY, 99) > 0.53 &&
                           abs(x - (hamletX + Double(lotX) * 25 + 12)) < 7 &&
                           abs(y - (hamletY + Double(lotY) * 30 + 12)) < 9 &&
                           roadDistance > 12

                // Agricultural parcels surround settlements and roads, while
                // woods occupy more uneven land beyond their cleared margins.
                let cultivated = villageDistance < 4.4 ||
                                 northRoadDistance < 360 ||
                                 crossDistance < 270
                let parcelX = Int(floor((x + sin(y / 420) * 74) / 220))
                let parcelY = Int(floor((y + cos(x / 390) * 60) / 170))
                let parcel = terrainHash(parcelX, parcelY, 31)
                let fieldBand = 0.83 + 0.17 * terrainNoise(x, y, 35, 41)
                let woodland = vegetation > (cultivated ? 0.58 : 0.43)
                var red: Double
                var green: Double
                var blue: Double
                if bridge {
                    red = 147 + grit * 16
                    green = 137 + grit * 12
                    blue = 112 + grit * 14
                } else if channel {
                    red = 39 + ridge * 21
                    green = 74 + ridge * 32
                    blue = 83 + foliage * 29
                } else if floodplain {
                    red = 105 + ridge * 32
                    green = 116 + ridge * 32
                    blue = 86 + ridge * 19
                } else if roof {
                    red = 133 + flecks * 35
                    green = 85 + flecks * 25
                    blue = 63 + flecks * 18
                } else if gravelRoad {
                    red = 146 + grit * 19
                    green = 138 + grit * 17
                    blue = 112 + grit * 14
                } else if settlement {
                    red = 111 + grit * 27
                    green = 119 + grit * 23
                    blue = 78 + grit * 17
                } else if woodland {
                    red = 32 + thicket * 30
                    green = 55 + thicket * 48
                    blue = 29 + thicket * 22
                } else if cultivated {
                    red = (88 + parcel * 79) * fieldBand
                    green = (97 + parcel * 65) * fieldBand
                    blue = (48 + parcel * 48) * fieldBand
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
        if deathStarted { return }
        gameTime += dt
        if Int(gameTime) % 12 == 0 && Int(gameTime - dt) % 12 != 0 { saveRun() }
        wave = max(1, prefs.integer(forKey: "aces.startWave")) + Int(gameTime / 36)
        let left = keys.contains(123) || keys.contains(0)
        let right = keys.contains(124) || keys.contains(2)
        let thrust = keys.contains(126) || keys.contains(13)
        let brake = keys.contains(125) || keys.contains(1)
        let turnRate: CGFloat = fighter == .thunderbolt ? 2.25 : 2.8
        if left { heading += turnRate * dt }
        if right { heading -= turnRate * dt }
        let bankTarget: CGFloat = left ? -0.65 : right ? 0.65 : 0
        bankAngle += (bankTarget - bankAngle) * min(1, dt * 3.6)
        if keys.contains(12) { climbRate = min(650, climbRate + 950 * dt) }
        else if keys.contains(14) { climbRate = max(-900, climbRate - 1050 * dt) }
        else { climbRate += (0 - climbRate) * min(1, dt * 3) }
        altitude = max(300, min(30000, altitude + climbRate * dt))
        if thrust { airspeed += 205 * dt }
        if brake { airspeed -= 235 * dt }
        airspeed += (-climbRate * 0.012) * dt
        airspeed = max(105, min(fighter.speed + 95, airspeed))
        sounds.engineVolume = Float(effectsVolume * (0.08 + Double(airspeed) / 1900))
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
        radarSweep += dt * 1.85
        if gameTime - lastFormation > max(8, 13.5 - CGFloat(wave) * 0.35) / CGFloat(max(0.5, prefs.double(forKey: "aces.enemyDensity") == 0 ? 1 : prefs.double(forKey: "aces.enemyDensity"))) && bandits.count < 15 {
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
            sprite.setScale((kind == 2 ? 1.17 : kind == 1 ? 0.87 : 0.96) * 0.9)
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
                sounds.play(.gun, volume:effectsVolume * 0.075)
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
                if gameTime - lastWarning > 4 {
                    sounds.play(.warning,volume:effectsVolume * 0.3)
                    lastWarning = gameTime
                }
                rearThreat = true
                break
            }
        }
        threat.text = rearThreat ? "⚠ SIX O'CLOCK — BANDIT BEHIND" : ""
    }

    private func firePlayerWeapons() {
        // Wing-mounted .50-caliber guns on P-51, P-47 and P-40;
        // P-38 concentrates its cannon and machine guns in the nose.
        if ammo < 2 && !prefs.bool(forKey: "aces.unlimitedAmmo") { return }
        if !prefs.bool(forKey: "aces.unlimitedAmmo") { ammo -= 2 }
        sounds.play(.gun, volume: effectsVolume * 0.25)
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
                            crashPlane(bandits[j].sprite, position: bandits[j].position, duration: 1.05)
                            sounds.play(.explosion, volume: effectsVolume * 0.65)
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
        let difficulty = prefs.integer(forKey:"aces.difficulty")
        health -= difficulty == 2 ? 2 : 1
        invulnerableUntil = gameTime + 0.75
        burst(at: player.position, count: 24)
        sounds.play(.hit, volume: effectsVolume * 0.45)
        if health <= 0 {
            sounds.stopEngine()
            beginPlayerCrash()
        } else {
            player.run(.sequence([.fadeAlpha(to: 0.25, duration: 0.1), .fadeAlpha(to: 1, duration: 0.25)]))
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
    private func saveRun() {
        let snapshot: [String: Any] = [
            "fighter": fighter.rawValue, "score":score, "kills":kills,
            "health":health, "ammo":ammo, "elapsed":Double(gameTime),
            "altitude":Double(altitude), "airspeed":Double(airspeed),
            "heading":Double(heading), "playerX":Double(player.position.x),
            "playerY":Double(player.position.y),
            "offsetX":Double(terrainOffset.x), "offsetY":Double(terrainOffset.y)
        ]
        prefs.set(snapshot, forKey:"aces.savedRun")
        prefs.set(true, forKey:"aces.hasSave")
    }
    private func loadRun() {
        guard let saved = prefs.dictionary(forKey:"aces.savedRun"),
              saved["fighter"] as? String == fighter.rawValue else { return }
        score = saved["score"] as? Int ?? 0
        kills = saved["kills"] as? Int ?? 0
        health = saved["health"] as? Int ?? fighter.health
        ammo = saved["ammo"] as? Int ?? fighter.ammunition
        gameTime = CGFloat(saved["elapsed"] as? Double ?? 0)
        altitude = CGFloat(saved["altitude"] as? Double ?? 7600)
        airspeed = CGFloat(saved["airspeed"] as? Double ?? 210)
        heading = CGFloat(saved["heading"] as? Double ?? (.pi/2))
        player.position = CGPoint(x:CGFloat(saved["playerX"] as? Double ?? Double(size.width/2)),
                                  y:CGFloat(saved["playerY"] as? Double ?? Double(size.height/2)))
        terrainOffset = CGPoint(x:CGFloat(saved["offsetX"] as? Double ?? 0),
                                y:CGFloat(saved["offsetY"] as? Double ?? 0))
        updateTerrainTiles(initial:true)
        player.zRotation = heading - .pi/2
        lastFormation = gameTime - 5
    }

    private var effectsVolume: Double {
        let value = prefs.object(forKey: "aces.effectsVolume") as? Double
        return value ?? 0.7
    }
    private func crashPlane(_ plane: SKNode, position: CGPoint, duration: TimeInterval) {
        plane.removeAllActions()
        let smoke = SKEmitterNode()
        smoke.particleBirthRate = 65
        smoke.particleLifetime = 0.7
        smoke.particleSpeed = 24
        smoke.particleSpeedRange = 20
        smoke.particleAlpha = 0.6
        smoke.particleAlphaSpeed = -0.8
        smoke.particleScale = 0.13
        smoke.particleScaleSpeed = 0.1
        smoke.particleColor = .darkGray
        smoke.particleColorBlendFactor = 1
        let particle = SKTexture(image: NSImage(size: CGSize(width: 8,height: 8), flipped:false) { rect in
            NSColor.white.setFill()
            NSBezierPath(ovalIn: rect).fill()
            return true
        })
        smoke.particleTexture = particle
        plane.addChild(smoke)
        plane.run(.sequence([
            .group([
                .rotate(byAngle: CGFloat.pi * 2.2, duration:duration),
                .moveBy(x: CGFloat.random(in:-90...90), y:-165, duration:duration),
                .scale(to:0.14,duration:duration),
                .fadeAlpha(to:0.3,duration:duration)
            ]),
            .run { [weak self] in
                self?.burst(at:plane.position,count:65)
                self?.sounds.play(.explosion,volume:(self?.effectsVolume ?? 0.7) * 0.95)
                self?.shakeCamera()
            },
            .removeFromParent()
        ]))
    }
    private func beginPlayerCrash() {
        if deathStarted { return }
        deathStarted = true
        status.text = "MAYDAY — AIRCRAFT GOING DOWN"
        keys.removeAll()
        sounds.play(.explosion,volume:effectsVolume * 0.45)
        crashPlane(player,position:player.position,duration:1.65)
        run(.sequence([.wait(forDuration:1.7),.run { [weak self] in
            self?.gameOver = true
            self?.prefs.set(false, forKey: "aces.hasSave")
            self?.prefs.removeObject(forKey: "aces.savedRun")
            self?.status.text = "SHOT DOWN — RETURN TO RESTART"
        }]))
    }
    private func shakeCamera() {
        let intensity = CGFloat(prefs.object(forKey: "aces.screenShake") as? Double ?? 0.7)
        guard intensity > 0 else { return }
        // Shake the world, not the HUD.
        let shakes: [SKAction] = (0..<10).flatMap { i -> [SKAction] in
            let strength = intensity * CGFloat(10-i)
            return [.moveBy(x:CGFloat.random(in:-strength...strength),
                            y:CGFloat.random(in:-strength...strength),duration:0.025),
                    .move(to:.zero,duration:0.025)]
        }
        environment.run(.sequence(shakes + [.move(to:.zero,duration:0.01)]))
    }
    private func updateAttitude() {
        attitude.removeAllChildren()
        let radius: CGFloat = 52
        let rim = SKShapeNode(circleOfRadius:radius)
        rim.fillColor = .black.withAlphaComponent(0.7)
        rim.strokeColor = .cyan.withAlphaComponent(0.5)
        rim.lineWidth = 2
        attitude.addChild(rim)
        let mask = SKCropNode()
        let aperture = SKShapeNode(circleOfRadius:radius-3)
        aperture.fillColor = .white
        mask.maskNode = aperture
        attitude.addChild(mask)
        let horizon = SKNode()
        horizon.zRotation = -bankAngle
        horizon.position.y = CGFloat(climbRate/21)
        let sky = SKShapeNode(rectOf:CGSize(width:150,height:110))
        sky.position.y = 55
        sky.fillColor = SKColor(red:0.23,green:0.45,blue:0.69,alpha:1)
        sky.strokeColor = .clear
        horizon.addChild(sky)
        let ground = SKShapeNode(rectOf:CGSize(width:150,height:110))
        ground.position.y = -55
        ground.fillColor = SKColor(red:0.55,green:0.37,blue:0.20,alpha:1)
        ground.strokeColor = .clear
        horizon.addChild(ground)
        let line = SKShapeNode(rectOf:CGSize(width:150,height:2))
        line.fillColor = .white
        line.strokeColor = .clear
        horizon.addChild(line)
        mask.addChild(horizon)
        let level = SKShapeNode(rectOf:CGSize(width:59,height:3))
        level.fillColor = .orange
        level.strokeColor = .clear
        attitude.addChild(level)
        let slip = SKShapeNode(circleOfRadius:3)
        slip.position = CGPoint(x:bankAngle * 30,y:-39)
        slip.fillColor = .orange
        slip.strokeColor = .clear
        attitude.addChild(slip)
        let label = SKLabelNode(fontNamed:"Menlo-Bold")
        label.text = "ATTITUDE / BANK"
        label.fontSize = 10
        label.fontColor = .cyan
        label.position = CGPoint(x:0,y:61)
        attitude.addChild(label)
    }

    private func installTelemetry() {
        hud.fontSize = 12
        hud.fontColor = .white.withAlphaComponent(0.82)
        telemetryPanel.fillColor = .black.withAlphaComponent(CGFloat(prefs.object(forKey: "aces.telemetryOpacity") as? Double ?? 0.35))
        telemetryPanel.strokeColor = SKColor(white:0.81,alpha:0.17)
        telemetryPanel.lineWidth = 0.55
        telemetryPanel.zPosition = 90
        addChild(telemetryPanel)
        for (i, label) in telemetryLines.enumerated() {
            label.fontSize = i == 0 ? 9 : i == 6 ? 24 : i == 1 ? 12 : 10
            label.fontColor = i == 0 ? SKColor(red:1,green:0.72,blue:0.4,alpha:0.95)
                                      : .white.withAlphaComponent(0.94)
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .center
            label.zPosition = 92
            addChild(label)
        }
        radarPanel.fillColor = .black.withAlphaComponent(CGFloat(prefs.object(forKey: "aces.telemetryOpacity") as? Double ?? 0.35))
        radarPanel.strokeColor = .cyan.withAlphaComponent(0.4)
        radarPanel.lineWidth = 1
        radarPanel.zPosition = 91
        addChild(radarPanel)
        radarContacts.zPosition = 93
        addChild(radarContacts)
        attitudePanel.fillColor = .black.withAlphaComponent(0.38)
        attitudePanel.strokeColor = .cyan.withAlphaComponent(0.35)
        attitudePanel.zPosition = 90
        addChild(attitudePanel)
        attitude.zPosition = 94
        addChild(attitude)
        layoutTelemetry()
    }
    private func layoutTelemetry() {
        let right = size.width - 18
        let panelWidth: CGFloat = 238
        let panelHeight: CGFloat = 218
        let top = size.height - 65
        let panel = CGRect(x: right - panelWidth, y: top - panelHeight,
                           width: panelWidth, height: panelHeight)
        telemetryPanel.path = CGPath(roundedRect: panel, cornerWidth: 10, cornerHeight: 10, transform: nil)
        for (i, label) in telemetryLines.enumerated() {
            let offsets: [CGFloat] = [16, 42, 70, 96, 124, 152, 192]
            label.position = CGPoint(x: panel.maxX - 13, y: panel.maxY - offsets[i])
        }
        let attitudeRect = CGRect(x: right - panelWidth, y: 249, width: panelWidth, height: 154)
        attitudePanel.path = CGPath(roundedRect: attitudeRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
        attitude.position = CGPoint(x: attitudeRect.midX, y: attitudeRect.midY)
        let radarFrame = CGRect(x: right - panelWidth, y: 19, width: panelWidth, height: 222)
        radarPanel.path = CGPath(roundedRect: radarFrame, cornerWidth: 10, cornerHeight: 10, transform: nil)
        radarContacts.position = CGPoint(x: radarFrame.midX, y: radarFrame.midY - 5)
    }
    private func updateRadar() {
        if gameTime - lastRadarRender < 0.045 { return }
        lastRadarRender = gameTime
        updateAttitude()
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
        let sweepColor = SKColor.cyan.withAlphaComponent(CGFloat(prefs.object(forKey: "aces.radarBrightness") as? Double ?? 0.75))
        for i in 0..<13 {
            let angle = radarSweep - CGFloat(i) * 0.038
            let p = CGMutablePath()
            p.move(to: .zero)
            p.addLine(to: CGPoint(x: cos(angle) * radius, y: sin(angle) * radius))
            let ray = SKShapeNode(path: p)
            ray.strokeColor = sweepColor.withAlphaComponent(CGFloat(13-i)/13 * 0.52)
            ray.lineWidth = i == 0 ? 2.4 : 1.2
            radarContacts.addChild(ray)
        }
        for bandit in bandits {
            let dx = bandit.position.x - player.position.x
            let dy = bandit.position.y - player.position.y
            // Player-forward is always up on the radar.
            let lateral = sin(heading) * dx - cos(heading) * dy
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
        threat.position = CGPoint(x: size.width - 24, y: size.height - 277)
        hud.text = "VECTOR ACES  /  WWII AIR COMBAT"
        let rows = [
            "VECTOR ACES  //  TELEMETRY",
            fighter.rawValue.uppercased(),
            String(format: "AIRSPEED  %03d MPH", Int(airspeed)),
            String(format: "HEADING   %03d DEG", Int((90 - heading * 180 / .pi).truncatingRemainder(dividingBy: 360) + 360) % 360),
            "ALT  \(Int(altitude)) FT  AIRFRAME \(max(0, health))/\(fighter.health)",
            "AMMO \(prefs.bool(forKey: "aces.unlimitedAmmo") ? "∞" : String(ammo))  WAVE \(wave)",
            String(format:"%06d",score)
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
        prefs.set(false, forKey: "aces.hasSave")
        prefs.removeObject(forKey: "aces.savedRun")
        health = fighter.health
        deathStarted = false
        player.removeAllActions()
        if player.parent == nil { addChild(player) }
        player.setScale(0.9)
        player.alpha = 1
        ammo = fighter.ammunition
        altitude = 7600
        climbRate = 0
        bankAngle = 0
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
        sounds.startEngine(volume:effectsVolume * 0.18)
        updateLabels()
    }
}

private final class CombatAudio {
    enum Effect { case engine, gun, hit, explosion, warning, menu }
    static let shared = CombatAudio()
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let enginePlayer = AVAudioPlayerNode()
    var engineVolume: Float = 0.12 { didSet { enginePlayer.volume = engineVolume } }
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
    init() {
        engine.attach(player)
        engine.attach(enginePlayer)
        engine.connect(player,to:engine.mainMixerNode,format:format)
        engine.connect(enginePlayer,to:engine.mainMixerNode,format:format)
        try? engine.start()
    }
    func startEngine(volume:Double) {
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning else { return }
        enginePlayer.stop()
        let count = 44100
        guard let buffer = AVAudioPCMBuffer(pcmFormat:format,frameCapacity:AVAudioFrameCount(count)),
              let samples = buffer.floatChannelData?.pointee else { return }
        buffer.frameLength = AVAudioFrameCount(count)
        for i in 0..<count {
            let t = Double(i) / 44100
            let envelope = 0.7 + 0.3 * sin(2 * .pi * 5 * t)
            samples[i] = Float((sin(2 * .pi * 76 * t) + 0.23 * sin(2 * .pi * 152 * t)) * envelope * 0.5)
        }
        enginePlayer.scheduleBuffer(buffer,at:nil,options:.loops,completionHandler:nil)
        engineVolume = Float(volume)
        enginePlayer.play()
    }
    func stopEngine() { enginePlayer.stop() }
    func play(_ effect: Effect, volume: Double) {
        guard volume > 0 else { return }
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning else { return }
        let duration: Double
        switch effect {
        case .engine: duration = 0.32
        case .gun: duration = 0.11
        case .hit: duration = 0.22
        case .explosion: duration = 0.85
        case .warning: duration = 0.18
        case .menu: duration = 0.11
        }
        let count = Int(44100 * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat:format,frameCapacity:AVAudioFrameCount(count)),
              let samples = buffer.floatChannelData?.pointee else { return }
        buffer.frameLength = AVAudioFrameCount(count)
        for i in 0..<count {
            let t = Double(i) / 44100
            let noise = Double.random(in:-1...1)
            let envelope = max(0,1 - t/duration)
            let wave: Double
            switch effect {
            case .engine:
                wave = (sin(2 * .pi * 76 * t) + 0.28 * sin(2 * .pi * 153 * t)) * envelope
            case .gun:
                wave = (noise * 0.72 + sin(2 * .pi * 86 * t) * 0.28) * pow(envelope,2)
            case .hit:
                wave = (noise * 0.65 + sin(2 * .pi * 145 * t) * 0.35) * envelope
            case .explosion:
                wave = (noise * 0.75 + sin(2 * .pi * (56 - t * 24) * t) * 0.25) * envelope * envelope
            case .warning:
                wave = sin(2 * .pi * 820 * t) * envelope
            case .menu:
                wave = sin(2 * .pi * 620 * t) * envelope
            }
            samples[i] = Float(max(-0.85,min(0.85,wave * volume)))
        }
        player.scheduleBuffer(buffer,completionHandler:nil)
        if !player.isPlaying { player.play() }
    }
}

