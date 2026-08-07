//
//  BatteryManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/4/23.
//

import Foundation
import Combine
import IOKit.ps
import EnalogSwift
import IOKit.pwr_mgt

enum BatteryWattageType {
    case current
    case max
    case voltage
    
}

enum BatteryThemalState {
    case optimal
    case suboptimal
    
}

enum BatteryCondition: String {
    case optimal = "Normal"
    case suboptimal = "Replace Soon"
    case malfunctioning = "Service Battery"
    case unknown = "Unknown"
    
}

struct BatteryCycleObject {
    var numerical:Int
    var formatted:String
    
    init(_ count:Int) {
        self.numerical = count
        
        if count > 999 {
            let divisor = pow(10.0, Double(1))
            let string = ((Double(count) / 1000.0) * divisor).rounded() / divisor

            self.formatted = "\(string)k"
            
        }
        else {
            self.formatted = "\(Int(count))"

        }
        
    }
    
}

struct BatteryMetricsObject {
    var cycles:BatteryCycleObject
    var heath:BatteryCondition
    
    init(cycles:String, health:String) {
        self.cycles = BatteryCycleObject(Int(cycles) ?? 0)
        self.heath = BatteryCondition(rawValue: health) ?? .optimal
        
    }
    
}

enum BatteryModeType {
    case normal
    case efficient
    case unavailable
    
    var flag:Bool {
        switch self {
            case .normal : return false
            case .efficient : return true
            case .unavailable : return false
            
        }
        
    }
    
}

enum BatteryChargingState {
    case charging
    case battery
    
    public var charging:Bool {
        switch self {
            case .charging : return true
            case .battery : return false
            
        }
        
    }
    
    public func progress(_ percent:Double, width:CGFloat) -> CGFloat {
        if self == .charging {
            return min(100 * (width - 2.6), (width - 2.6))
            
        }
        else {
            if percent > 0 && percent < 10 {
                return min(CGFloat(10 / 100) * (width - 2.6), (width - 2.6))

            }
            else if percent >= 90 && percent < 100 {
                return min(CGFloat(90 / 100) * (width - 2.6), (width - 2.6))

            }
            else {
                return min(CGFloat(percent / 100) * (width - 2.6), (width - 2.6))
                
            }
            
        }
        
    }
    
}

struct BatteryCharging:Equatable {
    var state:BatteryChargingState
    var started:Date?
    var ended:Date?
    
    init(_ charging:BatteryChargingState) {
        self.state = charging
        
        switch charging {
            case .charging : self.started = Date()
            case .battery : self.ended = Date()

        }
        
    }
    
}

struct BatteryRemaining:Equatable {
    static func == (lhs: BatteryRemaining, rhs: BatteryRemaining) -> Bool {
        return lhs.date == rhs.date
        
    }
    
    var date:Date
    var hours:Int? = nil
    var minutes:Int? = nil
    var formatted:String?
    
    init(hour: Int, minute:Int) {
        self.hours = hour
        self.minutes = minute
        self.date = Date(timeIntervalSinceNow: 60*2)

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        if let date = Calendar.current.date(byAdding: components, to: Date()) {
            let units = Calendar.current.dateComponents([.minute, .hour], from: Date(), to: date)
            
            if let hours = units.hour, let minutes = units.minute {
                if hours == 0 && minutes == 0 {
                    self.formatted = "AlertDeviceCalculatingTitle".localise()
                    
                }
                else if hours != 0 && minutes != 0 {
                    self.formatted = "\("TimestampHourFullLabel".localise([hours]))  \("TimestampMinuteFullLabel".localise([minutes]))"
                    
                }
                else if hours == 0 {
                    self.formatted = "TimestampMinuteFullLabel".localise([minutes])
                    
                }
                else if minute == 0 {
                    self.formatted = "TimestampHourFullLabel".localise([hour])
                    
                }
                
            }
            
            self.date = date

        }
        
    }
    
}

struct BatteryEstimateObject {
    var timestamp:Date
    var percent:Double
    
    init(_ percent: Double) {
        self.timestamp = Date()
        self.percent = percent
        
    }
    
}

class BatteryManager:ObservableObject {
    static var shared = BatteryManager()
    
