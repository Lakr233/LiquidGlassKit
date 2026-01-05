//
//  LiquidGlassEffectViewRepresentable.swift
//  LiquidExample
//

import LiquidGlassKit
import SwiftUI

struct LiquidGlassEffectViewRepresentable<Content: View>: NSViewRepresentable {
    typealias NSViewType = LiquidGlassEffectView

    let effect: PlatformVisualEffect
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    final class Coordinator {
        let hostingView: NSHostingView<Content>

        init(hostingView: NSHostingView<Content>) {
            self.hostingView = hostingView
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(hostingView: NSHostingView(rootView: content()))
    }

    func makeNSView(context: Context) -> LiquidGlassEffectView {
        let view = if let effect = effect as? LiquidGlassEffect {
            LiquidGlassEffectView(effect: effect)
        } else if let effect = effect as? LiquidGlassContainerEffect {
            LiquidGlassEffectView(effect: effect)
        } else {
            LiquidGlassEffectView(effect: LiquidGlassEffect(style: .regular))
        }

        view.wantsLayer = true
        view.layer?.cornerRadius = cornerRadius
        view.layer?.masksToBounds = true

        let hostingView = context.coordinator.hostingView
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        view.contentView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: view.contentView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: view.contentView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: view.contentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: view.contentView.trailingAnchor),
        ])

        return view
    }

    func updateNSView(_ nsView: LiquidGlassEffectView, context: Context) {
        nsView.layer?.cornerRadius = cornerRadius
        context.coordinator.hostingView.rootView = content()
    }
}
