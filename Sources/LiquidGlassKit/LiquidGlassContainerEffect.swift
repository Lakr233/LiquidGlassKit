//
//  LiquidGlassContainerEffect.swift
//  LiquidGlassKit
//

import Foundation

public final class LiquidGlassContainerEffect: PlatformVisualEffect {
    /// How far (in points) shapes can be apart while still “melting” together.
    public var spacing = 10.0

    /// Backwards-compatible alias for `spacing`.
    public var mergingSpace: Double {
        get { spacing }
        set { spacing = newValue }
    }

    override public init() {
        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
