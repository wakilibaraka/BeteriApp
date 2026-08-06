//
//  BBBluetoothView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 9/6/23.
//

import SwiftUI

struct BluetoothIcon: View {
    @State private var item:BluetoothObject?
    @State private var icon:String
    @State private var animation:Namespace.ID
    
    @Binding private var style:RadialStyle

    init(_ item:BluetoothObject?, style:Binding<RadialStyle>, animation:Namespace.ID) {
        self._item = State(initialValue: item)
        self._icon = State(initialValue: item?.type.icon ?? AppManager.shared.appDeviceType.icon)
        self._animation = State(initialValue: animation)
        
        self._style = style

    }
    
    var body: some View {
        HStack {
            ZStack {
                if self.item == nil || self.item?.battery.percent != nil {
                    RadialProgressMiniContainer(self.item, style: $style)
                    
                    Image(systemName: self.icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatterySubtitle"))
                        .padding(2)
                        .background(
                            Circle()
                                .fill(self.style == .light ? Color("BatteryTitle") : Color("BatteryButton"))
                                .blur(radius: 2)
                            
                        )
                        .matchedGeometryEffect(id: self.icon, in: animation)
                        .offset(x:12, y:12)
                    
                }
                else {
                    Image(systemName: self.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatterySubtitle"))
                        .padding(2)
                        .matchedGeometryEffect(id: item?.type.icon ?? "laptopcomputer", in: animation)
                    
                }

            }
            
            Spacer().frame(width:18)
            
        }
        
    }
    
}

struct BluetoothItem: View {
    @EnvironmentObject var manager:AppManager
    @EnvironmentObject var battery:BatteryManager

    @Binding var hover:Bool

    @State var item:BluetoothObject?
    @State var style:RadialStyle = .light

    @Namespace private var animation
    
    init(_ item:BluetoothObject?, hover:Binding<Bool>) {
        self._item = State(initialValue: item)
        self._hover = hover
        
    }

    var body: some View {
        HStack(alignment: .center) {
            BluetoothIcon(item, style: $style, animation: animation)

            VStack(alignment: .leading) {
                if let item = self.item {
                    Text(item.device ?? item.type.type.rawValue)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatteryTitle"))
                        .padding(0)
                    
                    HStack {
                        if self.hover == true {
                            if item.connected == .disconnected {
                                Text("BluetoothDisconnectedLabel".localise())
                        
                            }
                            else {
                                if let percent = item.battery.percent {
                                    Text("AlertSomePercentTitle".localise([Int(percent)]))
                                    
                                }
                                else {
                                    Text("BluetoothInvalidLabel".localise())
                                        
                                }
                                
                            }
                            
                        }
                        
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color("BatterySubtitle"))
                    
                }
                else {
                    Text(AppManager.shared.appDeviceType.name)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(self.style == .light ? Color("BatteryButton") : Color("BatteryTitle"))
                        .padding(0)
                    
                    if self.hover == true {
                        Text("AlertSomePercentTitle".localise([Int(battery.percentage)]))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color("BatterySubtitle"))
                        
                    }
                    
                }
                
            }
                                    
        }
        .frame(height: 60)
        .padding(.leading, 16)
        .padding(.trailing, 26)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous).fill(self.style == .light ? Color("BatteryTitle") : Color("BatteryButton"))
            
        )
        .onTapGesture {
            withAnimation(Animation.easeOut) {
                self.manager.device = item
                
            }
            
        }
        .onHover { hover in
            switch hover {
                case true : NSCursor.pointingHand.push()
                default : NSCursor.pop()
                
            }
            
        }
        .onChange(of: manager.device) { newValue in
            withAnimation(Animation.easeOut) {
                if newValue == item {
                    self.style = .light
                    
                }
                else {
                    self.style = .dark
                    
                }
                
            }
            
        }
        .onAppear() {
            if AppManager.shared.device == item {
                self.style = .light
                
            }
            else {
                self.style = .dark

            }
            
        }
        
    }
    
}

struct DeviceCardView: View {
    @ObservedObject var appManager = AppManager.shared
    let device: BluetoothObject
    
    var body: some View {
        let percent = device.battery.percent ?? 0
        let isLowBattery = percent < 20
        let isSelected = appManager.device == device
        
        HStack(spacing: 8) {
            // Exact SF Symbol
            Image(systemName: device.type.icon.isEmpty ? "headphones" : device.type.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isLowBattery ? .orange : .primary.opacity(0.8))
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.04))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(device.device ?? device.type.type.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                // Color-coded battery bar
                GeometryReader { geo in
                    let pct = CGFloat(percent) / 100.0
                    let barColor: Color = {
                        if pct < 0.2 { return .red }
                        if pct < 0.5 { return .orange }
                        return .green
                    }()
                    
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.primary.opacity(0.08))
                        
                        Capsule()
                            .fill(barColor)
                            .frame(width: max(0, min(geo.size.width * pct, geo.size.width)))
                    }
                }
                .frame(height: 4)
            }
            
            Spacer()
            
            // Clean percentage badge
            Text("\(Int(percent))%")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(isLowBattery ? .orange : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(isLowBattery ? Color.orange.opacity(0.12) : Color.primary.opacity(0.05))
                .cornerRadius(6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isSelected ? Color.primary.opacity(0.08) : Color.primary.opacity(0.03))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isLowBattery ? Color.orange.opacity(0.4) : (isSelected ? Color.primary.opacity(0.15) : Color.clear), lineWidth: 1.5)
        )
        .onTapGesture {
            withAnimation(.easeOut) {
                if appManager.device == device {
                    appManager.device = nil
                } else {
                    appManager.device = device
                }
            }
        }
    }
}
