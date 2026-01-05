//
//  GridBackgroundView.swift
//  LiquidExample
//

import SwiftUI

struct GridBackgroundView: View {
    var minorSpacing: CGFloat = 20
    var majorEvery: Int = 5

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let minor = Path { path in
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += minorSpacing
                    }

                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += minorSpacing
                    }
                }

                let majorSpacing = minorSpacing * CGFloat(majorEvery)
                let major = Path { path in
                    var x: CGFloat = 0
                    while x <= size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += majorSpacing
                    }

                    var y: CGFloat = 0
                    while y <= size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += majorSpacing
                    }
                }

                context.stroke(minor, with: .color(.primary.opacity(0.08)), lineWidth: 1)
                context.stroke(major, with: .color(.primary.opacity(0.16)), lineWidth: 1)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .ignoresSafeArea()
    }
}
