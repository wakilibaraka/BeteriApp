//
//  BBNetworkManager.swift
//  BatteryBoi
//
//  Created by AI on 8/7/26.
//

import Foundation
import CoreWLAN
import Combine

class NetworkManager: ObservableObject {
    static var shared = NetworkManager()
    
    @Published var wifiDevice: BluetoothObject?
    
    private var timer: Timer?
    
    init() {
        self.updateWiFiStatus()
        self.timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.updateWiFiStatus()
        }
    }
    
    private func updateWiFiStatus() {
        if let interface = CWWiFiClient.shared().interface(),
           let ssid = interface.ssid(),
           let bssid = interface.bssid() {
            
            let rssi = Double(interface.rssiValue())
            
            var distance: BluetoothDistanceType = .unknown
            if rssi >= -50 && rssi <= -20 {
                distance = .proximate
            } else if rssi >= -70 && rssi < -50 {
                distance = .near
            } else if rssi < -70 {
                distance = .far
            }
            
            // We use 'other' type but give it a wifi icon
            var type = BluetoothDeviceObject("other", subtype: nil, vendor: nil)
            type.icon = "wifi"
            
            let battery = BluetoothBatteryObject(general: nil, left: nil, right: nil, percent: nil)
            
            let device = BluetoothObject(
                address: bssid.lowercased().replacingOccurrences(of: ":", with: "-"),
                firmware: nil,
                battery: battery,
                type: type,
                distance: distance,
                updated: Date(),
                device: ssid,
                connected: .connected
            )
            
            DispatchQueue.main.async {
                self.wifiDevice = device
            }
        } else {
            DispatchQueue.main.async {
                self.wifiDevice = nil
            }
        }
    }
}
