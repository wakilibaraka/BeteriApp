//
//  BBHUDView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/12/23.
//

import SwiftUI

enum HUDAlertTypes:Int {
    case chargingComplete
    case chargingBegan
    case chargingStopped
    case percentFive
    case percentTen
    case percentTwentyFive
    case percentOne
    case percentMinThreshold
    case percentMaxThreshold
    case userInitiated
    case userLaunched
    case userEvent
    case deviceOverheating
    case deviceConnected
    case deviceRemoved
    case deviceDistance
    case userSettings

    var sfx:SystemSoundEffects? {
        switch self {
            case .chargingBegan : return .high
            case .chargingComplete : return .high
            case .chargingStopped : return .low
            case .percentTwentyFive : return .low
            case .percentTen : return .low
            case .percentFive : return .low
            case .percentOne : return .low
            case .percentMinThreshold: return .low
            case .percentMaxThreshold: return .high
            case .userLaunched : return nil
            case .userInitiated : return nil
            case .userSettings : return nil
            case .userEvent : return .low
            case .deviceOverheating : return .low
            case .deviceRemoved : return .low
            case .deviceConnected : return .high
            case .deviceDistance : return .low

        }
        
    }
    
    var trigger:Bool {
        switch self {
            case .chargingBegan : return true
            case .chargingComplete : return true
            case .chargingStopped : return true
            case .deviceRemoved : return true
            case .deviceConnected : return true
            default : return false
            
        }
        
    }
    
    var timeout:Bool {
        switch self {
            case .userLaunched, .userInitiated, .userSettings : return false
            default : return true
        }
    }
    
}

enum HUDProgressLayout {
    case center
    case trailing
    
}

enum HUDState:Equatable {
    case hidden
    case progress
    case revealed
    case detailed
    case dismissed
    
    var visible:Bool {
        switch self {
            case .detailed : return true
            case .revealed : return true
            default : return false
            
        }
        
    }
    
    func mask(showSettings: Bool = false) -> AnimationObject? {
        if self == .revealed {
            // Smooth single step to pill (no circle bulge)
            return .init([
                .init(0.5, easing: .bounce, width: 380, height: 100, blur: 0, radius: 50)], id: "initial")
            
        }
        else if self == .detailed {
            return .init([.init(0.5, easing: .bounce, width: 480, height: showSettings ? 650 : 270, radius: 16)], id:"expand_out")
            
        }
        else if self == .dismissed {
            // Snappy collapse straight to vanishing
            return .init([
                .init(0.3, easing: .easeout, width: 60, height: 60, opacity: 0, radius: 30)], id: "expand_close")

        }
        
        return nil
        
    }
    
    var glow:AnimationObject? {
        if self == .revealed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .bounce, opacity: 0.4, scale: 1.9),
                .init(0.4, easing: .easein, opacity: 0.0, blur:2.0)])
            
        }
        else if self == .dismissed {
            return .init([
                .init(0.03, easing: .easeout, opacity: 0.0, scale: 0.2),
                .init(0.4, easing: .easein, opacity: 0.6, scale:1.4),
                .init(0.2, easing: .bounce, opacity: 0.0, scale: 0.2)])
            
        }
        
        return nil

    }
    
    var progress:AnimationObject? {
        if self == .revealed {
            // Content fades in shortly after pill has expanded
            return .init([
                .init(0.01, easing: .linear, opacity: 0.0, scale: 0.85),
                .init(0.3, delay: 0.5, easing: .easeout, opacity: 1.0, scale: 1.0)])
            
        }
        else if self == .dismissed {
            return .init([.init(0.3, easing: .easeout, opacity: 0.0, blur: 4.0, scale: 0.9)])
            
        }

        return nil
        
    }
    
    var container:AnimationObject? {
        if self == .detailed {
            return .init([.init(0.4, easing: .easeout, padding:.init(top:24, bottom:16))], id:"hud_expand")
            
        }
        else if self == .dismissed {
            return .init([.init(0.3, easing: .easeout, opacity: 0.0, blur: 3.0)])

        }
        
        return nil

    }


}

struct HUDIcon: View {
    @EnvironmentObject var stats:StatsManager

    @Namespace private var animation

    var body: some View {
        VStack {
            ZStack {
                if stats.statsIcon.system == true {
                    Image(systemName: stats.statsIcon.name)
                        .resizable()
                        .aspectRatio(contentMode: .fit).matchedGeometryEffect(id: "icon", in: animation)

                }
                else {
                    Image(stats.statsIcon.name)
                        .resizable()
                        .aspectRatio(contentMode: .fit).matchedGeometryEffect(id: "icon", in: animation)
                        
                }
                
            }
            .frame(width: 32, height: 32)
            .foregroundColor(Color("BatterySubtitle"))
            .offset(y:1)
            
        }
        .frame(width: 28, height: 28)
        .padding(.leading, 8)
        .padding(.trailing, 4)
        .background(Color.clear)
        
    }
    
}

