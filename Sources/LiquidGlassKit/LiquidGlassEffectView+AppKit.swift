//
//  LiquidGlassEffectView+AppKit.swift
//  LiquidGlassKit
//

#if canImport(AppKit)
    import AppKit

    extension LiquidGlassEffectView: LiquidGlassEffectViewPlatforming {
        override public func layout() {
            super.layout()
            updateLayout()
        }

        override public func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            wantsLayer = true
            layer?.isOpaque = false
        }

        func platformInsertLiquidGlassView(_ view: LiquidGlassView) {
            addSubview(view, positioned: .below, relativeTo: contentView)
        }

        func platformUpdateLiquidGlassViewAppearance() {
            liquidGlassView?.layer?.cornerRadius = layer?.cornerRadius ?? 0
        }
    }
#endif
