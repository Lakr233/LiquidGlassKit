//
//  LiquidGlassContainerEffect.swift
//  LiquidGlassKit
//

import Foundation

public final class LiquidGlassContainerEffect: PlatformVisualEffect {
    public var spacing = 10.0

    override public init() {
        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
