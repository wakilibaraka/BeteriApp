//
//  BatteryHeroView.swift
//  BatteryBoi
//
//  Created by Antigravity on 8/5/26.
//

import SwiftUI

struct BatteryHeroView: View {
    @ObservedObject var battery = BatteryManager.shared
    
    @State private var boltOpacity: Double = 0.5
    @State private var boltScale: CGFloat = 0.9
    
    private var ringColor: [Color] {
        let pct = battery.percentage
        if pct < 20 { return [Color.red, Color.orange] }
        if pct < 50 { return [Color.orange, Color.yellow] }
        return [Color.green, Color.cyan, Color.blue]
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
                    .animation(.spring(response: 0.8, dampingFraction: 0.8), value: battery.percentage)
                
                VStack(spacing: 2) {
                    Text("\(Int(battery.percentage))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    if battery.charging.state == .charging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: Color.yellow.opacity(0.3), radius: 2, x: 0, y: 1)
                            .scaleEffect(boltScale)
                            .opacity(boltOpacity)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                    boltOpacity = 1.0
                                    boltScale = 1.15
                                }
                            }
                    }
                }
            }
            .frame(width: 90, height: 90)
            

            
            // Power metrics row
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.horizontal.fill")
                        .font(.system(size: 10))
                    Text(String(format: "%.1f W", battery.currentPowerDraw))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.secondary)
                
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
                        .foregroundColor(temp > 38 ? .orange : .secondary.opacity(0.8))
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
                }
                
                // Time remaining
                if let remaining = battery.remaining, let formatted = remaining.formatted {
                    Text(formatted)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                } else if battery.charging.state == .charging {
                    Text("Charging...")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
            .padding(.top, 2)
            
        }
    }
}
