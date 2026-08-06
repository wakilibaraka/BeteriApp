import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 11.0, macOS 10.13, tvOS 11.0, *)
extension ColorResource {

    /// The "BatteryBackground" asset catalog color resource.
    static let batteryBackground = ColorResource(name: "BatteryBackground", bundle: resourceBundle)

    /// The "BatteryButton" asset catalog color resource.
    static let batteryButton = ColorResource(name: "BatteryButton", bundle: resourceBundle)

    /// The "BatteryCharging" asset catalog color resource.
    static let batteryCharging = ColorResource(name: "BatteryCharging", bundle: resourceBundle)

    /// The "BatteryDefault" asset catalog color resource.
    static let batteryDefault = ColorResource(name: "BatteryDefault", bundle: resourceBundle)

    /// The "BatteryEfficient" asset catalog color resource.
    static let batteryEfficient = ColorResource(name: "BatteryEfficient", bundle: resourceBundle)

    /// The "BatteryLow" asset catalog color resource.
    static let batteryLow = ColorResource(name: "BatteryLow", bundle: resourceBundle)

    /// The "BatterySubtitle" asset catalog color resource.
    static let batterySubtitle = ColorResource(name: "BatterySubtitle", bundle: resourceBundle)

    /// The "BatteryTitle" asset catalog color resource.
    static let batteryTitle = ColorResource(name: "BatteryTitle", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 11.0, macOS 10.7, tvOS 11.0, *)
extension ImageResource {

    /// The "AudioIcon" asset catalog image resource.
    static let audioIcon = ImageResource(name: "AudioIcon", bundle: resourceBundle)

    /// The "ChargingIcon" asset catalog image resource.
    static let chargingIcon = ImageResource(name: "ChargingIcon", bundle: resourceBundle)

    /// The "CycleIcon" asset catalog image resource.
    static let cycleIcon = ImageResource(name: "CycleIcon", bundle: resourceBundle)

    /// The "EfficiencyIcon" asset catalog image resource.
    static let efficiencyIcon = ImageResource(name: "EfficiencyIcon", bundle: resourceBundle)

    /// The "EmptyIcon" asset catalog image resource.
    static let emptyIcon = ImageResource(name: "EmptyIcon", bundle: resourceBundle)

    /// The "EventIcon" asset catalog image resource.
    static let eventIcon = ImageResource(name: "EventIcon", bundle: resourceBundle)

    /// The "MuteIcon" asset catalog image resource.
    static let muteIcon = ImageResource(name: "MuteIcon", bundle: resourceBundle)

    /// The "OverheatIcon" asset catalog image resource.
    static let overheatIcon = ImageResource(name: "OverheatIcon", bundle: resourceBundle)

    /// The "PercentIcon" asset catalog image resource.
    static let percentIcon = ImageResource(name: "PercentIcon", bundle: resourceBundle)

    /// The "PlugIcon" asset catalog image resource.
    static let plugIcon = ImageResource(name: "PlugIcon", bundle: resourceBundle)

    /// The "RateIcon" asset catalog image resource.
    static let rateIcon = ImageResource(name: "RateIcon", bundle: resourceBundle)

    /// The "TimeIcon" asset catalog image resource.
    static let timeIcon = ImageResource(name: "TimeIcon", bundle: resourceBundle)

    /// The "WebsiteIcon" asset catalog image resource.
    static let websiteIcon = ImageResource(name: "WebsiteIcon", bundle: resourceBundle)

}

// MARK: - Backwards Deployment Support -

/// A color resource.
struct ColorResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog color resource name.
    fileprivate let name: Swift.String

    /// An asset catalog color resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize a `ColorResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

/// An image resource.
struct ImageResource: Swift.Hashable, Swift.Sendable {

    /// An asset catalog image resource name.
    fileprivate let name: Swift.String

    /// An asset catalog image resource bundle.
    fileprivate let bundle: Foundation.Bundle

    /// Initialize an `ImageResource` with `name` and `bundle`.
    init(name: Swift.String, bundle: Foundation.Bundle) {
        self.name = name
        self.bundle = bundle
    }

}

#if canImport(AppKit)
@available(macOS 10.13, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// Initialize a `NSColor` with a color resource.
    convenience init(resource: ColorResource) {
        self.init(named: NSColor.Name(resource.name), bundle: resource.bundle)!
    }

}

protocol _ACResourceInitProtocol {}
extension AppKit.NSImage: _ACResourceInitProtocol {}

@available(macOS 10.7, *)
@available(macCatalyst, unavailable)
extension _ACResourceInitProtocol {

    /// Initialize a `NSImage` with an image resource.
    init(resource: ImageResource) {
        self = resource.bundle.image(forResource: NSImage.Name(resource.name))! as! Self
    }

}
#endif

#if canImport(UIKit)
@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// Initialize a `UIColor` with a color resource.
    convenience init(resource: ColorResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}

@available(iOS 11.0, tvOS 11.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// Initialize a `UIImage` with an image resource.
    convenience init(resource: ImageResource) {
#if !os(watchOS)
        self.init(named: resource.name, in: resource.bundle, compatibleWith: nil)!
#else
        self.init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Color {

    /// Initialize a `Color` with a color resource.
    init(_ resource: ColorResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension SwiftUI.Image {

    /// Initialize an `Image` with an image resource.
    init(_ resource: ImageResource) {
        self.init(resource.name, bundle: resource.bundle)
    }

}
#endif