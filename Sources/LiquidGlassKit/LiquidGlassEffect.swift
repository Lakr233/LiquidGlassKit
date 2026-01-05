//
//  LiquidGlassEffect.swift
//  LiquidGlassKit
//

import Foundation

public final class LiquidGlassEffect: PlatformVisualEffect {
    public enum Style {
        case regular
        case clear

        var liquidGlass: LiquidGlass {
            switch self {
            case .regular:
                .regular
            case .clear:
                .regular // TODO: Add clear LiquidGlass preset.
            }
        }
    }

    let style: Style

    public init(style: Style) {
        self.style = style
        super.init()
    }

    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
