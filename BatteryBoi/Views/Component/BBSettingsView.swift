//
//  BBActionView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/15/23.
//

import SwiftUI

struct SettingsScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGPoint = .zero
    
    static func reduce(value: inout CGPoint, nextValue: () -> CGPoint) {
        
    }
    
}

struct SettingsItem: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var settings:SettingsManager
    @EnvironmentObject var battery:BatteryManager

    @Binding var hover:Bool

    @State var item:SettingsActionObject
    @State var subtitle:String? = nil
    @State var color:String? = nil
    @State var icon:String? = nil

    var body: some View {
        HStack(alignment: .center) {
            Image(icon ?? item.type.icon)
                .font(.system(size: 23, weight: .medium))
                .foregroundColor(self.color == nil ? Color("BatterySubtitle") : Color("BatteryEfficient"))
                .frame(height: 36)
                .padding(.trailing, 6)

            VStack(alignment: .leading) {
                Text(item.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("BatteryTitle"))
                    .padding(0)
                
                if self.hover == true && self.subtitle != nil {
                    Text(self.subtitle ?? "")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color("BatterySubtitle"))
                    
                }
                
            }
            
        }
        .frame(height: 60)
        .padding(.leading, 18)
        .padding(.trailing, 26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(Color("BatteryButton"))
            
        )
        .onAppear() {
            if item.type == .appEfficencyMode {
                self.color = self.battery.saver == .efficient ? "BatteryEfficient" : nil
                self.subtitle = self.battery.saver == .efficient ? "SettingsEnabledLabel".localise() : "SettingsDisabledLabel".localise()

            }
            else if item.type == .appPinned {
                self.subtitle = self.settings.pinned.subtitle
                self.icon = self.settings.pinned.icon

            }
            else if item.type == .appUpdateCheck {
                self.subtitle = self.updates.state.subtitle(updates.checked)
                
            }
            else if item.type == .customiseDisplay {
                self.subtitle = self.settings.enabledDisplay(false).type
                self.icon = self.settings.enabledDisplay(false).icon

            }
            else if item.type == .customiseSoundEffects {
                self.subtitle = self.settings.sfx.subtitle
                self.icon = self.settings.sfx.icon

            }
            else if item.type == .customiseCharge {
                self.subtitle = self.settings.charge.subtitle
                self.icon = self.settings.charge.icon

            }
            else if item.type == .customiseMinThreshold {
                self.subtitle = self.settings.minChargeThreshold.subtitle
                self.icon = self.settings.minChargeThreshold.icon

            }
            else if item.type == .customiseMaxThreshold {
                self.subtitle = self.settings.maxChargeThreshold.subtitle
                self.icon = self.settings.maxChargeThreshold.icon

            }

        }
        .onChange(of: self.battery.saver, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                if item.type == .appEfficencyMode {
                    self.color = self.battery.saver == .efficient ? "BatteryEfficient" : nil
                    self.subtitle = self.battery.saver == .efficient ? "SettingsEnabledLabel".localise() : "SettingsDisabledLabel".localise()

                }
                
            }
            
        })
        .onChange(of: self.updates.state, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                if item.type == .appUpdateCheck {
                    self.subtitle = self.updates.state.subtitle(updates.checked)
                    
                }
                
            }
            
        })
        .onChange(of: self.settings.display, perform: { newValue in
            withAnimation(Animation.easeOut.delay(0.1)) {
                if item.type == .customiseDisplay {
                    self.subtitle = newValue.type
                    self.icon = newValue.icon
                    
                }
                
                
            }
            
        })
        .onChange(of: self.settings.sfx, perform: { newValue in
            if item.type == .customiseSoundEffects {
                self.subtitle = self.settings.sfx.subtitle
                self.icon = self.settings.sfx.icon

            }

        })
        .onChange(of: self.settings.pinned, perform: { newValue in
            if item.type == .appPinned {
                self.subtitle = self.settings.pinned.subtitle
                self.icon = self.settings.pinned.icon

            }
            
        })
        .onChange(of: self.settings.charge, perform: { newValue in
            if item.type == .customiseCharge {
                self.subtitle = self.settings.charge.subtitle
                self.icon = self.settings.charge.icon

            }

        })
        .onChange(of: self.settings.minChargeThreshold, perform: { newValue in
            if item.type == .customiseMinThreshold {
                self.subtitle = newValue.subtitle
                self.icon = newValue.icon

            }

        })
        .onChange(of: self.settings.maxChargeThreshold, perform: { newValue in
            if item.type == .customiseMaxThreshold {
                self.subtitle = newValue.subtitle
                self.icon = newValue.icon

            }

        })
        .onTapGesture {
            SettingsManager.shared.settingsAction(item)
            
        }
        .onHover { hover in
            switch hover {
                case true : NSCursor.pointingHand.push()
                default : NSCursor.pop()
                
            }
            
        }
        
    }
    
}

