//
//  LiquidGlassEffectView.swift
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

@MainActor protocol LiquidGlassEffectViewPlatforming {
    func platformInsertLiquidGlassView(_ view: LiquidGlassView)
    func platformUpdateLiquidGlassViewAppearance()
}

public final class LiquidGlassEffectView: PlatformView, AnyVisualEffectView {
    public let contentView = PlatformView()
    public var effect: PlatformVisualEffect?

    var liquidGlassView: LiquidGlassView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let liquidGlassView {
                platformInsertLiquidGlassView(liquidGlassView)
            }
        }
    }

    public init(effect: LiquidGlassEffect) {
        self.effect = effect
        super.init(frame: .zero)

        let view = LiquidGlassView(effect.style.liquidGlass)
        addSubview(view)
        liquidGlassView = view

        setupContentView()
    }

    public init(effect: LiquidGlassContainerEffect) {
        self.effect = effect
        super.init(frame: .zero)

        setupContentView()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupContentView() {
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    func updateLayout() {
        liquidGlassView?.frame = contentView.frame
        platformUpdateLiquidGlassViewAppearance()
    }
}
