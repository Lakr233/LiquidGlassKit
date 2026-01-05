//
//  PlatformSpecification.swift
//  LiquidGlassKit
//

import Foundation

#if canImport(UIKit)
    import UIKit

    typealias PlatformView = UIView
    typealias PlatformControl = UIControl
    typealias PlatformColor = UIColor
    typealias PlatformBezierPath = UIBezierPath

    typealias PlatformImage = UIImage
    typealias PlatformImageView = UIImageView

    typealias PlatformEvent = UIEvent
    typealias PlatformTouch = UITouch

    typealias PlatformVisualEffect = UIVisualEffect
    typealias PlatformVisualEffectView = UIVisualEffectView

#elseif canImport(AppKit)
    import AppKit

    typealias PlatformView = NSView
    typealias PlatformControl = NSControl
    typealias PlatformColor = NSColor
    typealias PlatformBezierPath = NSBezierPath

    typealias PlatformImage = NSImage
    typealias PlatformImageView = NSImageView

    typealias PlatformEvent = NSEvent

    typealias PlatformVisualEffectView = NSVisualEffectView

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

#if canImport(MSDisplayLink)
    import MSDisplayLink

    final class PlatformDisplayLink {
        private final class Adapter: DisplayLinkDelegate {
            private final class Driver: @unchecked Sendable {
                weak var delegate: (any PlatformDisplayLinkDelegate)?
            }

            private let driver = Driver()

            var delegate: (any PlatformDisplayLinkDelegate)? {
                get { driver.delegate }
                set { driver.delegate = newValue }
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

        private let displayLink = DisplayLink()
        private let adapter = Adapter()

        func delegatingObject(_ delegate: (any PlatformDisplayLinkDelegate)?) {
            adapter.delegate = delegate
            displayLink.delegatingObject(delegate == nil ? nil : adapter)
        }
    }

#else
    #if canImport(UIKit)
        final class PlatformDisplayLink {
            private var displayLink: CADisplayLink?
            private weak var delegate: (any PlatformDisplayLinkDelegate)?

            func delegatingObject(_ delegate: (any PlatformDisplayLinkDelegate)?) {
                self.delegate = delegate

                if delegate == nil {
                    displayLink?.invalidate()
                    displayLink = nil
                    return
                }

                if displayLink == nil {
                    let link = CADisplayLink(target: self, selector: #selector(frameTick))
                    link.add(to: .main, forMode: .common)
                    displayLink = link
                }
            }

            @objc private func frameTick(_ link: CADisplayLink) {
                guard let delegate else { return }
                let context = PlatformDisplayLinkCallbackContext(
                    duration: link.duration,
                    timestamp: link.timestamp,
                    targetTimestamp: link.targetTimestamp,
                )
                delegate.synchronization(context: context)
            }

            deinit {
                displayLink?.invalidate()
            }
        }

    #elseif canImport(AppKit)
        import CoreVideo

        final class PlatformDisplayLink {
            private final class Driver: @unchecked Sendable {
                weak var delegate: (any PlatformDisplayLinkDelegate)?
            }

            private let driver = Driver()
            private var displayLink: CVDisplayLink?

            func delegatingObject(_ delegate: (any PlatformDisplayLinkDelegate)?) {
                driver.delegate = delegate

                if delegate == nil {
                    if let displayLink {
                        CVDisplayLinkStop(displayLink)
                    }
                    displayLink = nil
                    return
                }

                if displayLink == nil {
                    var link: CVDisplayLink?
                    CVDisplayLinkCreateWithActiveCGDisplays(&link)
                    guard let link else { return }

                    let driverPtr = Unmanaged.passUnretained(driver).toOpaque()
                    CVDisplayLinkSetOutputCallback(link, { _, _, outputTime, _, _, userInfo in
                        guard let userInfo else { return kCVReturnSuccess }

                        let driver = Unmanaged<Driver>.fromOpaque(userInfo).takeUnretainedValue()
                        let timestamp = TimeInterval(outputTime.pointee.videoTime) / TimeInterval(outputTime.pointee.videoTimeScale)

                        DispatchQueue.main.async {
                            let context = PlatformDisplayLinkCallbackContext(
                                duration: 0,
                                timestamp: timestamp,
                                targetTimestamp: 0,
                            )
                            driver.delegate?.synchronization(context: context)
                        }

                        return kCVReturnSuccess
                    }, driverPtr)

                    CVDisplayLinkStart(link)
                    displayLink = link
                }
            }

            deinit {
                if let displayLink {
                    CVDisplayLinkStop(displayLink)
                }
            }
        }
    #endif
#endif
