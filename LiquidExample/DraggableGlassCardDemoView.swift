//
//  DraggableGlassCardDemoView.swift
//  LiquidExample
//

import LiquidGlassKit
import SwiftUI

struct DraggableGlassCardDemoView: View {
    @State private var offset: CGSize = .zero

    var body: some View {
        ZStack {
            GridBackgroundView()

            LiquidGlassEffectViewRepresentable(
                effect: LiquidGlassEffect(style: .regular),
                cornerRadius: 24,
            ) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("LiquidGlassKit")
                        .font(.headline)
                    Text("Drag this card around")
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
            }
            .shadow(color: .black.opacity(0.15), radius: 18, x: 0, y: 10)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                    },
            )
        }
    }
}
