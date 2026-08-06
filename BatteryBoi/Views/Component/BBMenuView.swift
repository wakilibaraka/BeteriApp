//
//  MenuView.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import SwiftUI
import Combine

enum BatteryStyle:String {
    case chunky
    case basic
    
    var radius:CGFloat {
        switch self {
            case .basic : return 3
            case .chunky : return 5
            
        }
        
    }
    
    var size:CGSize {
        switch self {
            case .basic : return .init(width: 28, height: 13)
            case .chunky : return .init(width: 32, height: 15)
            
        }
        
    }
    
    var padding:CGFloat {
        switch self {
            case .basic : return 1
            case .chunky : return 2
            
        }
        
    }
    
}

enum BatteryAnimationType {
    case charging
    case low
    
}

public struct BatteryPulsatingIcon: View {
    @EnvironmentObject var manager:BatteryManager

    @State private var visible:Bool = false
    @State private var icon:String = "ChargingIcon"
    
    init(_ icon:String) {
        self._icon = State(initialValue: icon)
        
    }
    
    public var body: some View {
        Rectangle()
            .fill(Color.black)
            .mask(
               Image(icon)
                   .resizable()
                   .aspectRatio(contentMode: .fit)
            
            )
            .frame(width: 5, height: 8)
            .onAppear() {
                withAnimation(Animation.easeInOut) {
                    self.visible = true
                    
                }
            }
            .offset(y:0.4)
            .opacity(self.visible ? 1.0 : 0.0)
            .onChange(of: self.visible) { newValue in
                DispatchQueue.main.asyncAfter(deadline: .now() + (self.visible ? 2.0 : 0.8)) {
                    withAnimation(Animation.easeInOut) {
                        self.visible.toggle()
    
                    }
    
                }
    
            }
           
    }
    
}




public struct BatteryMask: Shape {
    private var radius:CGFloat

    init(_ value: CGFloat) {
        self.radius = value
        
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width - self.radius, y: 0))
        path.addQuadCurve(to: CGPoint(x: rect.width, y: self.radius), control: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - self.radius))
        path.addQuadCurve(to: CGPoint(x: rect.width - self.radius, y: rect.height), control: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: 0))

        return path
        
    }
    
}

private struct BatteryStatus: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var stats:StatsManager

    @State private var size:CGSize
    @State private var font:CGFloat
    @State private var icon:String? = nil

    @Binding private var hover:Bool
    
    init(_ size:CGSize, font:CGFloat, hover:Binding<Bool>) {
        self._size = State(initialValue: size)
        self._font = State(initialValue: font)
        self._hover = hover
        
    }

    var body: some View {
        ZStack {
            if let overlay = self.stats.overlay {
                Text(overlay).style(self.font).offset(y:self.hover ? 0.0 : -self.size.height)
                
            }

            HStack(alignment: .center, spacing:0.4) {
                if let icon = self.icon {
                    BatteryPulsatingIcon(icon)
                    
                }
                
                if let summary = self.stats.display {
                    Text(summary).style(self.font)
                    
                }
                
            }
            .offset(y:self.hover ? self.size.height : 0.0)
            .foregroundColor(Color.black)
            .frame(width: self.size.width, height: self.size.height)
            
        }
        .onAppear() {
            if self.manager.charging.state == .charging && self.manager.percentage != 100 {
                self.icon = "ChargingIcon"
                
            }
            else {
                self.icon = nil

            }
            
        }
        .onChange(of: manager.charging) { newValue in
            if newValue.state == .charging && self.manager.percentage != 100 {
                self.icon = "ChargingIcon"
                
            }
            else {
                self.icon = nil

            }
            
        }
        .onChange(of: manager.percentage) { newValue in
            if self.manager.charging.state == .charging && newValue != 100 {
                self.icon = "ChargingIcon"

            }
            else {
                self.icon = nil

            }
            
        }
        .frame(alignment: .center)
        .foregroundColor(Color.black)
        .animation(Animation.easeInOut, value: self.manager.charging)

    }
    
}

private struct BatteryStub: View {
    @State private var proxy:GeometryProxy
    @State private var size:CGSize

    init(_ proxy: GeometryProxy, size:CGSize) {
        self._proxy = State(initialValue: proxy)
        self._size = State(initialValue: size)
        
    }
    
    var body: some View {
        ZStack {
            BatteryMask(3.4).foregroundColor(Color("BatteryDefault"))

        }
        .position(x:proxy.size.width + 2, y:proxy.size.height / 2)
        .frame(width: 1.6, height: 6)
        .opacity(0.6)

    }
    
}

struct BatteryIcon: View {
    @EnvironmentObject var manager:BatteryManager
    
    @State var size:CGSize
    @State var radius:CGFloat = 25
    @State var max:CGFloat = 25
    @State var font:CGFloat
    @State var padding:CGFloat
    @State var progress:CGFloat
    
    @Binding var hover:Bool

    init(_ size: CGSize, radius: CGFloat, font:CGFloat, hover:Binding<Bool>) {
        self._size = State(initialValue: size)
        self._radius = State(initialValue: radius)
        self._max = State(initialValue: radius)
        self._font = State(initialValue: font)
        self._padding = State(initialValue: 1.6)
        self._progress = State(initialValue: 1.0)
        self._hover = hover

    }
    
    var batteryColor: Color {
        return .primary
    }

