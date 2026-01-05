//
//  PlatformSpecification.swift
//  LiquidGlassKit
//

import MSDisplayLink

#if canImport(UIKit)
import UIKit

internal typealias PlatformView = UIView
internal typealias PlatformControl = UIControl
internal typealias PlatformColor = UIColor
internal typealias PlatformBezierPath = UIBezierPath

internal typealias PlatformImage = UIImage
internal typealias PlatformImageView = UIImageView

internal typealias PlatformEvent = UIEvent
internal typealias PlatformTouch = UITouch

internal typealias PlatformVisualEffect = UIVisualEffect
internal typealias PlatformVisualEffectView = UIVisualEffectView

#elseif canImport(AppKit)
import AppKit

internal typealias PlatformView = NSView
internal typealias PlatformControl = NSControl
internal typealias PlatformColor = NSColor
internal typealias PlatformBezierPath = NSBezierPath

internal typealias PlatformImage = NSImage
internal typealias PlatformImageView = NSImageView

internal typealias PlatformEvent = NSEvent

internal typealias PlatformVisualEffectView = NSVisualEffectView

#else
#error("Unsupported platform")
#endif

internal typealias PlatformDisplayLink = DisplayLink
internal typealias PlatformDisplayLinkDelegate = DisplayLinkDelegate
internal typealias PlatformDisplayLinkCallbackContext = DisplayLinkCallbackContext