struct SettingsOverlayItem: View {
    @EnvironmentObject var bluetooth:BluetoothManager
    @EnvironmentObject var manager:AppManager

    @State private var item:SettingsActionType
    @State private var icon:String = ""
    @State private var visible:Bool = true
    @State private var timeline = Array<String>()
    @State private var index:Int = 0

    init(_ item:SettingsActionType) {
        self._item = State(initialValue: item)
        
    }
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color("BatteryButton"))
            .frame(width: 60)
            .overlay(
                Image(systemName: self.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color("BatterySubtitle"))
            
            )
            .onAppear() {
                self.index = 0
                self.timeline = self.bluetooth.connected.map({ $0.type.icon })
                
                if self.item == .appQuit {
                    self.icon = "power"
                    
                }
                else {
                    switch self.manager.menu {
                        case .settings : self.icon = self.timeline.index(self.index) ?? "headphones"
                        default : self.icon = "gearshape.fill"
                        
                    }
                    
                }
                

            }
            .onChange(of: self.manager.menu) { newValue in
                if self.item == .appDevices {
                    switch self.manager.menu {
                        case .settings : self.icon = self.timeline.index(self.index) ?? "headphones"
                        default : self.icon = "gearshape.fill"
                        
                    }

                }
                
            }
            .onChange(of: self.bluetooth.connected) { newValue in
                if item == .appDevices {
                    self.timeline = newValue.map({ $0.type.icon })
                    
                }
                
            }
            .onReceive(timer) { _ in
                if item == .appDevices {
                    switch self.timeline.index(self.index) {
                        case nil : self.index = 0
                        default : self.index += 1
                        
                    }
                    
                    if let icon = self.timeline.index(self.index) {
                        withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                            self.icon = icon
                            
                            
                        }
                        
                    }
                   
                }
                
            }
            .onHover { hover in
                switch hover {
                    case true : NSCursor.pointingHand.push()
                    default : NSCursor.pop()
                    
                }
                
            }
            .onTapGesture {
                switch self.item {
                    case .appQuit : SettingsManager.shared.settingsAction(.init(self.item))
                    default : AppManager.shared.appToggleMenu(true)
                    
                }
            
            }

    }
    
}

