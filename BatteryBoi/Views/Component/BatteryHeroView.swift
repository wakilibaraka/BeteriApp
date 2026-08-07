//
//  BatteryHeroView.swift
//  BatteryBoi
//
//  Created by Antigravity on 8/5/26.
//

import SwiftUI

struct BatteryHeroView: View {
    @EnvironmentObject var battery: BatteryManager
    
    @State private var boltOpacity: Double = 0.5
    @State private var boltScale: CGFloat = 0.9
    
    private var ringColor: [Color] {
        let pct = battery.percentage
        if pct < 20 { return [Color.red, Color.orange] }
        if pct < 50 { return [Color.orange, Color.yellow] }
        if pct >= 100 { return [Color.green, Color.teal] }
        return [Color.green, Color.cyan, Color.blue]
    }
    
    /// Returns a human-readable status label shown below the ring
    private var statusLabel: String {
        let isCharging = battery.charging.state == .charging
        let pct = Int(battery.percentage)
        
        if pct >= 100 && isCharging {
            return "Full"
        }
        if isCharging {
            // Show time until full if available
            if battery.powerIsCalculating {
                return "Calculating..."
            }
            if let fullDate = battery.powerUntilFull {
                let mins = Int(fullDate.timeIntervalSinceNow / 60)
                if mins <= 0 { return "Full" }
                let h = mins / 60, m = mins % 60
                if h > 0 && m > 0 { return "\(h)h \(m)m to full" }
                if h > 0 { return "\(h)h to full" }
                return "\(m)m to full"
            }
            return "Charging..."
        }
        // On battery — check optimized hold (plugged in but not charging)
        if let sourceState = nil as String?, sourceState == "AC Power" {
            return "Optimized (on hold)"
        }
        // Time remaining on battery
        if let remaining = battery.remaining, let formatted = remaining.formatted {
            return formatted
        }
        if battery.powerIsCalculating {
            return "Calculating..."
        }
        return ""
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 8)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(battery.percentage / 100.0, 0.0), 1.0)))
                    .stroke(
                        LinearGradient(colors: ringColor, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: battery.percentage)
                
                VStack(spacing: 2) {
                    Text("\(Int(battery.percentage))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.3), value: battery.percentage)
                    
                    if battery.charging.state == .charging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: Color.yellow.opacity(0.4), radius: 3, x: 0, y: 0)
                            .scaleEffect(boltScale)
                            .opacity(boltOpacity)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                                    boltOpacity = 1.0
                                    boltScale = 1.1
                                }
                            }
                    }
                }
            }
            .frame(width: 90, height: 90)
            
            // Power draw row
            VStack(spacing: 3) {
                let watts = battery.currentPowerDraw
                if watts > 0.1 {
                    HStack(spacing: 4) {
                        Image(systemName: battery.charging.state == .charging ? "bolt.fill" : "bolt.horizontal.fill")
                            .font(.system(size: 9))
                        Text(String(format: "%.1f W", watts))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(battery.charging.state == .charging ? .yellow.opacity(0.9) : .secondary)
                    .animation(.easeOut(duration: 0.3), value: battery.charging.state == .charging)
                }
                
                // Temperature & health row
                HStack(spacing: 8) {
                    let temp = battery.batteryTemperature
                    if temp > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "thermometer.medium")
                                .font(.system(size: 9))
                            Text(String(format: "%.0f°C", temp))
                                .font(.system(size: 10))
                        }
                        .foregroundColor(temp > 40 ? .orange : .secondary.opacity(0.8))
                    }
                    
                    let health = battery.batteryHealthPercent
                    if health < 100 {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                            Text(String(format: "%.0f%%", health))
                                .font(.system(size: 10))
                        }
                        .foregroundColor(health < 80 ? .orange : .secondary.opacity(0.8))
                    }
                    
                    // Cycle count
                    if let cycles = battery.metrics?.cycles.formatted {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.trianglehead.2.clockwise")
                                .font(.system(size: 9))
                            Text(cycles)
                                .font(.system(size: 10))
                        }
                        .foregroundColor(.secondary.opacity(0.7))
                    }
                }
                
                // Status label (time remaining / charging status)
                let label = statusLabel
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                        .transition(.opacity)
                        .animation(.easeOut(duration: 0.3), value: label)
                }
            }
            .padding(.top, 2)
        }
    }
}
