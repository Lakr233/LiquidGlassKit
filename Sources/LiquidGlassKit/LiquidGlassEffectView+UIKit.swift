//
//  LiquidGlassEffectView+UIKit.swift
//  LiquidGlassKit
//

#if canImport(UIKit)
    import UIKit

    extension LiquidGlassEffectView: LiquidGlassEffectViewPlatforming {
        override public func layoutSubviews() {
            super.layoutSubviews()
            updateLayout()
        }

        func platformInsertLiquidGlassView(_ view: LiquidGlassView) {
            insertSubview(view, belowSubview: contentView)
        }

        func platformUpdateLiquidGlassViewAppearance() {
            liquidGlassView?.layer.cornerRadius = layer.cornerRadius
            liquidGlassView?.layer.cornerCurve = layer.cornerCurve
        }
    }
#endif