    var body: some View {
        ZStack {
            HStack(alignment: .center) {
                Rectangle()
                    .frame(width: self.progress, alignment: .leading)
                    .clipShape(BatteryMask(3.4))
    
            }
            .frame(maxWidth: self.size.width, alignment: .leading)
            .foregroundColor(self.batteryColor)
            .overlay(
                BatteryStatus(size, font: font, hover: $hover)
             
            )
                        
        }
        .animation(.linear, value: self.manager.percentage)
        .inverse(
            BatteryStatus(size, font: font, hover: $hover).mask(
                Rectangle()
                    .fill(.black)
                    .frame(width: self.size.width)
                    .position(x: -(self.size.width / 2) + (self.progress + 2.0), y: self.size.height / 2)

            )
            
        )
        .clipShape(RoundedRectangle(cornerRadius: self.radius - self.padding, style: .continuous))
        .padding(self.padding)
        .onChange(of: self.manager.charging.state, perform: { newValue in
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                self.progress = newValue.progress(self.manager.percentage, width: self.size.width)
                
            }
            
        })
        .onChange(of: self.manager.percentage, perform: { newValue in
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                self.progress = self.manager.charging.state.progress(newValue, width: self.size.width)
                
            }
          
        })
        .onAppear() {
            withAnimation(.interactiveSpring(response: 0.6, dampingFraction: 0.9, blendDuration: 1)) {
                self.progress = self.manager.charging.state.progress(self.manager.percentage, width: self.size.width)
                
            }
            
        }
       

    }
    
}

struct BatteryContainer: View {
    @EnvironmentObject var manager:BatteryManager
    @EnvironmentObject var updates:UpdateManager
    @EnvironmentObject var stats:StatsManager

    @State private var size:CGSize
    @State private var radius:CGFloat
    @State private var font:CGFloat
    @State private var hover:Bool = false

    init(_ size: CGSize, radius:CGFloat, font:CGFloat) {
        self._size = State(initialValue: size)
        self._radius = State(initialValue: radius)
        self._font = State(initialValue: font)

    }
    
    var body: some View {
        ZStack {
            // Draw the colored inner fill directly
            BatteryIcon(self.size, radius: self.radius, font: self.font, hover: self.$hover)
            
            // Draw the outer border and empty space (with a hole punched out for the fill)
            RoundedRectangle(cornerRadius: self.radius, style: .continuous)
                .fill(Color("BatteryDefault"))
                .opacity(0.9)
                .frame(width:self.size.width, height: self.size.height)
                .mask(
                    Rectangle().inverse(BatteryIcon(self.size, radius: self.radius, font: self.font, hover: self.$hover))
                )

        }
        .onHover { hover in
            if self.stats.overlay != nil {
                withAnimation(Animation.easeOut(duration: 0.3).delay(self.hover ? 0.8 : 0.1)) {
                    self.hover = hover
                    
                }
                
            }
            
        }
        .onChange(of: self.manager.charging, perform: { newValue in
            if newValue.state == .charging && self.hover == true {
                withAnimation(Animation.easeOut(duration: 0.3)) {
                    self.hover = false
                    
                }
            
            }
            
        })
        .overlay(
            GeometryReader { geo in
                if let _ = self.updates.available {
                    Circle()
                        .fill(Color("BatteryEfficient"))
                        .frame(width: 5, height: 5)
                        .position(x:-5, y: (geo.size.height / 2) + 0.5)
                    
                }
                
                BatteryStub(geo, size: .init(width: 4, height: size.height / 2))
                
            }
            
        )
        
    }
    
}

struct MenuContainer: View {
    @StateObject var manager = BatteryManager.shared
    @StateObject var updates = UpdateManager.shared

    var body: some View {
        HStack(spacing: 5) {
            // Battery Icon (Samsung Style)
            HStack(spacing: 1.5) {
                ZStack(alignment: .center) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .stroke(Color.primary.opacity(0.6), lineWidth: 1.2)
                            .frame(width: 22, height: 12)
                        
                        let batteryColor: Color = {
                            if manager.percentage > 30 { return .green }
                            if manager.percentage > 10 { return .yellow }
                            return .red
                        }()
                        
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(batteryColor)
                            .frame(width: max(0, min(18, 18 * (manager.percentage / 100))), height: 8)
                            .padding(.leading, 2)
                    }
                    
                    // Charging Bolt Overlay
                    if manager.charging.state == .charging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(Color(NSColor.windowBackgroundColor))
                    }
                }
                
                // Terminal Tip
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.primary.opacity(0.6))
                    .frame(width: 1.5, height: 4)
            }
            .overlay(
                Group {
                    if let _ = updates.available {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 4, height: 4)
                            .offset(x: -4, y: -8)
                    }
                }, alignment: .topLeading
            )
            
            // Percentage Text
            Text("\(Int(manager.percentage))%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .offset(y: -0.5)
        }
        .frame(maxHeight: .infinity)
    }
}

class ClickThroughHostingView<Content: View>: NSHostingView<Content> {
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

struct MenuViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> ClickThroughHostingView<MenuContainer> {
        let hostingView = ClickThroughHostingView(rootView: MenuContainer())
        hostingView.frame.size = NSSize(width: 100, height: 20)
        return hostingView
    }

    func updateNSView(_ nsView: ClickThroughHostingView<MenuContainer>, context: Context) {
    }
}
