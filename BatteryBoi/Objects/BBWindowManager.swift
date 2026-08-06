//
//  WindowManager.swift
//  BatteryBoi
//
//  Created by Joe Barbour on 8/5/23.
//

import Foundation
import Cocoa
import SwiftUI
import Combine
import CoreGraphics

struct WindowViewBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()

        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground

        return view
        
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        
    }
    
}



class WindowManager: ObservableObject {
    static var shared = WindowManager()
    
    private var updates = Set<AnyCancellable>()
    private var triggered:Int = 0;
    private var screen:CGSize {
        if let display = CGMainDisplayID() as CGDirectDisplayID? {
            return .init(width: CGFloat(CGDisplayPixelsWide(display)), height:CGFloat(CGDisplayPixelsHigh(display)))

        }
        
    }
    
    @Published public var hover: Bool = false
    @Published public var state: HUDState = .hidden
    @Published public var opacity: CGFloat = 1.0
    @Published var showSettings: Bool = false

    init() {

        
        AppManager.shared.$alert.removeDuplicates().delay(for: .seconds(5.0), scheduler: RunLoop.main).sink { type in
            if AppManager.shared.alert?.timeout == true && self.state == .revealed {
                self.windowSetState(.dismissed)
                
            }

        }.store(in: &updates)

        AppManager.shared.$alert.removeDuplicates().delay(for: .seconds(10.0), scheduler: RunLoop.main).sink { type in
            if AppManager.shared.alert?.timeout == false && self.state == .revealed {
                self.windowSetState(.dismissed)
                
            }

        }.store(in: &updates)
        

                
        SettingsManager.shared.$pinned.sink { pinned in
            if pinned == .enabled {
                withAnimation(Animation.easeOut) {
                    self.opacity = 1.0

                }
                
            }
            
        }.store(in: &updates)

        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp, .rightMouseUp]) { event in
            if NSRunningApplication.current != NSWorkspace.shared.frontmostApplication {
                if SettingsManager.shared.enabledPinned == .disabled {
                    if self.state.visible == true {
                        self.windowSetState(.dismissed)
                        
                    }

                }
                else {
                    self.windowSetState(.revealed)

                }
                
            }
            
        }
        
        $state.sink { state in
            if state == .dismissed {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    WindowManager.shared.windowClose()
                    
                }
                
            }
            else if state == .progress {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.windowSetState(.revealed)
                    
                }
                
            }
            else if state == .revealed && AppManager.shared.alert?.timeout == false {
                // Do not automatically transition to .detailed. Let it stay as a round pop-up.
            }
            

        }.store(in: &updates)
        
    }
    
    public func windowSetState(_ state:HUDState, animated:Bool = true) {
        if self.state != state {
            withAnimation(.interactiveSpring(response: 0.4, dampingFraction: 0.7, blendDuration: 1.0)) {
                self.state = state
                
            }
            
        }
        
    }
    
    public func windowIsVisible(_ type:HUDAlertTypes) -> Bool {
        return self.state.visible || self.state == .progress
    }
    
    public func windowOpen(_ type:HUDAlertTypes, device:BluetoothObject?) {
        if let window = self.windowExists(type) {
            window.contentView = WindowHostingView(rootView: HUDParent(type, device: device))
            
            DispatchQueue.main.async {
                if window.canBecomeKeyWindow {
                    window.makeKeyAndOrderFront(nil)
                    window.alphaValue = 1.0
                    
                    if AppManager.shared.alert == nil {
                        if let sfx = type.sfx {
                            sfx.play()
                            
                        }
                        
                    }
                    
                    if BluetoothManager.shared.connected.count > 0 {
                        AppManager.shared.menu = .devices

                    }
                    
                    AppManager.shared.device = device
                    AppManager.shared.alert = type
                    
                    self.windowSetState(.progress)

                }
                
            }
                
        }
        
    }
    
    private func windowClose() {
        if let window = NSApplication.shared.windows.filter({$0.title == "modalwindow"}).first {
            if AppManager.shared.alert != nil {
                AppManager.shared.alert = nil
                AppManager.shared.device = nil
                
                self.state = .hidden
                
                window.alphaValue = 0.0
                
            }

        }
        
    }
    
    private func windowDefault(_ type:HUDAlertTypes) -> NSWindow? {
        var window:NSWindow?
        window = NSWindow()
        window?.styleMask = [.borderless, .miniaturizable, .resizable]
        window?.level = .statusBar
        window?.contentView?.translatesAutoresizingMaskIntoConstraints = false
        window?.center()
        window?.title = "modalwindow"
        window?.isMovableByWindowBackground = true
        window?.backgroundColor = .clear
        window?.setFrame(self.windowHandleFrame(), display: true)
        window?.titlebarAppearsTransparent = true
        window?.titleVisibility = .hidden
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.toolbarStyle = .unifiedCompact
        window?.isReleasedWhenClosed = false
        window?.alphaValue = 0.0
        
        return window
        
    }
    
    private func windowExists(_ type: HUDAlertTypes) -> NSWindow? {
        if let window = NSApplication.shared.windows.filter({$0.title == "modalwindow"}).first {
            return window
            
        }
        else {
            return self.windowDefault(type)
            
        }
        
    }
    
    public func windowHandleFrame(moved: NSRect? = nil) -> NSRect {
        var rect = windowLastRect
        
        if let moved = moved, triggered > 5 {
            rect = moved
        } else {
            self.triggered += 1
        }
        
        let screenBounds = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: self.screen.width, height: self.screen.height)
        
        if rect.width < 150 { rect.size.width = 150 }
        if rect.height < 150 { rect.size.height = 150 }
        
        if rect.origin.x < screenBounds.minX {
            rect.origin.x = screenBounds.minX
        } else if rect.maxX > screenBounds.maxX {
            rect.origin.x = screenBounds.maxX - rect.width
        }
        
        if rect.origin.y < screenBounds.minY {
            rect.origin.y = screenBounds.minY
        } else if rect.maxY > screenBounds.maxY {
            rect.origin.y = screenBounds.maxY - rect.height
        }
        
        if moved != nil && triggered > 5 {
            self.windowLastRect = rect
        }
        
        return rect
    }
    
    private var windowLastRect: NSRect {
        get {
            if let str = UserDefaults.main.string(forKey: "sd_window_rect") {
                return NSRectFromString(str)
            }
            let windowMargin: CGFloat = 40
            let positionDefault = CGSize(width: 480, height: 420)
            let positionLeft = (self.screen.width / 2) - (positionDefault.width / 2)
            let positionTop = self.screen.height - (positionDefault.height + windowMargin)
            return NSMakeRect(positionLeft, positionTop, positionDefault.width, positionDefault.height)
        }
        set {
            UserDefaults.main.set(NSStringFromRect(newValue), forKey: "sd_window_rect")
        }
    }

}

class WindowHostingView<Content>: NSHostingView<Content> where Content: View {
    override func scrollWheel(with event: NSEvent) {
        super.scrollWheel(with: event)
        
        if SettingsManager.shared.enabledPinned == .enabled {
            withAnimation(Animation.easeOut) {
                if WindowManager.shared.state == .revealed {
                    if event.deltaY < 0 && WindowManager.shared.opacity > 0.4 {
                        WindowManager.shared.opacity += (event.deltaY / 100)
                        
                    }
                    else if event.deltaY > 0 && WindowManager.shared.opacity < 1.0 {
                        WindowManager.shared.opacity += (event.deltaY / 100)
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
}
