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

// MARK: - Live Battery Stats Panel (used in DetailedPanelView)

struct BatteryStatsPanel: View {
    @ObservedObject var battery = BatteryManager.shared

    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    @State private var powerDraw: Double = 0
    @State private var temperature: Double = 0
    @State private var health: Double = 0
    @State private var cycles: String = "—"
    @State private var condition: String = "—"

    var body: some View {
        HStack(spacing: 8) {
            statCell(icon: "bolt.fill",          label: "Draw",   value: powerDraw > 0   ? String(format: "%.1fW",  powerDraw)   : "—", color: .yellow)
            statCell(icon: "thermometer",         label: "Temp",   value: temperature > 0 ? String(format: "%.0f°C", temperature) : "—", color: temperature > 40 ? .orange : .green)
            statCell(icon: "heart.fill",          label: "Health", value: health > 0      ? String(format: "%.0f%%", health)       : "—", color: health > 80 ? .green : health > 60 ? .orange : .red)
            statCell(icon: "arrow.2.circlepath",  label: "Cycles", value: cycles,                                                         color: .blue)
            statCell(icon: "checkmark.seal.fill", label: "State",  value: condition,                                                       color: condition == "Normal" ? .green : .orange)
        }
        .onAppear { refresh() }
        .onReceive(timer) { _ in refresh() }
    }

    @ViewBuilder
    private func statCell(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
    }

    private func refresh() {
        powerDraw   = battery.currentPowerDraw
        temperature = battery.batteryTemperature
        health      = battery.batteryHealthPercent
        cycles      = battery.metrics?.cycles.formatted ?? "—"
        condition   = battery.metrics?.heath.rawValue   ?? "—"
    }
}

// MARK: - Settings Form

struct RedesignedSettingsFormView: View {
    @ObservedObject var settings = SettingsManager.shared
    @ObservedObject var updates  = UpdateManager.shared
    @ObservedObject var battery  = BatteryManager.shared

    @State private var showAdvanced = false

    var body: some View {
        Form {

            // MARK: Primary — always visible
            Section(header: Text("General")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)) {

                LabeledContent("Launch at Login") {
                    Toggle("", isOn: Binding(
                        get: { settings.enabledAutoLaunch == .enabled },
                        set: {
                            settings.enabledAutoLaunch = $0 ? .enabled : .disabled
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                LabeledContent("Track Bluetooth Devices") {
                    Toggle("", isOn: Binding(
                        get: { settings.enabledBluetoothStatus == .enabled },
                        set: {
                            settings.objectWillChange.send()
                            settings.enabledBluetoothStatus = $0 ? .enabled : .disabled
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                LabeledContent("Optimize Charging at 80%") {
                    Toggle("", isOn: Binding(
                        get: { settings.charge == .enabled },
                        set: {
                            settings.objectWillChange.send()
                            settings.enabledChargeEighty = $0 ? .enabled : .disabled
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }

            Section(header: Text("Menu Bar")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)) {

                LabeledContent("Display") {
                    Picker("", selection: Binding(
                        get: { settings.display },
                        set: { newDisplay in
                            settings.display = newDisplay   // update @Published immediately
                            UserDefaults.save(.enabledDisplay, value: newDisplay.rawValue)
                        }
                    )) {
                        Text("Time Remaining").tag(SettingsDisplayType.countdown)
                        Text("Percentage").tag(SettingsDisplayType.percent)
                        Text("Cycle Count").tag(SettingsDisplayType.cycle)
                        Text("Nothing").tag(SettingsDisplayType.empty)
                        Text("Hidden").tag(SettingsDisplayType.hidden)
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 150)
                }

                LabeledContent("Theme") {
                    Picker("", selection: Binding(
                        get: { settings.theme },
                        set: { newTheme in
                            settings.theme = newTheme       // fix: update @Published immediately
                            settings.enabledTheme = newTheme
                        }
                    )) {
                        Text("System").tag(SettingsTheme.system)
                        Text("Light").tag(SettingsTheme.light)
                        Text("Dark").tag(SettingsTheme.dark)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }

            // MARK: Advanced — behind gear icon disclosure
            Section {
                DisclosureGroup(
                    isExpanded: $showAdvanced,
                    content: {
                        // Sound Effects
                        LabeledContent("Sound Effects") {
                            Toggle("", isOn: Binding(
                                get: { settings.sfx == .enabled },
                                set: {
                                    settings.objectWillChange.send()
                                    settings.enabledSoundEffects = $0 ? .enabled : .disabled
                                }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }
                        .padding(.top, 4)

                        // Keep Pinned
                        LabeledContent("Keep Pinned") {
                            Toggle("", isOn: Binding(
                                get: { settings.pinned == .enabled },
                                set: {
                                    settings.objectWillChange.send()
                                    settings.enabledPinned = $0 ? .enabled : .disabled
                                }
                            ))
                            .toggleStyle(.switch)
                            .labelsHidden()
                        }

                        // Low Power Mode
                        LabeledContent("Low Power Mode") {
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(battery.saver == .efficient ? Color.green : Color.secondary.opacity(0.35))
                                    .frame(width: 7, height: 7)
                                Text(battery.saver == .efficient ? "Active" : battery.saver == .unavailable ? "N/A" : "Off")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                if battery.saver != .unavailable {
                                    Button(battery.saver == .efficient ? "Disable" : "Enable") {
                                        BatteryManager.shared.powerSaveMode()
                                    }
                                    .buttonStyle(.plain)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                }
                            }
                        }

                        // Low Battery Alert
                        LabeledContent("Low Battery Alert") {
                            Picker("", selection: Binding(
                                get: { settings.minChargeThreshold },
                                set: {
                                    settings.objectWillChange.send()
                                    settings.enabledMinThreshold = $0
                                }
                            )) {
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
                            .frame(width: 110)
                        }

                        // Full Battery Alert
                        LabeledContent("Full Battery Alert") {
                            Picker("", selection: Binding(
                                get: { settings.maxChargeThreshold },
                                set: {
                                    settings.objectWillChange.send()
                                    settings.enabledMaxThreshold = $0
                                }
                            )) {
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
                            .frame(width: 110)
                        }

                        // App Version + actions
                        LabeledContent("Version") {
                            VStack(alignment: .trailing, spacing: 3) {
                                Text("BeteriApp \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                                    .font(.system(size: 10, weight: .semibold))
                                Text(updates.state.subtitle(updates.checked))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                        }

                        HStack(spacing: 10) {
                            Button("Check Updates") {
                                SettingsManager.shared.settingsAction(.init(.appUpdateCheck))
                            }
                            .font(.system(size: 10, weight: .medium))

                            Button("Support") {
                                if let url = URL(string: "https://batteryboi.ovatar.io/index?ref=app&modal=donate") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .font(.system(size: 10, weight: .medium))

                            Spacer()

                            Button("Quit") {
                                SettingsManager.shared.settingsAction(.init(.appQuit))
                            }
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.red)
                        }
                        .padding(.vertical, 2)
                    },
                    label: {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text("Advanced Settings")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                )
            }
        }
        .formStyle(.grouped)
    }
}

