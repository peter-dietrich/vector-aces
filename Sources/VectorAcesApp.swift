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
private enum AcesPlayMode: String {
    case interception
    case endless
}

private enum AcesCampaignMission: Int, CaseIterable, Identifiable {
    case stukas = 1
    case escort = 2
    case ace = 3
    case bridge = 4
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .stukas: return "STOP THE STUKAS"
        case .escort: return "BOMBER ESCORT"
        case .ace: return "HUNT THE ACE"
        case .bridge: return "DEFEND THE BRIDGE"
        }
    }
    var objective: String {
        switch self {
        case .stukas: return "DOWN 4 OF 6 STUKAS BEFORE AIRFIELD STRIKE"
        case .escort: return "KEEP 2 OF 3 ALLIED BOMBERS ALIVE"
        case .ace: return "DEFEAT THE ENEMY ACE BEFORE ESCAPE"
        case .bridge: return "STOP 5 OF 8 DIVE BOMBERS"
        }
    }
    var overview: String {
        switch self {
        case .stukas: return "Intercept incoming Stukas and protect the allied airfield."
        case .escort: return "Escort three allied B-17s against repeated fighter attacks."
        case .ace: return "Track and defeat an elite German pilot with two wingmen."
        case .bridge: return "Save the strategic bridge against four fast bomber waves."
        }
    }
    var duration: CGFloat {
        switch self {
        case .stukas: return 150
        case .escort: return 95
        case .ace: return 125
        case .bridge: return 155
        }
    }
}
private enum AcesPilotLog {
    private static let store = UserDefaults.standard
    static var unlocked: Int { max(1,store.integer(forKey:"aces.campaign.unlocked")) }
    static func stars(for mission: AcesCampaignMission) -> Int {
        store.integer(forKey:"aces.campaign.stars.\(mission.rawValue)")
    }
    static func best(for mission: AcesCampaignMission) -> Int {
        store.integer(forKey:"aces.campaign.best.\(mission.rawValue)")
    }
    static var rank: String {
        let wins = store.integer(forKey:"aces.campaign.wins")
        let kills = store.integer(forKey:"aces.campaign.kills")
        if wins >= 4 && kills >= 25 { return "SQUADRON LEADER" }
        if wins >= 3 && kills >= 16 { return "MAJOR" }
        if wins >= 2 && kills >= 10 { return "CAPTAIN" }
        if wins >= 1 { return "LIEUTENANT" }
        return "FLIGHT OFFICER"
    }
    static var medals: [(Int,String)] {
        [(1,"FIRST VICTORY"),(2,"GUARDIAN"),(4,"ACE HUNTER"),
         (8,"CAMPAIGN VETERAN"),(16,"PERFECT SORTIE")]
    }
    @discardableResult
    static func record(mission: AcesCampaignMission, victory: Bool,
                       score: Int, kills: Int, stars: Int,
                       damage: Int) -> [String] {
        store.set(store.integer(forKey:"aces.campaign.sorties")+1,forKey:"aces.campaign.sorties")
        store.set(store.integer(forKey:"aces.campaign.kills")+kills,forKey:"aces.campaign.kills")
        store.set(store.integer(forKey:"aces.campaign.score")+score,forKey:"aces.campaign.score")
        var newMedals: [String] = []
        if victory {
            store.set(store.integer(forKey:"aces.campaign.wins")+1,forKey:"aces.campaign.wins")
            let bestKey = "aces.campaign.best.\(mission.rawValue)"
            let starKey = "aces.campaign.stars.\(mission.rawValue)"
            store.set(max(score,store.integer(forKey:bestKey)),forKey:bestKey)
            store.set(max(stars,store.integer(forKey:starKey)),forKey:starKey)
            if mission.rawValue < 4 {
                store.set(max(unlocked,mission.rawValue+1),forKey:"aces.campaign.unlocked")
            }
        }
        let wins = store.integer(forKey:"aces.campaign.wins")
        let completed = AcesCampaignMission.allCases.filter { self.stars(for:$0)>0 }.count
        var requested = 0
        if wins > 0 { requested |= 1 }
        if victory && (mission == .stukas || mission == .escort || mission == .bridge) && stars == 3 { requested |= 2 }
        if victory && mission == .ace { requested |= 4 }
        if completed == 4 { requested |= 8 }
        if victory && damage == 0 { requested |= 16 }
        let previous = store.integer(forKey:"aces.campaign.medals")
        let awards = previous | requested
        store.set(awards,forKey:"aces.campaign.medals")
        newMedals = medals.filter { awards & $0.0 != 0 && previous & $0.0 == 0 }.map(\.1)
        return newMedals
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
private struct AcesPilotRecordSheet: View {
    @Environment(\.dismiss) private var dismiss
    private let store = UserDefaults.standard
    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:16) {
                HStack {
                    VStack(alignment:.leading,spacing:6) {
                        Text("VECTOR ACES / PERSONNEL FILE")
                            .font(.system(size:11,weight:.bold,design:.monospaced))
                            .foregroundStyle(AcesStyle.amber)
                        Text(AcesPilotLog.rank.uppercased())
                            .font(.system(size:28,weight:.black,design:.monospaced))
                    }
                    Spacer()
                    Image(systemName:"medal.star.fill")
                        .font(.system(size:38))
                        .foregroundStyle(AcesStyle.amber)
                }
                HStack(spacing:16) {
                    recordStatistic("SORTIES",store.integer(forKey:"aces.campaign.sorties"))
                    recordStatistic("VICTORIES",store.integer(forKey:"aces.campaign.wins"))
                    recordStatistic("HOSTILES",store.integer(forKey:"aces.campaign.kills"))
                    recordStatistic("TOTAL SCORE",store.integer(forKey:"aces.campaign.score"))
                }
                Divider()
                Text("CAMPAIGN SERVICE").font(.system(size:12,weight:.bold,design:.monospaced))
                    .foregroundStyle(AcesStyle.ice)
                ForEach(AcesCampaignMission.allCases) { mission in
                    HStack {
                        VStack(alignment:.leading,spacing:4) {
                            Text(String(format:"%02d / %@",mission.rawValue,mission.title))
                                .font(.system(size:13,weight:.bold,design:.monospaced))
                            Text(mission.overview).font(.system(size:10))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        Spacer()
                        VStack(alignment:.trailing) {
                            Text(String(repeating:"★",count:AcesPilotLog.stars(for:mission)))
                                .foregroundStyle(AcesStyle.amber)
                            Text("BEST \(AcesPilotLog.best(for:mission))")
                                .font(.system(size:10,design:.monospaced))
                        }
                    }
                    .padding(11)
                    .background(AcesStyle.panel,in:RoundedRectangle(cornerRadius:9))
                }
                Divider()
                Text("MEDALS & CITATIONS").font(.system(size:12,weight:.bold,design:.monospaced))
                    .foregroundStyle(AcesStyle.ice)
                let earned = store.integer(forKey:"aces.campaign.medals")
                ForEach(AcesPilotLog.medals,id:\.0) { medal in
                    HStack {
                        Image(systemName:earned & medal.0 != 0 ? "seal.fill" : "lock.fill")
                            .foregroundStyle(earned & medal.0 != 0 ? AcesStyle.amber : .gray)
                        Text(medal.1).font(.system(size:12,weight:.bold,design:.monospaced))
                        Spacer()
                        Text(earned & medal.0 != 0 ? "AWARDED" : "LOCKED")
                            .font(.system(size:10,design:.monospaced))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
                Button("RETURN TO HANGAR") { dismiss() }
                    .frame(maxWidth:.infinity)
                    .buttonStyle(.borderedProminent)
            }.padding(26)
        }
        .frame(width:720,height:670)
        .preferredColorScheme(.dark)
    }
    private func recordStatistic(_ name:String,_ number:Int) -> some View {
        VStack(alignment:.leading,spacing:4) {
            Text(name).font(.system(size:10,weight:.bold,design:.monospaced))
                .foregroundStyle(.white.opacity(0.5))
            Text(String(number)).font(.system(size:18,weight:.black,design:.monospaced))
                .foregroundStyle(AcesStyle.ice)
        }.frame(maxWidth:.infinity,alignment:.leading)
    }
}

@main struct VectorAcesApp: App {
    @AppStorage("aces.selectedFighter") private var selectedFighter = Fighter.mustang.rawValue
    @State private var started = false
    @State private var showingSettings = false
    @State private var showingPilotRecord = false
    @AppStorage("aces.hasSave") private var hasSave = false
    @AppStorage("aces.playMode") private var playMode = AcesPlayMode.interception.rawValue
    @AppStorage("aces.campaign.selected") private var selectedMission = 1
    private var fighter: Fighter { Fighter(rawValue:selectedFighter) ?? .mustang }
    var body: some Scene {
        WindowGroup("Vector Aces") {
            ZStack {
                Color(red:0.025,green:0.045,blue:0.077).ignoresSafeArea()
                if started {
                    AcesGameWindow(fighter:fighter, mode:AcesPlayMode(rawValue:playMode) ?? .interception,
                                   mission:AcesCampaignMission(rawValue:selectedMission) ?? .stukas,
                                   onHangar: { started = false })
                        .id(fighter)
                } else {
                    hangarCatalog
                }
            }
            .preferredColorScheme(.dark)
            .frame(minWidth:1000,minHeight:670)
            .sheet(isPresented:$showingSettings) { AcesSettings() }
            .sheet(isPresented:$showingPilotRecord) { AcesPilotRecordSheet() }
        }
        .defaultSize(width:1250,height:820)
    }
    private var hangarCatalog: some View {
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
                                Button("PILOT RECORD") { showingPilotRecord = true }
                                    .buttonStyle(.bordered).tint(AcesStyle.amber)
                                Button("CUSTOM SETTINGS") { showingSettings = true }
                                    .buttonStyle(.bordered).tint(AcesStyle.ice)
                            }
                            HStack(alignment:.top,spacing:18) {
                                hangarAircraftPicker
                                hangarAircraftDetails
                            }
                        }
                        .padding(25)
                        .frame(maxWidth:1280)
                        .frame(maxWidth:.infinity)
                    }
    }
    private var hangarAircraftPicker: some View {
                                VStack(alignment:.leading,spacing:13) {
                                    Text("MISSION TYPE")
                                        .font(.system(size:11,weight:.bold,design:.monospaced))
                                        .foregroundStyle(AcesStyle.ice)
                                    Picker("Mission type",selection:$playMode) {
                                        Text("Campaign").tag(AcesPlayMode.interception.rawValue)
                                        Text("Endless Dogfight").tag(AcesPlayMode.endless.rawValue)
                                    }
                                    .labelsHidden().pickerStyle(.segmented)
                                    Text(playMode == AcesPlayMode.interception.rawValue
                                         ? "CAMPAIGN • \((AcesCampaignMission(rawValue:selectedMission) ?? .stukas).title)"
                                         : "FREE FLIGHT • ENDLESS FORMATIONS")
                                        .font(.system(size:10,weight:.medium,design:.monospaced))
                                        .foregroundStyle(AcesStyle.amber)
                                        .fixedSize(horizontal:false,vertical:true)
                                    if playMode == AcesPlayMode.interception.rawValue {
                                        VStack(alignment:.leading,spacing:5) {
                                            Text("CAMPAIGN MISSIONS").font(.system(size:10,weight:.bold,design:.monospaced))
                                                .foregroundStyle(AcesStyle.ice)
                                            ForEach(AcesCampaignMission.allCases) { mission in
                                                Button {
                                                    selectedMission = mission.rawValue
                                                    CombatAudio.shared.play(.menu,volume:0.15)
                                                } label: {
                                                    HStack {
                                                        Text(String(format:"%02d",mission.rawValue))
                                                        Text(mission.title)
                                                        Spacer()
                                                        if AcesPilotLog.unlocked < mission.rawValue {
                                                            Image(systemName:"lock.fill")
                                                        } else if AcesPilotLog.stars(for:mission)>0 {
                                                            Text(String(repeating:"★",count:AcesPilotLog.stars(for:mission)))
                                                        }
                                                    }
                                                    .font(.system(size:10,weight:.bold,design:.monospaced))
                                                    .foregroundStyle(selectedMission == mission.rawValue ? AcesStyle.amber : .white.opacity(0.7))
                                                    .padding(.vertical,6)
                                                }
                                                .disabled(AcesPilotLog.unlocked < mission.rawValue)
                                                .buttonStyle(.plain)
                                            }
                                            Text((AcesCampaignMission(rawValue:selectedMission) ?? .stukas).overview)
                                                .font(.system(size:10,design:.monospaced))
                                                .foregroundStyle(.white.opacity(0.66))
                                                .fixedSize(horizontal:false,vertical:true)
                                            Text("PILOT: \(AcesPilotLog.rank)  •  SORTIES \(UserDefaults.standard.integer(forKey:"aces.campaign.sorties"))")
                                                .font(.system(size:10,weight:.bold,design:.monospaced))
                                                .foregroundStyle(AcesStyle.ice)
                                        }
                                    }
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
                                    if hasSave && playMode == AcesPlayMode.endless.rawValue {
                                        Button("RESUME SORTIE") {
                                            UserDefaults.standard.set(true, forKey: "aces.resumeRequested")
                                            started = true
                                        }
                                        .font(.system(size:13,weight:.bold,design:.monospaced))
                                        .frame(maxWidth:.infinity).padding(12)
                                        .background(AcesStyle.ice.opacity(0.22),in:RoundedRectangle(cornerRadius:8))
                                    }
                                    Button(playMode == AcesPlayMode.interception.rawValue ? "MISSION BRIEFING" : "START NEW SORTIE") {
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
    }
    private var hangarAircraftDetails: some View {
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
private struct AcesGameWindow: View {
    let fighter: Fighter
    let mode: AcesPlayMode
    let mission: AcesCampaignMission
    let onHangar: () -> Void
    @AppStorage("aces.difficulty") private var difficulty = 1
    @AppStorage("aces.soundEnabled") private var soundEnabled = true
    @State private var showingCustom = false
    @State private var scene: AirBattleScene

    init(fighter: Fighter, mode: AcesPlayMode, mission: AcesCampaignMission, onHangar: @escaping () -> Void) {
        self.fighter = fighter
        self.mode = mode
        self.mission = mission
        self.onHangar = onHangar
        _scene = State(initialValue: AirBattleScene(
            size: CGSize(width: 1200, height: 720), fighter: fighter, mode: mode, mission: mission))
    }
    var body: some View {
        VStack(spacing:0) {
            VStack(spacing:9) {
                HStack(spacing:9) {
                    VStack(alignment:.leading,spacing:2) {
                        HStack(alignment:.firstTextBaseline,spacing:9) {
                            Text("VECTOR ACES")
                                .font(.system(size:19,weight:.black,design:.monospaced))
                                .foregroundStyle(.white)
                            Text("v2026.11.13c")
                                .font(.system(size:10,weight:.medium,design:.monospaced))
                                .foregroundStyle(.gray)
                        }
                        Text("ARCADE  /  MACOS  /  WWII AIR COMBAT")
                            .font(.system(size:9,weight:.semibold,design:.monospaced))
                            .foregroundStyle(.cyan.opacity(0.7))
                    }
                    Spacer(minLength:4)
                    Button("Custom Game") { showingCustom = true }
                    Button("Save Game") { scene.saveNow() }
                        .disabled(mode == .interception)
                        .help(mode == .interception ? "Mission runs use a mission debrief; save slots are for Endless Dogfight." : "Save endless sortie")
                    Button("Resume") { scene.resumeSavedSortie() }
                        .disabled(mode == .interception)
                    Toggle("Sound",isOn:$soundEnabled)
                        .toggleStyle(.checkbox)
                        .onChange(of:soundEnabled) { newValue in
                            scene.setSoundEnabled(newValue)
                        }
                    Button("Hangar") { onHangar() }
                        .keyboardShortcut(.escape,modifiers:[])
                    Button(mode == .interception ? "Launch / Retry" : "New Game") {
                        if mode == .interception { scene.startOrRetryMission() }
                        else { scene.restart() }
                    }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                }
                HStack(spacing:12) {
                    Text("DIFFICULTY")
                        .font(.system(size:10,weight:.bold,design:.monospaced))
                        .foregroundStyle(.gray)
                    HStack(spacing:3) {
                        ForEach(0..<3,id:\.self) { level in
                            Button(["Easy","Medium","Hard"][level]) { difficulty = level }
                                .buttonStyle(.plain)
                                .font(.system(size:12,weight:.semibold))
                                .foregroundStyle(difficulty == level ? .black : .white)
                                .frame(width:67,height:27)
                                .background(difficulty == level ? Color.cyan : Color(white:0.28))
                                .clipShape(RoundedRectangle(cornerRadius:6))
                        }
                    }
                    Spacer()
                    Text(mode == .interception ? mission.title : fighter.rawValue.uppercased())
                        .font(.system(size:10,weight:.semibold,design:.monospaced))
                        .foregroundStyle(.cyan.opacity(0.73))
                    Button("Pause / Resume") { scene.togglePause() }
                        .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal,20)
            .padding(.vertical,9)
            .background(Color(white:0.09))

            GameSurface(scene:scene)
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .background(.black)

            HStack(spacing:10) {
                Text("← → Turn   ↑ Accelerate   ↓ Brake   Q Climb   E Descend   Space Fire   P Pause   Return Restart")
                Spacer(minLength:4)
                Text("Terrain: original continuous aerial landscape")
                    .foregroundStyle(.white.opacity(0.45))
            }
            .font(.system(size:10,weight:.bold,design:.monospaced))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal,12)
            .padding(.vertical,10)
            .background(Color(white:0.09))
        }
        .sheet(isPresented:$showingCustom) { AcesSettings() }
    }
}

private struct GameSurface: NSViewRepresentable {
    let scene: AirBattleScene
    func makeNSView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.presentScene(scene)
        DispatchQueue.main.async { view.window?.makeFirstResponder(scene) }
        return view
    }
    func updateNSView(_ nsView: SKView,context: Context) {}
}

private final class AirBattleScene: SKScene {
    private enum Tactic { case formation, intercept, flank, attack, evade, breakAway, regroup }
    private enum CombatRole { case interceptor, hunter, escort, bomber }
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
        var missionBomber: Bool = false
        var role: CombatRole = .hunter
        var flightID: Int = 0
        var wingIndex: Int = 0
        var evadeCooldown: CGFloat = 0
        var attackPasses: Int = 0
        var isAce: Bool = false
        var altitude: CGFloat = 7600
        var climbVelocity: CGFloat = 0
        var sizeAtSpawn: CGFloat = 1
    }
    private struct Round {
        let sprite: SKShapeNode
        var position: CGPoint
        let velocity: CGVector
        var lifetime: CGFloat
        let hostile: Bool
        var altitude: CGFloat = 7600
        var diveAttack: Bool = false
    }
    private let fighter: Fighter
    private let playMode: AcesPlayMode
    private let campaignMission: AcesCampaignMission
    private enum MissionStage { case briefing, active, success, failure }
    private var missionStage: MissionStage = .briefing
    private var missionTime: CGFloat = 0
    private let missionLimit: CGFloat = 150
    private var bomberLaunched = 0
    private var bomberDestroyed = 0
    private var bomberEscaped = 0
    private var airfieldHealth = 3
    private var missionEscortKills = 0
    private var missionHitsTaken = 0
    private var allies: [SKNode] = []
    private var allyHealth: [Int] = []
    private var lastAllyAttack: CGFloat = 0
    private var escortWaveIndex = 0
    private var eliteLaunched = false
    private var eliteDown = false
    private var campaignKillsAtStart = 0
    private let airfield = SKNode()
    private let missionText = SKLabelNode(fontNamed:"Menlo-Bold")
    private let missionBackdrop = SKShapeNode()
    private let missionCopy = (0..<6).map { _ in SKLabelNode(fontNamed:"Menlo") }
    private var player = SKNode()
    private let playerArtwork = SKNode()
    private var keys = Set<UInt16>()
    private var bandits: [Bandit] = []
    private var nextFlightID = 1
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
    private var flightEnergy: CGFloat = 68  // 0-100; altitude and airspeed affect available maneuvering energy.
    private var cloudCover = false
    private var lastTerrainAlert: CGFloat = -100
    private let tacticalCue = SKLabelNode(fontNamed:"Menlo-Bold")
    private let leadCue = SKNode()
    private var cloudAltitudes: [CGFloat] = []
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
    private let telemetryLines = (0..<19).map { _ in SKLabelNode(fontNamed: "Menlo-Bold") }
    private let telemetryAccent = SKShapeNode()
    private let telemetryRules = (0..<3).map { _ in SKShapeNode() }
    private let radarRange: CGFloat = 2400 // World-space arcade units; about 4.5x the old range.
    private let radarPanel = SKShapeNode()
    private let radarContacts = SKNode()
    private let radarLegend = SKLabelNode(fontNamed:"Menlo-Bold")
    private var gunCycle = 0
    private var ammo: Int
    private var altitude: CGFloat = 7600
    private var climbRate: CGFloat = 0
    private var bankAngle: CGFloat = 0
    private var deathStarted = false
    private var radarSweep: CGFloat = 0
    private var radarRadius: CGFloat = 85
    private var lastRadarRender: CGFloat = -1
    private let attitude = SKNode()
    private let attitudePanel = SKShapeNode()
    private let radarSweepNode = SKNode()
    private let sounds = CombatAudio.shared
    private let prefs = UserDefaults.standard

    init(size: CGSize, fighter: Fighter, mode: AcesPlayMode, mission: AcesCampaignMission) {
        self.fighter = fighter
        self.playMode = mode
        self.campaignMission = mission
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
        playerArtwork.addChild(drawAircraft(kind: -1, color: fighter.color))
        player.addChild(playerArtwork)
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
        tacticalCue.fontSize = 11
        tacticalCue.fontColor = .yellow
        tacticalCue.horizontalAlignmentMode = .left
        tacticalCue.zPosition = 103
        addChild(tacticalCue)
        configureLeadCue()
        installTelemetry()
        if playMode == .interception {
            configureAirfield()
            configureMissionOverlay()
            showMissionBriefing()
        }
        if playMode == .endless && prefs.bool(forKey: "aces.resumeRequested") { loadRun() }
        prefs.set(false, forKey: "aces.resumeRequested")
        updateLabels()
        if prefs.object(forKey:"aces.soundEnabled") as? Bool ?? true {
            sounds.startEngine(volume:effectsVolume * 0.18)
        }
        view.window?.makeFirstResponder(self)
    }
    override func willMove(from view: SKView) {
        if playMode == .endless && !gameOver && !deathStarted { saveRun() }
        sounds.stopEngine()
    }
    override func didChangeSize(_ oldSize: CGSize) {
        hud.position = CGPoint(x: 24, y: size.height - 22)
        status.position = CGPoint(x: size.width / 2, y: size.height / 2 + 80)
        threat.position = CGPoint(x: size.width - 24, y: size.height - 233)
        layoutTelemetry()
        layoutMissionOverlay()
        tacticalCue.position = CGPoint(x: 23, y: size.height - 65)
        if player.position == .zero { player.position = CGPoint(x: size.width / 2, y: size.height / 2) }
    }
    override func keyDown(with event: NSEvent) {
        keys.insert(event.keyCode)
        if playMode == .interception && event.keyCode == 36 && !event.isARepeat {
            if missionStage == .briefing { beginMission(); return }
            if missionStage == .success || missionStage == .failure { restart(); return }
        }
        if event.keyCode == 35 && !event.isARepeat && !gameOver &&
           (playMode == .endless || missionStage == .active) {
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

    private func drawAlliedB17() -> SKNode {
        // Original four-engine bomber silhouette for the escort scenario.
        // Intentionally distinct from the German single-engine Stuka shape.
        let node = SKNode()
        let fuselage = SKShapeNode(path: {
            let p = CGMutablePath()
            p.move(to:CGPoint(x:0,y:72))
            p.addLine(to:CGPoint(x:-9,y:48))
            p.addLine(to:CGPoint(x:-9,y:-61))
            p.addLine(to:CGPoint(x:-5,y:-76))
            p.addLine(to:CGPoint(x:5,y:-76))
            p.addLine(to:CGPoint(x:9,y:-61))
            p.addLine(to:CGPoint(x:9,y:48))
            p.closeSubpath()
            return p
        }())
        fuselage.fillColor = SKColor(red:0.60,green:0.68,blue:0.74,alpha:1)
        fuselage.strokeColor = .white.withAlphaComponent(0.65)
        fuselage.lineWidth = 1.4
        node.addChild(fuselage)
        let wing = SKShapeNode(path:{
            let p=CGMutablePath()
            p.move(to:CGPoint(x:-10,y:15))
            p.addLine(to:CGPoint(x:-100,y:-8))
            p.addLine(to:CGPoint(x:-100,y:-21))
            p.addLine(to:CGPoint(x:100,y:-21))
            p.addLine(to:CGPoint(x:100,y:-8))
            p.addLine(to:CGPoint(x:10,y:15))
            p.closeSubpath()
            return p
        }())
        wing.fillColor = SKColor(red:0.53,green:0.63,blue:0.70,alpha:1)
        wing.strokeColor = .white.withAlphaComponent(0.67)
        wing.lineWidth = 1.1
        node.addChild(wing)
        for x in [-68,-33,33,68] {
            let engine = SKShapeNode(ellipseOf:CGSize(width:15,height:27))
            engine.position = CGPoint(x:x,y:-8)
            engine.fillColor = SKColor(red:0.36,green:0.43,blue:0.47,alpha:1)
            engine.strokeColor = .black.withAlphaComponent(0.6)
            node.addChild(engine)
            let propeller=SKShapeNode(rectOf:CGSize(width:20,height:2))
            propeller.position = CGPoint(x:x,y:5)
            propeller.fillColor = .white.withAlphaComponent(0.65)
            propeller.strokeColor = .clear
            node.addChild(propeller)
        }
        let tail = SKShapeNode(rectOf:CGSize(width:80,height:12))
        tail.position = CGPoint(x:0,y:-59)
        tail.fillColor = SKColor(red:0.50,green:0.58,blue:0.64,alpha:1)
        tail.strokeColor = .white.withAlphaComponent(0.55)
        node.addChild(tail)
        for x in [-33,33] {
            let stabilizer=SKShapeNode(rectOf:CGSize(width:7,height:21))
            stabilizer.position = CGPoint(x:x,y:-63)
            stabilizer.fillColor = .white.withAlphaComponent(0.7)
            stabilizer.strokeColor = .clear
            node.addChild(stabilizer)
        }
        let roundel = SKShapeNode(circleOfRadius:9)
        roundel.fillColor = .white
        roundel.strokeColor = .blue
        roundel.lineWidth = 2
        roundel.position = CGPoint(x:-76,y:-12)
        node.addChild(roundel)
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
                cloudAltitudes.append(CGFloat([6200, 7600, 9400, 10800][bank]))

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
        if pausedGame || gameOver || deathStarted { return }
        if playMode == .interception && missionStage != .active { return }
        gameTime += dt
        if playMode == .endless && Int(gameTime) % 12 == 0 && Int(gameTime - dt) % 12 != 0 { saveRun() }
        if playMode == .endless { wave = max(1, prefs.integer(forKey: "aces.startWave")) + Int(gameTime / 36) }
        else { wave = 1; missionTime += dt }
        let left = keys.contains(123) || keys.contains(0)
        let right = keys.contains(124) || keys.contains(2)
        let thrust = keys.contains(126) || keys.contains(13)
        let brake = keys.contains(125) || keys.contains(1)
        // High energy makes maneuvering responsive; slow aircraft have a
        // softer turn rate rather than an instant or punishing stall.
        let turnBase: CGFloat
        switch fighter {
        case .mustang: turnBase = 2.75
        case .thunderbolt: turnBase = 2.23
        case .lightning: turnBase = 2.58
        case .warhawk: turnBase = 3.02
        }
        let energyTurn = 0.70 + 0.30 * flightEnergy / 100
        let turnRate = turnBase * energyTurn
        if left { heading += turnRate * dt }
        if right { heading -= turnRate * dt }
        let bankTarget: CGFloat = left ? -0.65 : right ? 0.65 : 0
        bankAngle += (bankTarget - bankAngle) * min(1, dt * 3.6)
        // Q/E remain the only vertical controls. Arcade rates (ft/sec) and
        // energy tradeoffs: sustained climb costs speed, dives restore it.
        let verticalProfile: (climb: CGFloat, dive: CGFloat)
        switch fighter {
        case .mustang: verticalProfile = (62,86)
        case .thunderbolt: verticalProfile = (47,103)
        case .lightning: verticalProfile = (57,90)
        case .warhawk: verticalProfile = (54,81)
        }
        let climbPerformance = verticalProfile.climb
        let divePerformance = verticalProfile.dive
        let verticalTarget: CGFloat = keys.contains(12) ? climbPerformance :
            keys.contains(14) ? -divePerformance : 0
        climbRate += (verticalTarget - climbRate) * min(1, dt * 2.2)
        altitude = max(0, min(26000, altitude + climbRate * dt))
        if thrust { airspeed += 160 * dt }
        if brake { airspeed -= 190 * dt }
        if climbRate > 5 { airspeed -= climbRate * 0.56 * dt }
        if climbRate < -5 { airspeed += abs(climbRate) * 0.75 * dt }
        if left || right { airspeed -= 15 * dt }
        airspeed += (fighter.speed * 0.70 - airspeed) * dt * 0.18
        let diveSpeedReserve: CGFloat = fighter == .thunderbolt ? 155 : 135
        airspeed = max(105, min(fighter.speed + diveSpeedReserve, airspeed))
        let speedReserve = max(0, min(100, (airspeed - 105) /
            max(1, fighter.speed + diveSpeedReserve - 105) * 100))
        let altitudeReserve = max(0, min(100, (altitude - 300) / 15000 * 100))
        let targetEnergy = 0.78 * speedReserve + 0.22 * altitudeReserve
        flightEnergy += (targetEnergy - flightEnergy) * min(1, dt * 1.1)
        if altitude <= 165 && climbRate < -8 {
            health = 0
            beginPlayerCrash()
            return
        }
        if altitude < 670 && gameTime - lastTerrainAlert > 8 {
            flash("PULL UP  /  TERRAIN AHEAD")
            lastTerrainAlert = gameTime
        }
        sounds.engineVolume = (prefs.object(forKey:"aces.soundEnabled") as? Bool ?? true)
            ? Float(effectsVolume * (0.08 + Double(airspeed) / 1900)) : 0
        player.zRotation = heading - .pi / 2
        // The aircraft pivots into its bank and presents a foreshortened wing
        // profile rather than staying a rigid flat silhouette during turns.
        // Forward heading and muzzle geometry remain independent of banking.
        playerArtwork.xScale = 1 - abs(bankAngle) * 0.27
        playerArtwork.yScale = 1 + abs(bankAngle) * 0.055
        playerArtwork.position.x = bankAngle * 8
        playerArtwork.zRotation = -bankAngle * 0.12
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
        for node in allies {
            node.position.x += scroll.dx
            node.position.y += scroll.dy
        }
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
        cloudCover = coveredByCloud(player.position, altitude: altitude)
        updateLeadCue()
        if keys.contains(49) && gameTime - lastFire > 0.115 {
            firePlayerWeapons()
            lastFire = gameTime
        }
        radarSweep += dt * 1.85
        if playMode == .endless {
            if gameTime - lastFormation > max(8, 13.5 - CGFloat(wave) * 0.35) / CGFloat(max(0.5, prefs.double(forKey: "aces.enemyDensity") == 0 ? 1 : prefs.double(forKey: "aces.enemyDensity"))) && bandits.count < 15 {
                spawnFormation()
                lastFormation = gameTime
            }
        } else {
            updateMissionSpawns()
        }
        updateBandits(dt: dt, scrolling: scroll)
        updateRounds(dt: dt, scrolling: scroll)
        if playMode == .interception { evaluateMission() }
        // Give a reliable threat direction for attacks approaching outside the view.
        updateLabels()
    }

    // MARK: Mission 01 - Stop the Stukas
    // Mission objectives are deliberately separate from endless-wave scoring.
    // Position is camera-relative just like the rest of the battlefield.
    private func configureAirfield() {
        airfield.removeFromParent()
        airfield.removeAllChildren()
        airfield.name = "airfield"
        airfield.position = CGPoint(x:size.width * 0.76,y:size.height * 0.39)
        airfield.zPosition = -3
        if campaignMission == .bridge {
            let river = SKShapeNode(rectOf:CGSize(width:110,height:290),cornerRadius:15)
            river.fillColor = SKColor(red:0.16,green:0.37,blue:0.51,alpha:0.92)
            river.strokeColor = .cyan.withAlphaComponent(0.24)
            airfield.addChild(river)
            let road = SKShapeNode(rectOf:CGSize(width:270,height:36),cornerRadius:3)
            road.fillColor = SKColor(red:0.41,green:0.39,blue:0.34,alpha:1)
            road.strokeColor = .white.withAlphaComponent(0.45)
            airfield.addChild(road)
            for x in [-65,0,65] {
                let pylon = SKShapeNode(rectOf:CGSize(width:8,height:58))
                pylon.position.x = CGFloat(x)
                pylon.fillColor = .gray
                pylon.strokeColor = .white.withAlphaComponent(0.3)
                airfield.addChild(pylon)
            }
            let marker = SKLabelNode(fontNamed:"Menlo-Bold")
            marker.text = "STRATEGIC BRIDGE"
            marker.fontSize = 11
            marker.fontColor = .yellow
            marker.position = CGPoint(x:0,y:96)
            airfield.addChild(marker)
            environment.addChild(airfield)
            return
        }
        let outer = SKShapeNode(rectOf:CGSize(width:238,height:151),cornerRadius:9)
        outer.fillColor = SKColor(red:0.26,green:0.35,blue:0.23,alpha:0.8)
        outer.strokeColor = SKColor(red:0.8,green:0.8,blue:0.55,alpha:0.4)
        airfield.addChild(outer)
        let strip = SKShapeNode(rectOf:CGSize(width:183,height:34),cornerRadius:3)
        strip.fillColor = SKColor(red:0.37,green:0.37,blue:0.34,alpha:1)
        strip.strokeColor = SKColor(white:0.86,alpha:0.67)
        strip.zRotation = 0.12
        airfield.addChild(strip)
        for i in -5...5 {
            let mark = SKShapeNode(rectOf:CGSize(width:10,height:2))
            mark.fillColor = .white
            mark.strokeColor = .clear
            mark.position = CGPoint(x:CGFloat(i)*15,y:CGFloat(i)*1.8)
            airfield.addChild(mark)
        }
        for i in 0..<4 {
            let hangar = SKShapeNode(rectOf:CGSize(width:31,height:22),cornerRadius:3)
            hangar.fillColor = SKColor(red:0.51,green:0.49,blue:0.37,alpha:1)
            hangar.strokeColor = .black.withAlphaComponent(0.4)
            hangar.position = CGPoint(x:CGFloat(i-2)*49+24,y:-53)
            airfield.addChild(hangar)
        }
        let marker = SKLabelNode(fontNamed:"Menlo-Bold")
        marker.text = "ALLIED AIRFIELD"
        marker.fontSize = 10
        marker.fontColor = SKColor(red:0.95,green:0.90,blue:0.47,alpha:1)
        marker.position = CGPoint(x:0,y:83)
        airfield.addChild(marker)
        environment.addChild(airfield)
    }

    private func configureMissionOverlay() {
        missionBackdrop.zPosition = 175
        missionBackdrop.fillColor = SKColor(calibratedRed:0.018,green:0.038,blue:0.065,alpha:0.91)
        missionBackdrop.strokeColor = .cyan.withAlphaComponent(0.46)
        missionBackdrop.lineWidth = 1.3
        addChild(missionBackdrop)
        for (index,label) in missionCopy.enumerated() {
            label.fontSize = index == 0 ? 21 : index == 5 ? 15 : 13
            label.fontName = index == 0 || index == 5 ? "Menlo-Bold" : "Menlo"
            label.fontColor = index == 0 ? .cyan :
                index == 5 ? .orange : .white
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.zPosition = 177
            addChild(label)
        }
        missionText.fontSize = 12
        missionText.fontColor = .orange
        missionText.horizontalAlignmentMode = .left
        missionText.zPosition = 102
        addChild(missionText)
        layoutMissionOverlay()
    }

    private func layoutMissionOverlay() {
        guard playMode == .interception else { return }
        let boxWidth = min(size.width - 90,720)
        let boxHeight: CGFloat = 300
        let rect = CGRect(x:(size.width-boxWidth)/2,
                          y:(size.height-boxHeight)/2,
                          width:boxWidth,height:boxHeight)
        missionBackdrop.path = CGPath(roundedRect:rect,cornerWidth:13,cornerHeight:13,transform:nil)
        for (i,label) in missionCopy.enumerated() {
            label.position = CGPoint(x:rect.midX,y:rect.maxY - CGFloat(i)*46 - 41)
        }
        missionText.position = CGPoint(x:22,y:size.height-22)
    }

    private func showMissionBriefing() {
        missionStage = .briefing
        missionBackdrop.isHidden = false
        let lines: [String]
        switch campaignMission {
        case .stukas:
            lines = ["MISSION 01  //  STOP THE STUKAS",
                "SIX JU 87 DIVE BOMBERS APPROACH THE ALLIED AIRFIELD",
                "FW 190 ESCORTS WILL TRY TO DRAW YOU AWAY",
                "DESTROY AT LEAST FOUR BOMBERS BEFORE THEY STRIKE",
                "AIRFIELD INTEGRITY 3  •  150 SECOND LIMIT",
                "PRESS RETURN TO LAUNCH"]
        case .escort:
            lines = ["MISSION 02  //  BOMBER ESCORT",
                "THREE ALLIED B-17S CROSS ENEMY AIRSPACE",
                "PROTECT THE FORMATION FROM GERMAN INTERCEPTORS",
                "KEEP AT LEAST TWO BOMBERS FLYING",
                "95 SECOND ESCORT WINDOW",
                "PRESS RETURN TO LAUNCH"]
        case .ace:
            lines = ["MISSION 03  //  HUNT THE ACE",
                "A DEADLY FW 190 PILOT IS OPERATING NEARBY",
                "THE ACE IS PROTECTED BY TWO WINGMEN",
                "FIND AND DESTROY THE ACE BEFORE HE ESCAPES",
                "125 SECOND INTERCEPTION WINDOW",
                "PRESS RETURN TO LAUNCH"]
        case .bridge:
            lines = ["MISSION 04  //  DEFEND THE BRIDGE",
                "EIGHT DIVE BOMBERS APPROACH A STRATEGIC BRIDGE",
                "FOUR WAVES ARRIVE WITH ENEMY ESCORTS",
                "DESTROY AT LEAST FIVE OF THE EIGHT BOMBERS",
                "BRIDGE INTEGRITY 3  •  155 SECOND LIMIT",
                "PRESS RETURN TO LAUNCH"]
        }
        for (label,line) in zip(missionCopy,lines) { label.text=line;label.isHidden=false }
        missionText.text = ""
        status.text = ""
    }

    func startOrRetryMission() {
        guard playMode == .interception else { return }
        if missionStage != .briefing { restart() }
        beginMission()
    }

    private func beginMission() {
        guard playMode == .interception && missionStage == .briefing else { return }
        missionStage = .active
        missionBackdrop.isHidden = true
        missionCopy.forEach { $0.isHidden = true }
        missionTime = 0
        gameTime = 0
        bomberLaunched = 0
        bomberDestroyed = 0
        bomberEscaped = 0
        airfieldHealth = 3
        missionEscortKills = 0
        missionHitsTaken = 0
        campaignKillsAtStart = kills
        eliteLaunched = false
        eliteDown = false
        lastAllyAttack = 0
        escortWaveIndex = 0
        clearMissionAllies()
        if campaignMission == .escort { spawnAlliedBombers() }
        keys.removeAll()
        status.text = ""
        view?.window?.makeFirstResponder(self)
    }

    private func spawnMissionBomberPair() {
        let launchIndex = bomberLaunched / 2
        let flightID = nextFlightID
        nextFlightID += 1
        let base = CGPoint(x:airfield.position.x + 1650,
                           y:airfield.position.y + CGFloat(launchIndex-1)*140)
        for i in 0..<2 {
            let point = CGPoint(x:base.x+CGFloat(i)*80,y:base.y+CGFloat(i)*135)
            let sprite = SKNode()
            sprite.position = point
            sprite.zPosition = 15
            sprite.addChild(drawAircraft(kind:2,color:SKColor(
                red:0.43,green:0.45,blue:0.33,alpha:1)))
            sprite.setScale(1.04)
            addChild(sprite)
            let toward = atan2(airfield.position.y-point.y,airfield.position.x-point.x)
            sprite.zRotation = toward - .pi/2
            var bomber = Bandit(sprite:sprite,position:point,heading:toward,
                                speed:118,health:3,kind:2,
                                formationTime:0,fireCooldown:100,
                                targetOffset:0,tactic:.formation,tacticTime:0,
                                maneuverSign:1,entryHeading:toward,
                                previousDistance:0,missionBomber:true)
            bomber.role = .bomber
            bomber.flightID = flightID
            bomber.wingIndex = i
            bomber.altitude = 7450 - CGFloat(launchIndex) * 310
            bomber.sizeAtSpawn = sprite.xScale
            bandits.append(bomber)
            bomberLaunched += 1
        }
        // Escorts enter close to the inbound bombers but maneuver
        // independently and pursue the player, not the airfield.
        for i in 0..<(launchIndex == 0 ? 2 : 1) {
            let point = CGPoint(x:base.x-180+CGFloat(i)*85,y:base.y+220)
            let sprite = SKNode()
            sprite.position = point
            sprite.zPosition = 15
            sprite.addChild(drawAircraft(kind:0,color:SKColor(
                red:0.45,green:0.47,blue:0.43,alpha:1)))
            sprite.setScale(0.86)
            addChild(sprite)
            let toward = atan2(player.position.y-point.y,player.position.x-point.x)
            sprite.zRotation = toward - .pi/2
            var escort = Bandit(sprite:sprite,position:point,heading:toward,
                                speed:240,health:2,kind:0,
                                formationTime:2,fireCooldown:2.2,
                                targetOffset:CGFloat.random(in:-0.65...0.65),
                                tactic:.formation,tacticTime:0,
                                maneuverSign:i == 0 ? -1 : 1,
                                entryHeading:toward,previousDistance:800)
            escort.role = .escort
            escort.flightID = flightID
            escort.wingIndex = i
            escort.altitude = 7600 - CGFloat(launchIndex) * 220
            escort.sizeAtSpawn = sprite.xScale
            bandits.append(escort)
        }
        flash("MISSION ALERT  //  INBOUND STUKAS  \(bomberLaunched)/6")
    }

    private func updateMissionSpawns() {
        guard missionStage == .active else { return }
        switch campaignMission {
        case .stukas, .bridge:
            let schedule: [CGFloat] = campaignMission == .stukas ? [2,30,58] : [2,24,46,68]
            let next = bomberLaunched / 2
            if next < schedule.count && missionTime >= schedule[next] {
                spawnMissionBomberPair()
            }
            let objective = campaignMission == .bridge ? "BRIDGE" : "AIRFIELD"
            let total = campaignMission == .bridge ? 8 : 6
            missionText.text = String(format:"%@ %d/3  //  DOWN %d/%d  //  TIME %03d",
                objective,airfieldHealth,bomberDestroyed,total,
                Int(max(0,campaignMission.duration-missionTime)))
        case .escort:
            let schedule: [CGFloat] = [2,26,50,74]
            if escortWaveIndex < schedule.count && missionTime >= schedule[escortWaveIndex] {
                spawnCampaignFighters(count:2,elite:false)
                escortWaveIndex += 1
            }
            updateAlliedEscort(dt:1.0/60.0)
            missionText.text = "B-17 SURVIVORS \(allyHealth.filter{$0>0}.count)/3  //  TIME \(Int(max(0,campaignMission.duration-missionTime)))"
        case .ace:
            if !eliteLaunched && missionTime >= 2 {
                spawnCampaignFighters(count:3,elite:true)
                eliteLaunched = true
            }
            missionText.text = "ENEMY ACE \(eliteDown ? "DOWN" : "ACTIVE")  //  TIME \(Int(max(0,campaignMission.duration-missionTime)))"
        }
    }

    private func clearMissionAllies() {
        for ally in allies { ally.removeFromParent() }
        allies.removeAll()
        allyHealth.removeAll()
    }

    private func spawnAlliedBombers() {
        for i in 0..<3 {
            let node = SKNode()
            node.position = CGPoint(x:size.width*0.34 + CGFloat(i)*64,
                                    y:size.height*0.35 + CGFloat(i)*100)
            node.zPosition = 16
            let aircraft = drawAlliedB17()
            node.addChild(aircraft)
            node.setScale(0.64)
            node.zRotation = -.pi/2
            addChild(node)
            allies.append(node)
            allyHealth.append(3)
        }
    }

    private func updateAlliedEscort(dt: CGFloat) {
        for i in allies.indices where allyHealth[i] > 0 {
            let node = allies[i]
            node.position.x += 62 * dt
            node.position.y += sin(missionTime*0.7+CGFloat(i))*0.3
        }
        if missionTime-lastAllyAttack < 2.8 { return }
        lastAllyAttack = missionTime
        // An enemy close enough to the formation can make an attack pass.
        for i in allies.indices where allyHealth[i] > 0 {
            let nearest = bandits.filter { !$0.missionBomber }.map {
                hypot($0.position.x-allies[i].position.x,
                      $0.position.y-allies[i].position.y)
            }.min() ?? .greatestFiniteMagnitude
            if nearest < 270 {
                allyHealth[i] -= 1
                burst(at:allies[i].position,count:10)
                if allyHealth[i] <= 0 {
                    crashPlane(allies[i],position:allies[i].position,duration:1.2)
                    flash("ALLIED BOMBER LOST")
                } else {
                    flash("B-17 UNDER ATTACK")
                }
                break
            }
        }
    }

    private func spawnCampaignFighters(count: Int, elite: Bool) {
        let flight = nextFlightID
        nextFlightID += 1
        let center = CGPoint(x:player.position.x + CGFloat.random(in:560...800),
                             y:player.position.y + CGFloat.random(in:-320...320))
        for i in 0..<count {
            let point = CGPoint(x:center.x+CGFloat(i)*62,
                                y:center.y+CGFloat(i-1)*85)
            let kind = elite && i == 0 ? 0 : i % 2
            let sprite = SKNode()
            sprite.position = point
            sprite.zPosition = 15
            sprite.addChild(drawAircraft(kind:kind,color:elite && i == 0 ?
                SKColor(red:0.72,green:0.24,blue:0.20,alpha:1) :
                SKColor(red:0.44,green:0.47,blue:0.43,alpha:1)))
            sprite.setScale(elite && i == 0 ? 1.12 : 0.88)
            addChild(sprite)
            let direction = atan2(player.position.y-point.y,player.position.x-point.x)
            sprite.zRotation = direction - .pi/2
            var enemy = Bandit(sprite:sprite,position:point,heading:direction,
                               speed:elite && i == 0 ? 282 : 244,
                               health:elite && i == 0 ? 9 : 2,
                               kind:kind,formationTime:1.4,
                               fireCooldown:elite && i == 0 ? 1.0 : 2.2,
                               targetOffset:CGFloat.random(in:-0.7...0.7),
                               tactic:.formation,tacticTime:0,
                               maneuverSign:i%2 == 0 ? 1 : -1,
                               entryHeading:direction,previousDistance:700)
            enemy.role = kind == 1 ? .interceptor : .hunter
            enemy.flightID = flight
            enemy.wingIndex = i
            enemy.altitude = altitude + CGFloat.random(in:-300...300)
            enemy.sizeAtSpawn = sprite.xScale
            enemy.isAce = elite && i == 0
            bandits.append(enemy)
        }
        flash(elite ? "RED ACE DETECTED — PRIORITY TARGET" : "HOSTILE FIGHTERS APPROACHING")
    }

    private func advanceMissionBomber(_ b: inout Bandit,
                                      dt: CGFloat, scrolling: CGVector) {
        let dx = airfield.position.x - b.position.x
        let dy = airfield.position.y - b.position.y
        let toward = atan2(dy,dx)
        let difference = atan2(sin(toward-b.heading),cos(toward-b.heading))
        b.heading += max(-0.48*dt,min(0.48*dt,difference))
        b.position.x += cos(b.heading)*b.speed*dt + scrolling.dx
        b.position.y += sin(b.heading)*b.speed*dt + scrolling.dy
        b.altitude = max(1250, b.altitude - 47 * dt)
        b.sprite.position = b.position
        b.sprite.zRotation = b.heading - .pi/2
        let visual = 1 + max(-0.12,min(0.10,(b.altitude-altitude)/6000))
        b.sprite.setScale(b.sizeAtSpawn * visual)
    }

    private func evaluateMission() {
        guard missionStage == .active else { return }
        switch campaignMission {
        case .stukas, .bridge:
            let total = campaignMission == .stukas ? 6 : 8
            let required = campaignMission == .stukas ? 4 : 5
            if airfieldHealth <= 0 {
                finishMission(success:false,reason:"OBJECTIVE DESTROYED")
            } else if bomberLaunched >= total && bomberDestroyed+bomberEscaped >= total {
                let won = bomberDestroyed >= required
                finishMission(success:won,reason:won ? "OBJECTIVE SECURED" : "BOMBERS BROKE THROUGH")
            } else if missionTime >= campaignMission.duration {
                finishMission(success:false,reason:"INTERCEPTION WINDOW EXPIRED")
            }
        case .escort:
            if allyHealth.filter({$0>0}).count < 2 {
                finishMission(success:false,reason:"ALLIED BOMBERS LOST")
            } else if missionTime >= campaignMission.duration {
                finishMission(success:true,reason:"FORMATION REACHED SAFETY")
            }
        case .ace:
            if eliteDown {
                finishMission(success:true,reason:"ENEMY ACE SHOT DOWN")
            } else if missionTime >= campaignMission.duration {
                finishMission(success:false,reason:"ACE ESCAPED")
            }
        }
    }

    private func finishMission(success: Bool, reason: String) {
        guard playMode == .interception && missionStage == .active else { return }
        missionStage = success ? .success : .failure
        gameOver = true
        pausedGame = false
        keys.removeAll()
        sounds.stopEngine()
        if success { score += 500 + Int(max(0,campaignMission.duration-missionTime))*10 + airfieldHealth*250 }
        let stars = !success ? 0 : (missionHitsTaken == 0 ? 3 : missionHitsTaken <= 2 ? 2 : 1)
        let awards = AcesPilotLog.record(mission:campaignMission,victory:success,
                    score:score,kills:max(0,kills-campaignKillsAtStart),
                    stars:stars,damage:missionHitsTaken)
        let lines = [
            success ? "MISSION COMPLETE  //  VICTORY" : "MISSION FAILED  //  RETREAT",
            reason,
            "MISSION \(campaignMission.rawValue)  /  \(campaignMission.title)",
            "HOSTILES DOWN \(max(0,kills-campaignKillsAtStart))  /  DAMAGE TAKEN \(missionHitsTaken)",
            "TOTAL SCORE  \(score)  /  RANK  \(AcesPilotLog.rank)",
            "\(stars) STAR MISSION  •  \(awards.first ?? "RETURN TO RETRY")"
        ]
        missionBackdrop.isHidden = false
        for (label,line) in zip(missionCopy,lines) {
            label.text = line
            label.isHidden = false
        }
        missionText.text = ""
        status.text = ""
        if success && campaignMission == .stukas {
            let best = prefs.integer(forKey:"aces.mission01Best")
            if score > best { prefs.set(score,forKey:"aces.mission01Best") }
        }
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
        let flightID = nextFlightID
        nextFlightID += 1
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
            var pilot = Bandit(sprite: sprite, position: location, heading: toward,
                               speed: kind == 2 ? 150 : CGFloat.random(in: 180...240),
                               health: kind == 2 ? 5 : (wave >= 3 ? 3 : 2), kind: kind,
                               formationTime: CGFloat.random(in: 1.7...3.7) + row * 0.25,
                               fireCooldown: index * 0.18 + 1.3,
                               targetOffset: CGFloat.random(in: -1.15...1.15),
                               tactic: .formation, tacticTime: 0, maneuverSign: sign,
                               entryHeading: toward, previousDistance: 1000)
            pilot.role = kind == 2 ? .bomber : (kind == 1 ? .interceptor : .hunter)
            pilot.flightID = flightID
            pilot.wingIndex = i
            pilot.altitude = max(1400, altitude + CGFloat.random(in:-1100...950))
            pilot.sizeAtSpawn = sprite.xScale
            bandits.append(pilot)
        }
        flash("INCOMING FORMATION — \(count) HOSTILES")
    }
    private func updateBandits(dt: CGFloat, scrolling: CGVector) {
        // Phase 2 AI: pilots maintain limited attack slots. Fighters lead,
        // flank, make a firing pass and disengage rather than forming a swarm.
        // Escorts initially screen their bomber group before breaking to engage.
        let difficulty = max(0,min(2,prefs.integer(forKey:"aces.difficulty")))
        let simultaneousAttacks = difficulty == 0 ? 1 : (difficulty == 1 ? 2 : 3)
        let attacking = bandits.filter { !$0.missionBomber && $0.tactic == .attack }.count
        var availableAttackSlots = max(0,simultaneousAttacks - attacking)

        for i in bandits.indices {
            var b = bandits[i]
            if b.missionBomber {
                advanceMissionBomber(&b,dt:dt,scrolling:scrolling)
                bandits[i] = b
                continue
            }
            b.formationTime -= dt
            b.tacticTime -= dt
            b.evadeCooldown = max(0,b.evadeCooldown-dt)
            b.fireCooldown -= dt
            let escortTarget: CGPoint?
            if playMode == .interception && campaignMission == .escort {
                let closest = allies.indices.filter { allyHealth[$0] > 0 }.min(by: {
                    hypot(allies[$0].position.x-b.position.x,allies[$0].position.y-b.position.y) <
                    hypot(allies[$1].position.x-b.position.x,allies[$1].position.y-b.position.y)
                })
                escortTarget = closest.map { allies[$0].position }
            } else {
                escortTarget = nil
            }
            let target = escortTarget ?? player.position
            let dx = target.x-b.position.x
            let dy = target.y-b.position.y
            let distance = hypot(dx,dy)
            let bearing = atan2(dy,dx)
            let forwardX = cos(heading)
            let forwardY = sin(heading)
            let playerBehind = cos(b.heading)*(player.position.x-b.position.x) +
                               sin(b.heading)*(player.position.y-b.position.y) < -65
            let playerAimingAtBandit = cos(heading) * (b.position.x-player.position.x) +
                sin(heading) * (b.position.y-player.position.y) > 0
            let playerToEnemy = atan2(b.position.y-player.position.y,
                                      b.position.x-player.position.x)
            let playerAspect = abs(atan2(sin(playerToEnemy-heading),
                                        cos(playerToEnemy-heading)))
            let underPursuit = playerBehind && playerAimingAtBandit &&
                               playerAspect < 0.7 && distance < 390

            let nearbyBomber = bandits.filter { $0.missionBomber &&
                $0.flightID == b.flightID }.min {
                hypot($0.position.x-b.position.x,$0.position.y-b.position.y) <
                hypot($1.position.x-b.position.x,$1.position.y-b.position.y)
            }
            let escorting = b.role == .escort && nearbyBomber != nil
            if b.tactic == .formation && b.formationTime <= 0 {
                b.tactic = escorting ? .flank : .intercept
                b.tacticTime = CGFloat.random(in:1.2...2.4)
            }
            if underPursuit && b.tactic != .evade && b.evadeCooldown <= 0 &&
               b.tactic != .formation && b.kind != 2 {
                b.tactic = .evade
                b.tacticTime = CGFloat.random(in:0.8...1.45)
                b.evadeCooldown = CGFloat.random(in:4.5...7)
                b.maneuverSign = Bool.random() ? 1 : -1
            }
            if b.tactic == .evade && b.tacticTime <= 0 {
                b.tactic = .breakAway
                b.tacticTime = CGFloat.random(in:1.0...1.8)
            }
            if b.tactic == .intercept && (distance < 500 || b.tacticTime <= 0) {
                b.tactic = .flank
                b.tacticTime = CGFloat.random(in:1.0...2.3)
            }
            if b.tactic == .flank && (b.tacticTime <= 0 || distance < 260) {
                if availableAttackSlots > 0 && distance < 680 {
                    b.tactic = .attack
                    b.tacticTime = CGFloat.random(in:1.5...2.7)
                    b.attackPasses += 1
                    availableAttackSlots -= 1
                } else {
                    b.tacticTime = CGFloat.random(in:0.8...1.4)
                }
            }
            if b.tactic == .attack && (distance < 115 || b.tacticTime <= 0) {
                b.tactic = .breakAway
                b.tacticTime = CGFloat.random(in:1.15...2.1)
                b.maneuverSign = Bool.random() ? 1 : -1
            }
            if b.tactic == .breakAway && b.tacticTime <= 0 {
                b.tactic = .regroup
                b.tacticTime = CGFloat.random(in:1.2...2.2)
            }
            if b.tactic == .regroup && (b.tacticTime <= 0 || distance > 690) {
                b.tactic = escorting ? .flank : .intercept
                b.tacticTime = CGFloat.random(in:1.3...2.4)
            }

            let leadTime = min(1.25,distance / 510)
            let predictedX = dx + forwardX * airspeed * leadTime
            let predictedY = dy + forwardY * airspeed * leadTime
            let leadBearing = atan2(predictedY,predictedX)
            let desired: CGFloat
            switch b.tactic {
            case .formation:
                desired = b.entryHeading
            case .intercept:
                desired = leadBearing
            case .flank:
                if escorting, let bomber = nearbyBomber, distance > 290 {
                    let flankX = bomber.position.x + (b.wingIndex == 0 ? -160 : 160)
                    let flankY = bomber.position.y + 135
                    desired = atan2(flankY-b.position.y,flankX-b.position.x)
                } else {
                    // Wingmen approach opposing flanks, forcing the player to
                    // make an evasive choice while only a few pilots fire.
                    let flankSign: CGFloat = b.wingIndex.isMultiple(of:2) ? 1 : -1
                    desired = atan2(predictedY + flankSign * 135 * cos(heading),
                                    predictedX - flankSign * 135 * sin(heading))
                }
            case .attack:
                // Bf 109s make agile turning attacks, Fw 190s make faster passes.
                desired = leadBearing + b.targetOffset * (b.kind == 1 ? 0.08 : 0.14)
            case .evade:
                // An abrupt hook away from the pursuing aircraft.
                desired = b.heading + b.maneuverSign * (b.kind == 1 ? 1.2 : 0.95)
            case .breakAway:
                desired = b.heading + b.maneuverSign * (b.kind == 0 ? 0.62 : 0.90)
            case .regroup:
                if escorting, let bomber = nearbyBomber {
                    desired = atan2(bomber.position.y-b.position.y,
                                    bomber.position.x-b.position.x)
                } else {
                    desired = bearing + b.maneuverSign * 1.35
                }
            }

            let turnRate: CGFloat = b.kind == 1 ? 2.45 : b.kind == 0 ? 1.85 : 1.05
            let delta = atan2(sin(desired-b.heading),cos(desired-b.heading))
            b.heading += max(-turnRate*dt,min(turnRate*dt,delta))
            let speedGoal: CGFloat
            switch b.tactic {
            case .formation: speedGoal = b.kind == 2 ? 160 : 230
            case .attack: speedGoal = b.kind == 0 ? 315 : 265
            case .evade: speedGoal = b.kind == 0 ? 315 : 275
            case .breakAway: speedGoal = b.kind == 0 ? 320 : 285
            case .flank, .intercept: speedGoal = b.kind == 0 ? 275 : 250
            case .regroup: speedGoal = 225
            }
            // Pursue a favorable altitude rather than tracking only in 2D.
            let verticalDifference = altitude - b.altitude
            let verticalRate: CGFloat = b.kind == 1 ? 68 : b.kind == 0 ? 56 : 34
            let altitudeStep = max(-verticalRate*dt,min(verticalRate*dt,verticalDifference))
            b.climbVelocity = altitudeStep / max(dt,0.001)
            b.altitude += altitudeStep
            let diveBoost = b.climbVelocity < -6 ? min(36,abs(b.climbVelocity)*0.35) : 0
            b.speed += max(-115*dt,min(115*dt,speedGoal + diveBoost-b.speed))
            b.position.x += cos(b.heading)*b.speed*dt + scrolling.dx
            b.position.y += sin(b.heading)*b.speed*dt + scrolling.dy
            b.sprite.position = b.position
            b.sprite.zRotation = b.heading - .pi/2
            let visual = 1 + max(-0.12,min(0.10,(b.altitude-altitude)/6000))
            b.sprite.setScale(b.sizeAtSpawn * visual)

            let aim = abs(atan2(sin(bearing-b.heading),cos(bearing-b.heading)))
            let aimTolerance: CGFloat = difficulty == 0 ? 0.11 : difficulty == 1 ? 0.16 : 0.20
            let shotRange: CGFloat = difficulty == 0 ? 340 : difficulty == 1 ? 395 : 435
            let altitudeAligned = abs(b.altitude - altitude) < 900
            let obscured = (cloudCover || coveredByCloud(b.position, altitude:b.altitude))
            if b.tactic == .attack && b.fireCooldown <= 0 && altitudeAligned &&
               (!obscured || distance < 150) &&
               distance < shotRange && aim < aimTolerance {
                fire(from:b.position,angle:b.heading,hostile:true,sourceAltitude:b.altitude)
                sounds.play(.gun,volume:effectsVolume*0.075)
                let cooldownBase: CGFloat = difficulty == 0 ? 2.6 :
                    difficulty == 1 ? 1.75 : 1.35
                b.fireCooldown = cooldownBase + CGFloat.random(in:0.1...0.65)
            }
            b.previousDistance = distance
            bandits[i] = b
        }
        // Escaped bombers damage the defended airfield. Fighters have a larger
        // turning arena and time to circle back, but cannot accumulate forever.
        for i in bandits.indices.reversed() {
            let b = bandits[i]
            if b.missionBomber {
                if hypot(b.position.x-airfield.position.x,b.position.y-airfield.position.y) < 90 {
                    bomberEscaped += 1
                    airfieldHealth = max(0,airfieldHealth-1)
                    burst(at:airfield.position,count:26)
                    sounds.play(.explosion,volume:effectsVolume*0.65)
                    b.sprite.removeFromParent()
                    bandits.remove(at:i)
                    flash("AIRFIELD HIT — \(airfieldHealth) DEFENSE REMAINING")
                }
                continue
            }
            if b.position.x < -1100 || b.position.x > size.width+1100 ||
               b.position.y < -1100 || b.position.y > size.height+1100 {
                b.sprite.removeFromParent()
                bandits.remove(at:i)
            } else if abs(b.altitude-altitude) < 350 &&
                      hypot(b.position.x-player.position.x,
                            b.position.y-player.position.y) < 31 &&
                      gameTime > invulnerableUntil {
                takeDamage()
            }
        }

        var rearThreat = false
        for b in bandits where !b.missionBomber {
            let x = b.position.x-player.position.x
            let y = b.position.y-player.position.y
            let aft = x*cos(heading)+y*sin(heading)
            let relative = abs(atan2(sin(atan2(y,x)-heading),
                                     cos(atan2(y,x)-heading)))
            if aft < -80 && relative > 2.4 && hypot(x,y) < 530 {
                if gameTime-lastWarning > 4 {
                    sounds.play(.warning,volume:effectsVolume*0.3)
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
                      lateral: CGFloat = 0, forward: CGFloat = 0,
                      sourceAltitude: CGFloat? = nil) {
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
        rounds.append(Round(sprite:round, position:round.position,
                            velocity:CGVector(dx:cos(angle)*speed,dy:sin(angle)*speed),
                            lifetime:hostile ? 1.8 : 1.3, hostile:hostile,
                            altitude:sourceAltitude ?? altitude,
                            diveAttack:!hostile && climbRate < -32 && flightEnergy > 48))
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
                if gameTime > invulnerableUntil && abs(bullet.altitude-altitude) < 760 &&
                   hypot(bullet.position.x - player.position.x, bullet.position.y - player.position.y) < 25 {
                    takeDamage()
                    consumed = true
                }
            } else {
                for j in bandits.indices.reversed() {
                    if abs(bullet.altitude-bandits[j].altitude) < 760 &&
                       hypot(bullet.position.x - bandits[j].position.x,
                             bullet.position.y - bandits[j].position.y) < 35 {
                        bandits[j].health -= 1
                        // Direct hits provoke a defensive break rather than a
                        // pilot blindly continuing a straight firing run.
                        if bandits[j].health > 0 && !bandits[j].missionBomber &&
                           bandits[j].evadeCooldown <= 0 {
                            bandits[j].tactic = .evade
                            bandits[j].tacticTime = CGFloat.random(in:0.75...1.3)
                            bandits[j].evadeCooldown = 4.8
                            bandits[j].maneuverSign = Bool.random() ? 1 : -1
                            bandits[j].fireCooldown = max(bandits[j].fireCooldown,0.55)
                        }
                        burst(at: bullet.position, count: 5)
                        consumed = true
                        if bandits[j].health <= 0 {
                            crashPlane(bandits[j].sprite, position: bandits[j].position, duration: 1.05)
                            sounds.play(.explosion, volume: effectsVolume * 0.65)
                            let wasBomber = bandits[j].missionBomber
                            let wasElite = bandits[j].isAce
                            let wasEscort = playMode == .interception && !wasBomber
                            bandits.remove(at: j)
                            if wasBomber { bomberDestroyed += 1 }
                            if wasElite { eliteDown = true }
                            if wasEscort { missionEscortKills += 1 }
                            kills += 1
                            if gameTime < comboDeadline { hitCombo += 1 } else { hitCombo = 1 }
                            comboDeadline = gameTime + 3.6
                            let diveBonus = bullet.diveAttack ? 75 * wave : 0
                            let award = 100 * wave * min(hitCombo,4) + diveBonus
                            score += award
                            if bullet.diveAttack { flash("BOOM & ZOOM  /  +\(award)") }
                            else if hitCombo > 1 { flash("COMBO ×\(hitCombo)   +\(award)") }
                            else { flash("SPLASH ONE   +\(award)") }
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
        if playMode == .interception { missionHitsTaken += 1 }
        invulnerableUntil = gameTime + 0.75
        burst(at: player.position, count: 24)
        sounds.play(.hit, volume: effectsVolume * 0.45)
        if health <= 0 {
            sounds.stopEngine()
            beginPlayerCrash()
        } else {
            player.run(.sequence([.fadeAlpha(to: 0.25, duration: 0.1), .fadeAlpha(to: 1, duration: 0.25)]))
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
    func saveNow() {
        if playMode == .endless && !gameOver && !deathStarted { saveRun() }
    }
    func resumeSavedSortie() {
        guard playMode == .endless && prefs.bool(forKey:"aces.hasSave") else { return }
        guard let saved = prefs.dictionary(forKey:"aces.savedRun") else { return }
        restart()
        prefs.set(saved,forKey:"aces.savedRun")
        prefs.set(true,forKey:"aces.hasSave")
        loadRun()
        pausedGame = false
        status.text = "SORTIE RESUMED"
        status.run(.sequence([.wait(forDuration:1.1),.run { [weak self] in
            self?.status.text = ""
        }]))
        view?.window?.makeFirstResponder(self)
    }
    func togglePause() {
        guard !gameOver && !deathStarted &&
              (playMode == .endless || missionStage == .active) else { return }
        pausedGame.toggle()
        status.text = pausedGame ? "PAUSED — P TO RESUME" : ""
        view?.window?.makeFirstResponder(self)
    }
    func setSoundEnabled(_ enabled: Bool) {
        if enabled {
            sounds.startEngine(volume:effectsVolume * 0.18)
        } else {
            sounds.stopEngine()
        }
        view?.window?.makeFirstResponder(self)
    }

    private func saveRun() {
        let snapshot: [String: Any] = [
            "fighter": fighter.rawValue, "score":score, "kills":kills,
            "health":health, "ammo":ammo, "elapsed":Double(gameTime),
            "altitude":Double(altitude), "airspeed":Double(airspeed),
            "heading":Double(heading), "playerX":Double(player.position.x),
            "playerY":Double(player.position.y),
            "offsetX":Double(terrainOffset.x), "offsetY":Double(terrainOffset.y),
            "energy":Double(flightEnergy)
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
        flightEnergy = CGFloat(saved["energy"] as? Double ?? 68)
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
            if self?.playMode == .interception {
                self?.finishMission(success:false, reason:"AIRCRAFT LOST")
            } else {
                self?.prefs.set(false, forKey:"aces.hasSave")
                self?.prefs.removeObject(forKey:"aces.savedRun")
                self?.status.text = "SHOT DOWN — RETURN TO RESTART"
            }
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

    // MARK: Phase 3 tactical vision and predictive gunnery
    // Clouds use the same camera-relative positions as the aircraft.
    // Check altitude too: crossing a cloud on the map is not concealment
    // when the aircraft is well above or below its layer.
    private func coveredByCloud(_ point: CGPoint, altitude targetAltitude: CGFloat) -> Bool {
        for (index, cloud) in cloudClusters.enumerated() {
            guard index < cloudAltitudes.count,
                  abs(targetAltitude - cloudAltitudes[index]) < 750,
                  let sprite = cloud as? SKSpriteNode else { continue }
            let dx = point.x - cloud.position.x
            let dy = point.y - cloud.position.y
            let x = max(1, sprite.size.width * 0.35)
            let y = max(1, sprite.size.height * 0.31)
            if (dx * dx)/(x * x) + (dy * dy)/(y * y) < 1 { return true }
        }
        return false
    }

    private func configureLeadCue() {
        leadCue.zPosition = 104
        leadCue.isHidden = true
        let ring = SKShapeNode(circleOfRadius: 12)
        ring.strokeColor = SKColor.cyan.withAlphaComponent(0.76)
        ring.lineWidth = 1.3
        ring.fillColor = .clear
        leadCue.addChild(ring)
        for delta in [CGFloat(0), .pi / 2, .pi, .pi * 1.5] {
            let path = CGMutablePath()
            path.move(to:CGPoint(x:cos(delta)*15,y:sin(delta)*15))
            path.addLine(to:CGPoint(x:cos(delta)*21,y:sin(delta)*21))
            let dash = SKShapeNode(path:path)
            dash.strokeColor = .cyan.withAlphaComponent(0.6)
            dash.lineWidth = 1.2
            leadCue.addChild(dash)
        }
        addChild(leadCue)
    }

    private func updateLeadCue() {
        leadCue.isHidden = true
        guard !bandits.isEmpty else { return }
        let projectileSpeed: CGFloat = 790
        var closestPosition: CGPoint?
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        var alignedAltitude = false
        for target in bandits {
            let dx = target.position.x-player.position.x
            let dy = target.position.y-player.position.y
            let distance = hypot(dx,dy)
            if distance >= 760 || distance >= closestDistance { continue }
            let relative = atan2(sin(atan2(dy,dx)-heading),
                                 cos(atan2(dy,dx)-heading))
            if abs(relative) > 0.55 { continue }
            closestDistance = distance
            closestPosition = target.position
            alignedAltitude = abs(target.altitude-altitude) < 760
        }
        guard let selected = closestPosition else { return }
        // Estimate interception using target heading and speed. This is a
        // leading reference, not a lock-on; the user must still fly and aim.
        guard let target = bandits.min(by:{
            hypot($0.position.x-selected.x,$0.position.y-selected.y) <
            hypot($1.position.x-selected.x,$1.position.y-selected.y)
        }) else { return }
        let travelTime = min(0.85, closestDistance / projectileSpeed)
        let aimPoint = CGPoint(x:selected.x + cos(target.heading)*target.speed*travelTime,
                               y:selected.y + sin(target.heading)*target.speed*travelTime)
        leadCue.position = aimPoint
        leadCue.isHidden = !alignedAltitude || cloudCover ||
            coveredByCloud(target.position,altitude:target.altitude)
    }

    private func installTelemetry() {
        hud.isHidden = true // SwiftUI header and footer own their navigation text.
        let ice = SKColor(calibratedRed: 0.12, green: 0.91, blue: 0.99, alpha: 1)
        let amber = SKColor(calibratedRed: 1, green: 0.72, blue: 0.40, alpha: 0.94)
        let muted = SKColor(calibratedWhite: 0.82, alpha: 0.9)
        telemetryPanel.fillColor = SKColor(calibratedRed: 0.035, green: 0.085, blue: 0.13,
            alpha: CGFloat(prefs.object(forKey: "aces.telemetryOpacity") as? Double ?? 0.23))
        telemetryPanel.strokeColor = SKColor(calibratedWhite: 0.81, alpha: 0.17)
        telemetryPanel.lineWidth = 0.55
        telemetryPanel.zPosition = 90
        addChild(telemetryPanel)

        telemetryAccent.fillColor = amber.withAlphaComponent(0.72)
        telemetryAccent.strokeColor = .clear
        telemetryAccent.zPosition = 91
        addChild(telemetryAccent)
        for rule in telemetryRules {
            rule.fillColor = SKColor(calibratedWhite: 0.81, alpha: 0.20)
            rule.strokeColor = .clear
            rule.zPosition = 91
            addChild(rule)
        }
        for (i, label) in telemetryLines.enumerated() {
            label.fontSize = i == 2 ? 30 : i == 5 ? 25 :
                (i == 8 || i == 9 || i == 12 ? 13 : 10)
            if [0, 7, 11, 15].contains(i) {
                label.fontSize = 9
                label.fontColor = amber
            } else if [2, 5, 8, 9].contains(i) {
                label.fontColor = ice
            } else {
                label.fontColor = muted
            }
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .center
            label.zPosition = 93
            addChild(label)
        }
        radarPanel.fillColor = SKColor(calibratedRed: 0.035, green: 0.085, blue: 0.13,
            alpha: CGFloat(prefs.object(forKey: "aces.telemetryOpacity") as? Double ?? 0.23))
        radarPanel.strokeColor = .cyan.withAlphaComponent(0.3)
        radarPanel.lineWidth = 0.7
        radarPanel.zPosition = 91
        addChild(radarPanel)
        radarContacts.zPosition = 93
        addChild(radarContacts)
        radarLegend.fontSize = 9
        radarLegend.fontColor = SKColor(calibratedWhite:0.86,alpha:0.89)
        radarLegend.horizontalAlignmentMode = .right
        radarLegend.zPosition = 95
        radarLegend.text = "LONG RANGE  /  2400 UNITS"
        addChild(radarLegend)

        attitudePanel.fillColor = SKColor(calibratedRed: 0.035, green: 0.085, blue: 0.13,
            alpha: CGFloat(prefs.object(forKey: "aces.telemetryOpacity") as? Double ?? 0.23))
        attitudePanel.strokeColor = .cyan.withAlphaComponent(0.28)
        attitudePanel.lineWidth = 0.7
        attitudePanel.zPosition = 91
        addChild(attitudePanel)
        attitude.zPosition = 94
        addChild(attitude)
        layoutTelemetry()
    }

    private func layoutTelemetry() {
        let right = size.width - 15
        let panelWidth: CGFloat = min(232, max(190, size.width * 0.195))
        let panelHeight: CGFloat = min(380, max(300, size.height * 0.52))
        let top = size.height - 14
        let panel = CGRect(x: right - panelWidth, y: top - panelHeight,
                           width: panelWidth, height: panelHeight)
        telemetryPanel.path = CGPath(roundedRect: panel, cornerWidth: 8, cornerHeight: 8, transform: nil)
        telemetryAccent.path = CGPath(rect: CGRect(x:panel.minX+6,y:panel.minY+10,
                                                  width:2,height:panelHeight-20),transform:nil)

        // Explicit vertical hierarchy: score, wave, aircraft, tactical, systems.
        let baseOffsets: [CGFloat] = [15,33,60,91,111,139,165,188,210,
                                      232,251,276,296,316,331,348,364,379,394]
        let scale = panelHeight / 410
        let rightX = panel.maxX - 12
        for (i, label) in telemetryLines.enumerated() {
            label.position = CGPoint(x:rightX, y:panel.maxY - baseOffsets[i] * scale)
            label.setScale(min(1, max(0.75, scale)))
        }
        for (i, offset) in [100.0, 177.0, 267.0].enumerated() {
            telemetryRules[i].path = CGPath(rect: CGRect(
                x: panel.minX + 16, y: panel.maxY - CGFloat(offset) * scale,
                width: panelWidth - 29, height: 0.7), transform: nil)
        }
        let attitudeHeight: CGFloat = min(124, max(106, size.height * 0.16))
        let attitudeRect = CGRect(x: panel.minX, y: panel.minY - 8 - attitudeHeight,
                                  width:panelWidth,height:attitudeHeight)
        attitudePanel.path = CGPath(roundedRect: attitudeRect, cornerWidth: 8, cornerHeight: 8,
                                    transform:nil)
        attitude.position = CGPoint(x:attitudeRect.midX,y:attitudeRect.midY)
        attitude.setScale(min(1, attitudeHeight / 134))

        let radarBottom: CGFloat = 12
        let radarFrame = CGRect(x:panel.minX,y:radarBottom,width:panelWidth,
                                height:max(100,attitudeRect.minY - radarBottom - 8))
        radarPanel.path = CGPath(roundedRect:radarFrame,cornerWidth:8,cornerHeight:8,transform:nil)
        radarRadius = min(84,(radarFrame.height - 24) / 2)
        radarContacts.position = CGPoint(x:radarFrame.midX,y:radarFrame.midY - 4)
        radarLegend.position = CGPoint(x:radarFrame.maxX - 11,y:radarFrame.maxY - 14)
    }
    private func updateRadar() {
        if gameTime - lastRadarRender < 0.045 { return }
        lastRadarRender = gameTime
        updateAttitude()
        radarContacts.removeAllChildren()
        let radius = radarRadius
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
            // 2400 game-world units displayed out to the outer ring.
            // Nonlinear radial compression preserves near-contact separation.
            let actualRange = hypot(lateral,ahead)
            if actualRange > radarRange { continue }
            let rangeFraction = actualRange / radarRange
            let renderedRadius = radius * pow(rangeFraction,0.77)
            let px = actualRange > 0 ? (lateral / actualRange) * renderedRadius : 0
            let py = actualRange > 0 ? (ahead / actualRange) * renderedRadius : 0
            let contactSize: CGFloat = bandit.kind == 2 ? 4.0 : 3.1
            let blip = SKShapeNode(circleOfRadius:contactSize * (1 - 0.30 * rangeFraction))
            blip.position = CGPoint(x: px, y: py)
            blip.fillColor = bandit.missionBomber ? .orange : .red
            blip.strokeColor = bandit.missionBomber ? .yellow : .orange
            blip.glowWidth = 1.5
            let swept = (radarSweep - atan2(py, px)).truncatingRemainder(dividingBy: 2 * .pi)
            let lag = swept < 0 ? swept + 2 * .pi : swept
            blip.alpha = (0.18 + 0.82 * exp(-lag * 0.53)) * (1 - 0.42 * rangeFraction)
            radarContacts.addChild(blip)
        }
        if playMode == .interception && missionStage == .active {
            let deltaX = airfield.position.x - player.position.x
            let deltaY = airfield.position.y - player.position.y
            let lateral = sin(heading)*deltaX - cos(heading)*deltaY
            let forward = cos(heading)*deltaX + sin(heading)*deltaY
            let distance = hypot(lateral,forward)
            if distance < radarRange {
                let offset = radius * pow(distance / radarRange,0.77)
                let marker = SKShapeNode(rectOf:CGSize(width:7,height:7),cornerRadius:1)
                marker.fillColor = .green
                marker.strokeColor = .white.withAlphaComponent(0.75)
                marker.position = distance > 0 ?
                    CGPoint(x:lateral/distance*offset,y:forward/distance*offset) : .zero
                radarContacts.addChild(marker)
            }
        }
    }

    private func updateLabels() {
        status.position = CGPoint(x:size.width/2,y:size.height*0.64)
        // Important rear threats must remain readable outside the panel.
        threat.position = CGPoint(x:size.width - 252,y:size.height - 29)
        hud.text = "VECTOR ACES / WWII AIR COMBAT"
        if score > prefs.integer(forKey:"aces.bestScore") {
            prefs.set(score,forKey:"aces.bestScore")
        }
        let degrees = Int((90 - heading * 180 / .pi).truncatingRemainder(dividingBy: 360) + 360) % 360
        let contacts = bandits.filter {
            hypot($0.position.x-player.position.x,$0.position.y-player.position.y) <= radarRange
        }
        let nearest = bandits.min { lhs,rhs in
            hypot(lhs.position.x-player.position.x,lhs.position.y-player.position.y) <
            hypot(rhs.position.x-player.position.x,rhs.position.y-player.position.y)
        }
        var bearingText = "NO CONTACT"
        var rangeText = "RANGE  ---"
        if let target = nearest {
            let dx = target.position.x-player.position.x
            let dy = target.position.y-player.position.y
            let distance = hypot(dx,dy)
            let relative = atan2(sin(atan2(dy,dx)-heading),cos(atan2(dy,dx)-heading))
            // Positive relative angle is left of the aircraft. Clock numbers
            // advance to the RIGHT, so the sign is deliberately inverted.
            let hour = Int((12 - (relative * 6 / .pi)).rounded())
            let clock = ((hour % 12) + 12) % 12
            bearingText = String(format:"NEAREST  %02d O'CLOCK",clock == 0 ? 12 : clock)
            rangeText = String(format:"RANGE  %04d UNITS",Int(distance.rounded()))
        }
        let airframe = max(0,health)
        let ammoText = prefs.bool(forKey:"aces.unlimitedAmmo") ? "UNLIMITED" : String(ammo)
        let altitudeBand = altitude < 3500 ? "LOW" : altitude < 15000 ? "COMBAT" : "HIGH"
        let rate = Int(climbRate * 60)
        let engine = airframe <= 1 ? "CRITICAL" : airframe <= fighter.health / 2 ? "DAMAGED" : "NORMAL"
        // Arcade power indication reflects current usable speed, not engine manifold pressure.
        let power = Int(max(0,min(100,(airspeed - 105) / max(1,fighter.speed - 10) * 100)))
        let difficulty = ["ROOKIE","VETERAN","ACE"][min(2,max(0,prefs.integer(forKey:"aces.difficulty")))]
        let rows = [
            "VECTOR ACES  //  TELEMETRY",
            "CURRENT SCORE",
            String(format:"%06d",score),
            String(format:"BEST  %06d",prefs.integer(forKey:"aces.bestScore")),
            "CURRENT WAVE",
            String(format:"%02d",wave),
            String(format:"%02d KILLS   /   %02d CONTACTS",kills,contacts.count),
            "AIRCRAFT STATUS",
            "AIRFRAME  \(airframe)/\(fighter.health)",
            "AMMO  \(ammoText)",
            "\(Int(airspeed)) MPH  /  \(Int(altitude)) FT",
            "TACTICAL AWARENESS",
            bearingText,
            rangeText,
            "CONTACTS IN RANGE  \(contacts.count)",
            "FLIGHT SYSTEMS",
            "\(fighter.rawValue.uppercased())",
            "HDG \(degrees)°  V/S \(rate >= 0 ? "+" : "")\(rate) FPM",
            "ENERGY \(Int(flightEnergy))% / \(cloudCover ? "CLOUD" : altitudeBand) / \(engine)",
        ]
        for (i,label) in telemetryLines.enumerated() {
            label.text = rows[i]
            if i == 8 {
                label.fontColor = airframe <= 1 ? .red : .cyan
            }
        }
        // Priority guidance avoids crowding the Vector Drift-style panel.
        if altitude < 700 {
            tacticalCue.text = "⚠ TERRAIN  /  PULL UP"
            tacticalCue.fontColor = .orange
        } else if cloudCover {
            tacticalCue.text = "CLOUD COVER  /  VISIBILITY REDUCED"
            tacticalCue.fontColor = .cyan
        } else if climbRate < -35 && flightEnergy > 48 {
            tacticalCue.text = "DIVE ATTACK  /  SPEED BONUS"
            tacticalCue.fontColor = .cyan
        } else if climbRate > 25 {
            tacticalCue.text = "CLIMB  /  ENERGY DRAIN"
            tacticalCue.fontColor = .yellow
        } else {
            tacticalCue.text = ""
        }
        // The external threat banner is governed by the combat AI and stays
        // visible during the closest rear attack.
        updateRadar()
    }
    func restart() {
        for b in bandits { b.sprite.removeFromParent() }
        for r in rounds { r.sprite.removeFromParent() }
        bandits.removeAll()
        rounds.removeAll()
        gameTime = 0
        lastFormation = -8
        nextFlightID = 1
        lastWarning = -10
        hitCombo = 0
        comboDeadline = 0
        threat.text = ""
        lastFire = -1
        if playMode == .endless {
            prefs.set(false, forKey: "aces.hasSave")
            prefs.removeObject(forKey: "aces.savedRun")
        }
        health = fighter.health
        deathStarted = false
        player.removeAllActions()
        if player.parent == nil { addChild(player) }
        player.setScale(0.9)
        playerArtwork.xScale = 1
        playerArtwork.yScale = 1
        playerArtwork.position.x = 0
        playerArtwork.zRotation = 0
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
        flightEnergy = 68
        cloudCover = false
        lastTerrainAlert = -100
        leadCue.isHidden = true
        tacticalCue.text = ""
        heading = .pi / 2
        player.position = CGPoint(x: size.width / 2, y: size.height / 2)
        keys.removeAll()
        gameOver = false
        pausedGame = false
        invulnerableUntil = 0
        status.text = ""
        if playMode == .interception {
            clearMissionAllies()
            missionTime = 0
            bomberLaunched = 0
            bomberDestroyed = 0
            bomberEscaped = 0
            airfieldHealth = 3
            missionEscortKills = 0
            missionHitsTaken = 0
            escortWaveIndex = 0
            eliteLaunched = false
            eliteDown = false
            campaignKillsAtStart = 0
            configureAirfield()
            showMissionBriefing()
        }
        if prefs.object(forKey:"aces.soundEnabled") as? Bool ?? true {
            sounds.startEngine(volume:effectsVolume * 0.18)
        }
        updateLabels()
    }
}

private final class CombatAudio {
    enum Effect: CaseIterable, Hashable { case gun, hit, explosion, warning, menu }
    static let shared = CombatAudio()

    // Continuous engine audio never shares a playback queue with combat effects.
    private let engine = AVAudioEngine()
    private let enginePlayer = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var buffers: [Effect: AVAudioPCMBuffer] = [:]
    private var voices: [Effect: [AVAudioPlayerNode]] = [:]
    private var nextVoice: [Effect: Int] = [:]
    private var engineBuffer: AVAudioPCMBuffer?
    var engineVolume: Float = 0.12 {
        didSet { enginePlayer.volume = engineVolume }
    }

    private init() {
        engine.attach(enginePlayer)
        engine.connect(enginePlayer, to: engine.mainMixerNode, format: format)
        // Generate and attach every sound ONCE, before the first dogfight.
        // No audio synthesis or new AVAudioPlayerNode allocation occurs on shot.
        for effect in Effect.allCases {
            buffers[effect] = makeBuffer(effect)
            let voiceCount: Int
            switch effect {
            case .gun: voiceCount = 12
            case .explosion: voiceCount = 6
            case .hit: voiceCount = 4
            case .warning: voiceCount = 2
            case .menu: voiceCount = 3
            }
            let pool = (0..<voiceCount).map { _ -> AVAudioPlayerNode in
                let node = AVAudioPlayerNode()
                engine.attach(node)
                engine.connect(node, to: engine.mainMixerNode, format: format)
                return node
            }
            voices[effect] = pool
            nextVoice[effect] = 0
        }
        engineBuffer = makeEngineBuffer()
        engine.prepare()
        try? engine.start()
    }

    func startEngine(volume: Double) {
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning, let buffer = engineBuffer else { return }
        enginePlayer.stop()
        enginePlayer.scheduleBuffer(buffer, at: nil, options: .loops)
        engineVolume = Float(max(0, min(1, volume)))
        enginePlayer.play()
    }

    func stopEngine() { enginePlayer.stop() }

    func play(_ effect: Effect, volume: Double) {
        guard volume > 0, let buffer = buffers[effect],
              let pool = voices[effect], !pool.isEmpty else { return }
        if !engine.isRunning { try? engine.start() }
        guard engine.isRunning else { return }

        // Choose an idle voice first. If every voice is busy, replace the
        // oldest round-robin voice instead of queuing behind old gunshots.
        let cursor = nextVoice[effect] ?? 0
        let selected = (0..<pool.count)
            .map { (cursor + $0) % pool.count }
            .first { !pool[$0].isPlaying } ?? cursor
        let node = pool[selected]
        nextVoice[effect] = (selected + 1) % pool.count
        node.stop() // Clear any residual scheduled audio on this voice.
        node.volume = Float(max(0, min(1, volume)))
        node.scheduleBuffer(buffer, at: nil, options: .interrupts)
        node.play()
    }

    private func makeEngineBuffer() -> AVAudioPCMBuffer? {
        let count = 44_100
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                          frameCapacity: AVAudioFrameCount(count)),
              let samples = buffer.floatChannelData?.pointee else { return nil }
        buffer.frameLength = AVAudioFrameCount(count)
        for i in 0..<count {
            let t = Double(i) / 44_100
            let envelope = 0.7 + 0.3 * sin(2 * .pi * 5 * t)
            samples[i] = Float((sin(2 * .pi * 76 * t) +
                                0.23 * sin(2 * .pi * 152 * t)) * envelope * 0.5)
        }
        return buffer
    }

    private func makeBuffer(_ effect: Effect) -> AVAudioPCMBuffer? {
        let duration: Double
        switch effect {
        case .gun: duration = 0.09
        case .hit: duration = 0.19
        case .explosion: duration = 0.76
        case .warning: duration = 0.18
        case .menu: duration = 0.09
        }
        let count = Int(44_100 * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format,
                                          frameCapacity: AVAudioFrameCount(count)),
              let samples = buffer.floatChannelData?.pointee else { return nil }
        buffer.frameLength = AVAudioFrameCount(count)
        for i in 0..<count {
            let t = Double(i) / 44_100
            let noise = Double.random(in: -1...1)
            let envelope = max(0, 1 - t / duration)
            let wave: Double
            switch effect {
            case .gun:
                wave = (noise * 0.72 + sin(2 * .pi * 86 * t) * 0.28)
                    * envelope * envelope
            case .hit:
                wave = (noise * 0.65 + sin(2 * .pi * 145 * t) * 0.35)
                    * envelope
            case .explosion:
                wave = (noise * 0.75 + sin(2 * .pi * (56 - t * 24) * t) * 0.25)
                    * envelope * envelope
            case .warning:
                wave = sin(2 * .pi * 820 * t) * envelope
            case .menu:
                wave = sin(2 * .pi * 620 * t) * envelope
            }
            samples[i] = Float(max(-0.85, min(0.85, wave)))
        }
        return buffer
    }
}