    @Published var charging:BatteryCharging = .init(.battery)
    @Published var percentage:Double = 100
    @Published var remaining:BatteryRemaining? = nil
    @Published var mode:Bool = false
    @Published var saver:BatteryModeType = .unavailable
    @Published var rate:BatteryEstimateObject? = nil
    @Published var metrics:BatteryMetricsObject? = nil
    @Published var thermal:BatteryThemalState = .optimal

    private var counter:Int? = 0
    private var updates = Set<AnyCancellable>()
    private var runLoopSource: CFRunLoopSource?

    init() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let loopSource = IOPSNotificationCreateRunLoopSource({ (context) in
            if let ctx = context {
                let manager = Unmanaged<BatteryManager>.fromOpaque(ctx).takeUnretainedValue()
                manager.powerStatus(true)
                manager.remaining = manager.powerRemaing
            }
        }, context).takeRetainedValue()
        
        self.runLoopSource = loopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), loopSource, .defaultMode)
        
        #if DEBUG
            AppManager.shared.appTimer(90).sink { _ in
                self.powerThermalCheck()
             
            }.store(in: &updates)
        #endif
        
        AppManager.shared.appTimer(60).sink { _ in
            self.saver = self.powerSaveModeStatus
            self.metrics = self.powerProfilerDetails

        }.store(in: &updates)
        
        self.powerStatus(true)
        self.remaining = self.powerRemaing
    
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
        self.updates.forEach { $0.cancel() }
        
    }
    
    public func powerForceRefresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.powerStatus(true)
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.saver = self.powerSaveModeStatus
            self.metrics = self.powerProfilerDetails
            
        }
        
    }
    
    // Fallback removed in favor of native IOKit runloop
    
    private func powerStatus(_ force:Bool = false) {
        if force == true {
            let oldPercentage = self.percentage
            self.percentage = self.powerPercentage

            if self.powerCharging != self.charging.state {
                let newState = self.powerCharging
                self.charging = .init(newState)
                
                DispatchQueue.main.async {
                    if newState == .charging {
                        WindowManager.shared.windowOpen(.chargingBegan, device: nil)
                    } else {
                        WindowManager.shared.windowOpen(.chargingStopped, device: nil)
                    }
                }
            }
            
            if oldPercentage != self.percentage {
                DispatchQueue.main.async {
                    if self.charging.state == .battery {
                        if oldPercentage > 25.0 && self.percentage <= 25.0 {
                            WindowManager.shared.windowOpen(.percentTwentyFive, device: nil)
                        } else if oldPercentage > 10.0 && self.percentage <= 10.0 {
                            WindowManager.shared.windowOpen(.percentTen, device: nil)
                        } else if oldPercentage > 5.0 && self.percentage <= 5.0 {
                            WindowManager.shared.windowOpen(.percentFive, device: nil)
                        } else if oldPercentage > 1.0 && self.percentage <= 1.0 {
                            WindowManager.shared.windowOpen(.percentOne, device: nil)
                        }
                        
                        let minThresh = Double(SettingsManager.shared.enabledMinThreshold.rawValue)
                        if oldPercentage > minThresh && self.percentage <= minThresh {
                            WindowManager.shared.windowOpen(.percentMinThreshold, device: nil)
                        }
                    } else if self.charging.state == .charging {
                        let maxThresh = Double(SettingsManager.shared.enabledMaxThreshold.rawValue)
                        if oldPercentage < maxThresh && self.percentage >= maxThresh {
                            WindowManager.shared.windowOpen(.percentMaxThreshold, device: nil)
                        }
                        if oldPercentage < 100.0 && self.percentage >= 100.0 {
                            WindowManager.shared.windowOpen(.chargingComplete, device: nil)
                        }
                    }
                }
            }
            
        }
        
    }
    
    private var powerCharging:BatteryChargingState {
        if self.powerIsCharging {
            return .charging
        } else {
            return .battery
        }
    }

    private var powerPercentage:Double {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                
                if description["Type"] as? String == kIOPSInternalBatteryType {
                    return description[kIOPSCurrentCapacityKey] as? Double ?? 0.0
                    
                }
                
            }
            
        }
        
        return 100.0
        
    }
    
    public var powerIsCharging: Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let providingSource = IOPSGetProvidingPowerSourceType(snapshot).takeRetainedValue() as String
        return providingSource == kIOPSACPowerValue
    }
    
    public var powerIsCalculating: Bool {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType {
                    let timeE = description[kIOPSTimeToEmptyKey] as? Int ?? 0
                    let timeF = description[kIOPSTimeToFullChargeKey] as? Int ?? 0
                    return timeE == 65535 || timeE == -1 || timeF == 65535 || timeF == -1
                }
            }
        }
        return false
    }
    
    private var powerRemaing:BatteryRemaining? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType {
                    if let time = description[kIOPSTimeToEmptyKey] as? Int, time > 0, time != 65535 {
                        return .init(hour: time / 60, minute: time % 60)
                    }
                }
            }
        }
        return nil
    }
    
    public var powerUntilFull:Date? {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if description[kIOPSTypeKey] as? String == kIOPSInternalBatteryType {
                    if let time = description[kIOPSTimeToFullChargeKey] as? Int, time > 0, time != 65535 {
                        return Date(timeIntervalSinceNow: Double(time * 60))
                    }
                }
            }
        }
        return nil
    }
    
    private var powerDepetionAverage:Double? {
        get { return nil }
        set { }
    }
    
    private var powerSaveModeStatus:BatteryModeType {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["bash", "-c", "pmset -g | grep lowpowermode"]

        let pipe = Pipe()
        task.standardOutput = pipe
        
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        if let output = output?.trimmingCharacters(in: .whitespacesAndNewlines) {
            if output.contains("lowpowermode") == true {
                if output.contains("1") == true {
                    return .efficient

                }
                else if output.contains("0") == true {
                    return .normal

                }
                
            }
            
        }
                
        return .unavailable
        
    }
    
    public func powerSaveMode() {
        if self.saver != .unavailable {
            let command = "do shell script \"pmset -c lowpowermode \(self.saver.flag ? 0 : 1)\" with administrator privileges"
            
            if let script = NSAppleScript(source:command) {
                var error: NSDictionary?
                script.executeAndReturnError(&error)
                
                DispatchQueue.main.async {
                    self.saver = self.powerSaveModeStatus
                    
                }
                
            }
            
        }
                
    }
    
    private func powerThermalCheck() {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["pmset", "-g", "therm"]

        let pipe = Pipe()
        process.standardOutput = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let cores = self.powerCPUCores
            
            if let match = output.range(of: "CPU_Scheduler_Limit\\s+=\\s+(\\d+)", options: .regularExpression) {
                let value = Int(output[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                
                if value < 100 {
                    if self.thermal != .suboptimal {
                        DispatchQueue.main.async {
                            WindowManager.shared.windowOpen(.deviceOverheating, device: nil)
                        }
                    }
                    self.thermal = .suboptimal
                }

            }
            
            if let match = output.range(of: "CPU_Available_CPUs\\s+=\\s+(\\d+)", options: .regularExpression) {
                let value = Int(output[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                
                if value < cores {
                    if self.thermal != .suboptimal {
                        DispatchQueue.main.async {
                            WindowManager.shared.windowOpen(.deviceOverheating, device: nil)
                        }
                    }
                    self.thermal = .suboptimal
                }

            }
            
            if let match = output.range(of: "CPU_Speed_Limit\\s+=\\s+(\\d+)", options: .regularExpression) {
                let value = Int(output[match].components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
                
                if value < 100 {
                    if self.thermal != .suboptimal {
                        DispatchQueue.main.async {
                            WindowManager.shared.windowOpen(.deviceOverheating, device: nil)
                        }
                    }
                    self.thermal = .suboptimal
                }

            }
            
        }
        
        self.thermal = .optimal
        
    }

    
    private var powerProfilerDetails:BatteryMetricsObject? {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["system_profiler", "SPPowerDataType"]

        let pipe = Pipe()
        process.standardOutput = pipe

        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: data, encoding: .utf8) {
            let lines = output.split(separator: "\n")
            
            var cycles: String?
            var heath: String?
            
            for line in lines {
                if line.contains("Cycle Count") {
                    cycles = String(line.split(separator: ":").last ?? "").trimmingCharacters(in: .whitespaces)
                    
                }
                
                if line.contains("Condition") {
                    heath = String(line.split(separator: ":").last ?? "").trimmingCharacters(in: .whitespaces)
                    
                }
                
                if let cycles = cycles, let heath = heath {
                    return .init(cycles: cycles, health: heath)
                    
                }
                
            }
          
        }
        
        return nil
        
    }
    
    private var powerCPUCores:Int {
        let process = Process()
        process.launchPath = "/usr/bin/env"
        process.arguments = ["sysctl", "-n", "hw.physicalcpu"]

        let pipe = Pipe()
        process.standardOutput = pipe

        process.launch()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8),
           let cores = Int(output.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return cores
            
        }

        return 1
        
    }
    
    private func powerWattage(_ type: BatteryWattageType) -> Int? {
        let process = Process()
        process.launchPath = "/bin/sh"
        
        switch type {
            case .current: process.arguments = ["-c", "ioreg -l | grep CurrentCapacity | awk '{print $5}'"]
            case .max: process.arguments = ["-c", "ioreg -l | grep MaxCapacity | awk '{print $5}'"]
            case .voltage: process.arguments = ["-c", "ioreg -l | grep Voltage | awk '{print $5}'"]
            
        }
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            return Int(output.trimmingCharacters(in: .whitespacesAndNewlines))
            
        }
        
        return nil
        
    }
    
    public func powerHourWattage() -> Double? {
        if let mAh = self.powerWattage(.max), let mV = self.powerWattage(.voltage) {
            return (Double(mAh) / 1000.0) * (Double(mV) / 1000.0)
            
        }
        
        return nil
        
    }

    public var currentPowerDraw: Double {
        let service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleSmartBattery"))
        defer {
            if service != 0 {
                IOObjectRelease(service)
            }
        }
        if service != 0 {
            let ampObj = IORegistryEntryCreateCFProperty(service, "InstantAmperage" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
            let voltObj = IORegistryEntryCreateCFProperty(service, "Voltage" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
            
            var amperage: Double = 0.0
            if let ampInt = ampObj as? Int {
                amperage = Double(ampInt)
            } else if let ampInt64 = ampObj as? Int64 {
                amperage = Double(ampInt64)
            } else if let ampDouble = ampObj as? Double {
                amperage = ampDouble
            }
            
            if amperage > 1_000_000_000 {
                amperage = amperage - 18446744073709551616.0
            }
            
            var voltage: Double = 0.0
            if let voltInt = voltObj as? Int {
                voltage = Double(voltInt)
            } else if let voltInt64 = voltObj as? Int64 {
                voltage = Double(voltInt64)
            } else if let voltDouble = voltObj as? Double {
                voltage = voltDouble
            }
            
            return abs(amperage * voltage) / 1_000_000.0
        }
        return 0.0
    }

    // MARK: - Battery Temperature & Health (IORegistry)

    /// Battery temperature in degrees Celsius from IORegistry.
    public var batteryTemperature: Double {
        let service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleSmartBattery"))
        defer { if service != 0 { IOObjectRelease(service) } }
        guard service != 0 else { return 0.0 }
        if let tempObj = IORegistryEntryCreateCFProperty(service, "Temperature" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue() as? Int {
            // Temperature is reported in tenths of degrees Kelvin; convert to Celsius.
            return (Double(tempObj) / 10.0) - 273.15
        }
        return 0.0
    }

    /// Battery health as a percentage of design capacity (0–100).
    public var batteryHealthPercent: Double {
        let service = IOServiceGetMatchingService(0, IOServiceNameMatching("AppleSmartBattery"))
        defer { if service != 0 { IOObjectRelease(service) } }
        guard service != 0 else { return 100.0 }
        let maxObj = IORegistryEntryCreateCFProperty(service, "AppleRawMaxCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        let designObj = IORegistryEntryCreateCFProperty(service, "DesignCapacity" as CFString, kCFAllocatorDefault, 0)?.takeRetainedValue()
        if let maxCap = maxObj as? Int, let designCap = designObj as? Int, designCap > 0 {
            return min(100.0, (Double(maxCap) / Double(designCap)) * 100.0)
        }
        return 100.0
    }



}