struct ActiveConnectionsView: View {
    @EnvironmentObject var bluetooth: BluetoothManager
    
    var connectedDevices: [BluetoothObject] {
        bluetooth.list.filter { $0.connected == .connected && $0.type.icon != "" }
    }
    
    var displayConnections: [BluetoothObject] {
        Array(connectedDevices.prefix(2))
    }
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(displayConnections, id: \.address) { (device: BluetoothObject) in
                HStack(spacing: 4) {
                    Image(systemName: device.type.icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(device.device ?? device.type.type.name)
                        .font(.system(size: 10, weight: .medium))
                        .lineLimit(1)
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            }
            
            if connectedDevices.count > 2 {
                Text("+\(connectedDevices.count - 2)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 4)
            }
        }
        .layoutPriority(1)
    }
}


struct HUDSummary: View {
    @EnvironmentObject var stats:StatsManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var window:WindowManager
    @EnvironmentObject var bluetooth:BluetoothManager

    @State private var title = ""
    @State private var subtitle = ""
    @State private var visible:Bool = false
    
    var body: some View {
        HStack(alignment: .center) {
            HUDIcon()
            
            VStack(alignment: .leading, spacing: 1) {
                Text(self.title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                ViewMarkdown($subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .opacity(0.8)
                
                if self.updates.available != nil {
                    UpdatePromptView()
                    
                }
                
                if self.title != "" {
                    ActiveConnectionsView()
                        .padding(.top, 2)
                }
                
            }
            
            Spacer()
            
        }
        .blur(radius: self.visible ? 0.0 : 4.0)
        .opacity(self.visible ? 1.0 : 0.0)
        .onAppear() {
            self.title = self.stats.title
            self.subtitle = self.stats.subtitle
            self.visible = WindowManager.shared.state.visible

        }
        .onChange(of: self.stats.title) { newValue in
            self.title = newValue

        }
        .onChange(of: self.stats.subtitle) { newValue in
            self.subtitle = newValue

        }
        .onChange(of: window.state, perform: { newValue in
            withAnimation(Animation.easeOut(duration: 0.35).delay(self.visible == false ? 0.5 : 0.0)) {
                self.visible = newValue.visible

            }
          
        })
        
    }
    
}

struct HUDContainer: View {
    @EnvironmentObject var battery:BatteryManager
    @EnvironmentObject var manager:WindowManager
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var namespace:Namespace.ID
    @State private var animation:AnimationState = .waiting

    init(animation:Namespace.ID) {
        self._namespace = State(initialValue: animation)
        self._timeline = State(initialValue: .init([]))
    }
    
    var body: some View {
        HStack(alignment: .center) {
            HUDSummary()
            HUDProgress().matchedGeometryEffect(id: "progress", in: self.namespace)
        }
        .timeline($timeline ,state: $animation)
        .padding(.leading, 4)
        .padding(.trailing, 10)
        .onAppear() {
            if let animation = window.state.container {
                self.timeline = animation
                
            }
            
        }
        .onChange(of: window.state, perform: { newValue in
            if let animation = newValue.container {
                self.timeline = animation
            }
        })
        
    }
    
}

struct HUDMaskView: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    var keyframes = Array<AnimationKeyframeObject>()
    
    init() {
        self._timeline = State(initialValue: .init([]))
        
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .timeline($timeline, state: $animation)
                .frame(width: 20, height: 20)
            
        }
        .onAppear() {
            if let animation = window.state.mask(showSettings: window.showSettings) {
                self.timeline = animation
                
            }
          
        }
        .onChange(of: window.state, perform: { newValue in
            if let animation = newValue.mask(showSettings: window.showSettings) {
                self.timeline = animation
                
            }
          
        })
        .onChange(of: window.showSettings, perform: { newValue in
            if let animation = window.state.mask(showSettings: newValue) {
                self.timeline = animation
            }
        })
        
    }

}

struct HUDGlow: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        Circle()
            .fill(Color("BatteryBackground"))
            .frame(width: 80, height: 80)
            .timeline($timeline, state: $animation)
            .onAppear() {
                if let animation = window.state.glow {
                    self.timeline = animation
                    
                }
              
            }
            .onChange(of: window.state, perform: { newValue in
                if let animation = newValue.glow {
                    self.timeline = animation
                    
                }
              
            })

    }
    
}