struct RedesignedSettingsFormView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var updates = UpdateManager.shared
    @ObservedObject var battery = BatteryManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("General").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)) {
                // Launch at Login
                let autoLaunchBinding = Binding<Bool>(
                    get: { settings.enabledAutoLaunch == .enabled },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledAutoLaunch = $0 ? .enabled : .disabled 
                    }
                )
                LabeledContent("Launch at Login") {
                    Toggle("", isOn: autoLaunchBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                // Keep Pinned
                let pinnedBinding = Binding<Bool>(
                    get: { settings.pinned == .enabled },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledPinned = $0 ? .enabled : .disabled 
                    }
                )
                LabeledContent("Keep Pinned to Screen") {
                    Toggle("", isOn: pinnedBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                // Sound Effects
                let sfxBinding = Binding<Bool>(
                    get: { settings.sfx == .enabled },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledSoundEffects = $0 ? .enabled : .disabled 
                    }
                )
                LabeledContent("Play Sound Effects") {
                    Toggle("", isOn: sfxBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
            }
            
            Section(header: Text("Battery Alerts").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)) {
                // Show Complete at 80%
                let chargeBinding = Binding<Bool>(
                    get: { settings.charge == .enabled },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledChargeEighty = $0 ? .enabled : .disabled 
                    }
                )
                LabeledContent("Charge Complete at 80%") {
                    Toggle("", isOn: chargeBinding)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }
                
                // Low battery alert threshold
                let minThresholdBinding = Binding<SettingsMinThreshold>(
                    get: { settings.minChargeThreshold },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledMinThreshold = $0 
                    }
                )
                LabeledContent("Low Battery Alert") {
                    Picker("", selection: minThresholdBinding) {
                        Text("Disabled").tag(SettingsMinThreshold.disabled)
                        Text("10%").tag(SettingsMinThreshold.ten)
                        Text("15%").tag(SettingsMinThreshold.fifteen)
                        Text("20%").tag(SettingsMinThreshold.twenty)
                        Text("25%").tag(SettingsMinThreshold.twentyFive)
                        Text("30%").tag(SettingsMinThreshold.thirty)
                        Text("35%").tag(SettingsMinThreshold.thirtyFive)
                        Text("40%").tag(SettingsMinThreshold.forty)
                        Text("45%").tag(SettingsMinThreshold.fortyFive)
                        Text("50%").tag(SettingsMinThreshold.fifty)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
                
                // Full battery alert threshold
                let maxThresholdBinding = Binding<SettingsMaxThreshold>(
                    get: { settings.maxChargeThreshold },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledMaxThreshold = $0 
                    }
                )
                LabeledContent("Full Battery Alert") {
                    Picker("", selection: maxThresholdBinding) {
                        Text("Disabled").tag(SettingsMaxThreshold.disabled)
                        Text("70%").tag(SettingsMaxThreshold.seventy)
                        Text("75%").tag(SettingsMaxThreshold.seventyFive)
                        Text("80%").tag(SettingsMaxThreshold.eighty)
                        Text("85%").tag(SettingsMaxThreshold.eightyFive)
                        Text("90%").tag(SettingsMaxThreshold.ninety)
                        Text("95%").tag(SettingsMaxThreshold.ninetyFive)
                        Text("100%").tag(SettingsMaxThreshold.hundred)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 120)
                }
            }
            
            Section(header: Text("Appearance").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)) {
                // Theme
                let themeBinding = Binding<SettingsTheme>(
                    get: { settings.theme },
                    set: { 
                        settings.objectWillChange.send()
                        settings.enabledTheme = $0 
                    }
                )
                LabeledContent("App Theme") {
                    Picker("", selection: themeBinding) {
                        Text("System").tag(SettingsTheme.system)
                        Text("Light").tag(SettingsTheme.light)
                        Text("Dark").tag(SettingsTheme.dark)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            

            

            

            
            Section(header: Text("System & Updates").font(.system(size: 11, weight: .bold)).foregroundColor(.secondary)) {
                LabeledContent("App Version") {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("BeteriApp \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                            .font(.system(size: 11, weight: .semibold))
                        Text(updates.state.subtitle(updates.checked))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack(spacing: 12) {
                    Button(action: {
                        SettingsManager.shared.settingsAction(.init(.appUpdateCheck))
                    }) {
                        Text("Check for Updates")
                            .font(.system(size: 11, weight: .medium))
                    }
                    
                    Button(action: {
                        if let url = URL(string: "http://batteryboi.ovatar.io/index?ref=app&modal=donate") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("Support Creator")
                            .font(.system(size: 11, weight: .medium))
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .formStyle(.grouped)
    }
}
