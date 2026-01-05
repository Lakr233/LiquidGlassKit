//
//  AnyVisualEffectView.swift
//  LiquidGlassKit
//

import Foundation

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#else
    #error("Unsupported platform")
#endif

public protocol AnyVisualEffectView: PlatformView {
    var contentView: PlatformView { get }
    var effect: PlatformVisualEffect? { get set }
}

#if canImport(UIKit)
    extension UIVisualEffectView: AnyVisualEffectView {}
#elseif canImport(AppKit)
    extension NSVisualEffectView: AnyVisualEffectView {
        public var contentView: NSView { self }

        public var effect: PlatformVisualEffect? {
            get { nil }
            set {}
        }
    }
#endif

@MainActor public func VisualEffectView(effect: PlatformVisualEffect?) -> AnyVisualEffectView {
    if let effect = effect as? LiquidGlassEffect {
        LiquidGlassEffectView(effect: effect)
    } else if let effect = effect as? LiquidGlassContainerEffect {
        LiquidGlassEffectView(effect: effect)
    } else {
        #if canImport(UIKit)
            UIVisualEffectView(effect: effect)
        #elseif canImport(AppKit)
            NSVisualEffectView()
        #endif
    }
}
