//
//  LiquidGlassEffectView.swift
//  LiquidGlass
//
//  Created by Alexey Demin on 2025-12-23.
//

#if canImport(UIKit)
    import UIKit

    public class LiquidGlassEffectView: UIView, AnyVisualEffectView {
        public let contentView = UIView()
        public var effect: UIVisualEffect?

        var liquidGlassView: LiquidGlassView? {
            didSet {
                oldValue?.removeFromSuperview()
                if let liquidGlassView {
                    insertSubview(liquidGlassView, belowSubview: contentView)
                }
            }
        }

        public required init(effect: LiquidGlassEffect) {
            self.effect = effect

            super.init(frame: .zero)

            let liquidGlassView = LiquidGlassView(effect.style.liquidGlass)
            addSubview(liquidGlassView)
            self.liquidGlassView = liquidGlassView

            setupContentView()
        }

        public required init(effect: LiquidGlassContainerEffect) {
            self.effect = effect

            super.init(frame: .zero)

            setupContentView()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func setupContentView() {
            addSubview(contentView)
            contentView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contentView.topAnchor.constraint(equalTo: topAnchor),
                contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
                contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            ])
        }

        override public func layoutSubviews() {
            super.layoutSubviews()

            liquidGlassView?.frame = contentView.frame
            liquidGlassView?.layer.cornerRadius = layer.cornerRadius
            liquidGlassView?.layer.cornerCurve = layer.cornerCurve
        }
    }

    /// A visual effect that renders a glass material.
    public class LiquidGlassEffect: UIVisualEffect {
        public enum Style {
            case regular, clear

            var liquidGlass: LiquidGlass {
                switch self {
                case .regular: .regular
                case .clear: .regular // TODO: Add clear LiquidGlass preset.
                }
            }
        }

        let style: Style

        /// Creates a glass effect with the specified style.
        /// - Parameter style: The glass effect style.
        public init(style: Style) {
            self.style = style
            super.init()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    /// A `LiquidGlassContainerEffect` renders multiple glass elements into a combined effect.
    ///
    /// When using `LiquidGlassContainerEffect` with a `VisualEffectView` you can
    /// add individual glass elements to the visual effect view's contentView by nesting `VisualEffectView`'s
    /// configured with `LiquidGlassEffect`. In that configuration, the glass container will render all glass elements
    /// in one combined view, behind the visual effect view's `contentView`.
    public class LiquidGlassContainerEffect: UIVisualEffect {
        /// The spacing specifies the distance between elements at which they begin to merge.
        public var spacing = 10.0

        /// Creates a combined glass effect.
        public override init() {
            super.init()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    public protocol AnyVisualEffectView: UIView {
        var contentView: UIView { get }
        var effect: UIVisualEffect? { get set }
    }

    extension UIVisualEffectView: AnyVisualEffectView {}

    public func VisualEffectView(effect: UIVisualEffect?) -> AnyVisualEffectView {
        if let effect = effect as? LiquidGlassEffect {
            return LiquidGlassEffectView(effect: effect)
        } else if let effect = effect as? LiquidGlassContainerEffect {
            return LiquidGlassEffectView(effect: effect)
        } else {
            return UIVisualEffectView(effect: effect)
        }
    }

#endif
