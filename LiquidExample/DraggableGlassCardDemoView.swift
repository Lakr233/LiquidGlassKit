//
//  DraggableGlassCardDemoView.swift
//  LiquidExample
//

import LiquidGlassKit
import SwiftUI

struct DraggableGlassCardDemoView: View {
    @State private var card1Offset: CGSize = .init(width: -120, height: -40)
    @State private var card2Offset: CGSize = .init(width: 120, height: 40)

    @State private var card1Frame: CGRect = .zero
    @State private var card2Frame: CGRect = .zero

    var body: some View {
        ZStack {
            GridBackgroundView()

            LiquidGlassEffectViewRepresentable(
                effect: {
                    let effect = LiquidGlassContainerEffect()
                    effect.mergingSpace = 120
                    return effect
                }(),
                cornerRadius: 28,
            ) {
                ZStack {
                    DraggableGlassCard(
                        title: "LiquidGlassKit",
                        subtitle: "Drag cards to see them melt",
                        offset: $card1Offset,
                    )
                    .measureFrame { card1Frame = $0 }

                    DraggableGlassCard(
                        title: "Second Card",
                        subtitle: "Moves independently",
                        offset: $card2Offset,
                    )
                    .measureFrame { card2Frame = $0 }
                }
                .padding(60)
            }
            .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)
            .overlay(alignment: .bottom) {
                Text("card1: \(Int(card1Offset.width)), \(Int(card1Offset.height))   card2: \(Int(card2Offset.width)), \(Int(card2Offset.height))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 14)
            }
            .modifier(ContainerMergedFrames(frames: [card1Frame, card2Frame]))
        }
        .coordinateSpace(name: "LiquidGlassContainer")
    }
}

private struct DraggableGlassCard: View {
    let title: String
    let subtitle: String
    @Binding var offset: CGSize

    @State private var startOffset: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider().opacity(0.2)

            HStack(spacing: 10) {
                Text("x: \(Int(offset.width))")
                Text("y: \(Int(offset.height))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 260)
        .contentShape(Rectangle())
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    offset = .init(
                        width: startOffset.width + value.translation.width,
                        height: startOffset.height + value.translation.height,
                    )
                }
                .onEnded { _ in
                    startOffset = offset
                },
        )
        .onAppear {
            startOffset = offset
        }
    }
}

private struct ContainerMergedFrames: ViewModifier {
    let frames: [CGRect]

    func body(content: Content) -> some View {
        content
            .background(ContainerMergedFramesView(frames: frames))
    }
}

private struct ContainerMergedFramesView: NSViewRepresentable {
    let frames: [CGRect]

    func makeNSView(context _: Context) -> NSView {
        UpdatingView(frames: frames)
    }

    func updateNSView(_ nsView: NSView, context _: Context) {
        (nsView as? UpdatingView)?.frames = frames
    }

    private final class UpdatingView: NSView {
        var frames: [CGRect] {
            didSet { updateMergedFrames() }
        }

        init(frames: [CGRect]) {
            self.frames = frames
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidMoveToSuperview() {
            super.viewDidMoveToSuperview()
            updateMergedFrames()
        }

        override func layout() {
            super.layout()
            updateMergedFrames()
        }

        private func updateMergedFrames() {
            guard let effectView = superview as? LiquidGlassEffectView else { return }
            effectView.mergedFrames = frames
        }
    }
}

private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private extension View {
    func measureFrame(_ onChange: @escaping (CGRect) -> Void) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear
                    .preference(key: FramePreferenceKey.self, value: proxy.frame(in: .named("LiquidGlassContainer")))
            },
        )
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }
}