struct HUDProgress: View {
    @EnvironmentObject var window:WindowManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        RadialProgressContainer(true)
            .timeline($timeline, state: $animation)
            .onAppear() {
                if let animation = window.state.progress {
                    self.timeline = animation
                    
                }
              
            }
            .onChange(of: window.state, perform: { newValue in
                if let animation = newValue.progress {
                    self.timeline = animation
                    
                }
                
            })
        
    }
    
}

struct HUDView: View {
    @EnvironmentObject var window:WindowManager
    @EnvironmentObject var appManager:AppManager
    @EnvironmentObject var bluetooth:BluetoothManager

    @State private var timeline:AnimationObject
    @State private var animation:AnimationState = .waiting

    @Namespace private var namespace

    init() {
        self._timeline = State(initialValue: .init([]))

    }
    
    var body: some View {
        ZStack(alignment: .center) {
            if self.window.state == .detailed {
                DetailedPanelView()
            }
            else {
                VStack {
                    HUDContainer(animation: namespace)
                        .matchedGeometryEffect(id: "hud", in: self.namespace)
                }
            }
        }
        .frame(width: window.state == .detailed ? 480 : 400, height: window.state == .detailed ? (window.showSettings ? 750 : 370) : 200)
        .background(
            ZStack {
                if window.state == .detailed {
                    VisualEffectView()
                } else {
                    Color("BatteryBackground").opacity(window.opacity)
                }
            }
        )
        .timeline($timeline, state: $animation)
        .mask(
            HUDMaskView()
        )
        .onHover(perform: { hover in
            self.window.hover = hover
        })
    }
}

struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .popover
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct DetailedPanelView: View {
    @EnvironmentObject var appManager: AppManager
    @EnvironmentObject var bluetooth: BluetoothManager
    @EnvironmentObject var battery: BatteryManager
    @EnvironmentObject var settings: SettingsManager
    
    @EnvironmentObject var window: WindowManager

    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BeteriApp")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("macOS System Utility")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Settings button
                    Button(action: {
                        withAnimation(.easeOut(duration: 0.3)) {
                            window.showSettings.toggle()
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 26, height: 26)
                            .background(Color.primary.opacity(0.04))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Advanced Settings")
                    
                    // Quit button
                    Button(action: {
                        SettingsManager.shared.settingsAction(.init(.appQuit))
                    }) {
                        Image(systemName: "power")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.red.opacity(0.8))
                            .frame(width: 26, height: 26)
                            .background(Color.red.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Quit BeteriApp")
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            Divider()
                .opacity(0.4)
            
            // Top Section: Battery & Devices
            HStack(alignment: .top, spacing: 14) {
                // Left Column: MacBook Battery (BatteryHeroView)
                VStack {
                    Spacer()
                    BatteryHeroView()
                    Spacer()
                }
                .padding(14)
                .frame(width: 180)
                .frame(maxHeight: .infinity)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)
                
                // Right Column: Connected Bluetooth Devices
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connected Devices")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    let connectedDevices = bluetooth.list.filter { $0.connected == .connected }
                    if !connectedDevices.isEmpty {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(connectedDevices, id: \.address) { device in
                                    DeviceCardView(device: device)
                                }
                            }
                            .padding(.trailing, 4)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "bolt.horizontal.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No Connected Devices")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)
            }
            .frame(height: 200)
            .padding(14)
            
            // Battery Stats Row — always visible
            BatteryStatsPanel()
                .padding(.horizontal, 14)
                .padding(.bottom, 14)
            
            if window.showSettings {
                Divider()
                    .opacity(0.4)
                
                // Bottom Section: Settings Form
                RedesignedSettingsFormView()
                    .padding(.top, 4)
            }
        }
        .frame(width: 480, height: window.showSettings ? 750 : 370)
        .clipped()
    }
}

struct HUDParent: View {
    @State var type:HUDAlertTypes
    @State var device:BluetoothObject?

    init(_ type: HUDAlertTypes, device:BluetoothObject?) {
        self._type = State(initialValue: type)
        self._device = State(initialValue: device)
        
    }
    
    var body: some View {
        VStack {
            HUDView()
          
        }
        .environmentObject(WindowManager.shared)
        .environmentObject(AppManager.shared)
        .environmentObject(BatteryManager.shared)
        .environmentObject(SettingsManager.shared)
        .environmentObject(UpdateManager.shared)
        .environmentObject(StatsManager.shared)
        .environmentObject(BluetoothManager.shared)

    }
    
}
