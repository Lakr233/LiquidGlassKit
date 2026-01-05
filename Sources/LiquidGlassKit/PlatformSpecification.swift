//
//  PlatformSpecification.swift
//  LiquidGlassKit
//

import Foundation

#if canImport(UIKit)
    import UIKit

    public typealias PlatformView = UIView
    public typealias PlatformControl = UIControl
    public typealias PlatformColor = UIColor
    public typealias PlatformBezierPath = UIBezierPath

    public typealias PlatformImage = UIImage
    public typealias PlatformImageView = UIImageView

    public typealias PlatformEvent = UIEvent
    public typealias PlatformTouch = UITouch

    public typealias PlatformVisualEffect = UIVisualEffect
    public typealias PlatformVisualEffectView = UIVisualEffectView

#elseif canImport(AppKit)
    import AppKit

    public typealias PlatformView = NSView
    public typealias PlatformControl = NSControl
    public typealias PlatformColor = NSColor
    public typealias PlatformBezierPath = NSBezierPath

    public typealias PlatformImage = NSImage
    public typealias PlatformImageView = NSImageView

    public typealias PlatformEvent = NSEvent

    public class PlatformVisualEffect: NSObject {}

    public typealias PlatformVisualEffectView = NSVisualEffectView

#else
    #error("Unsupported platform")
#endif

@MainActor protocol PlatformDisplayLinkDelegate: AnyObject {
    func synchronization(context: PlatformDisplayLinkCallbackContext)
}

struct PlatformDisplayLinkCallbackContext {
    let duration: TimeInterval
    let timestamp: TimeInterval
    let targetTimestamp: TimeInterval
}

import MSDisplayLink

final class PlatformDisplayLink: DisplayLinkDelegate {
    private final class Driver: @unchecked Sendable {
        weak var delegate: (any PlatformDisplayLinkDelegate)?
    }

    private let displayLink = DisplayLink()
    private let driver = Driver()

    var delegate: (any PlatformDisplayLinkDelegate)? {
        get { driver.delegate }
        set { driver.delegate = newValue }
    }

    func delegatingObject(_ delegate: (any PlatformDisplayLinkDelegate)?) {
        self.delegate = delegate
        displayLink.delegatingObject(delegate == nil ? nil : self)
    }

    func synchronization(context: DisplayLinkCallbackContext) {
        let platformContext = PlatformDisplayLinkCallbackContext(
            duration: context.duration,
            timestamp: context.timestamp,
            targetTimestamp: context.targetTimestamp,
        )

        DispatchQueue.main.async { [driver] in
            driver.delegate?.synchronization(context: platformContext)
        }
    }
}
