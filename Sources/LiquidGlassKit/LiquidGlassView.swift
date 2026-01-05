//
//  LiquidGlassView.swift
//  LiquidGlass
//
//  Created by Alexey Demin on 2025-12-05.
//

#if canImport(UIKit)
    import CoreGraphics
    import UIKit
#elseif canImport(AppKit)
    import AppKit
    import CoreGraphics
#else
    #error("Unsupported platform")
#endif

import MetalKit
import MetalPerformanceShaders
import simd

struct LiquidGlass {
    /// Maximum number of rectangles supported in the shader.
    static let maxRectangles = 16

    /// Mirror the Metal 'ShaderUniforms' exactly for buffer binding.
    struct ShaderUniforms {
        var resolution: SIMD2<Float> = .zero // Frame size in pixels.
        var contentsScale: Float = .zero // Scale factor. 2 for Retina; 3 for Super Retina.
        var touchPoint: SIMD2<Float> = .zero // Touch position in points (upper-left origin).
        var shapeMergeSmoothness: Float = .zero // Specifies the distance between elements at which they begin to merge (spacing).
        var cornerRadius: Float = .zero // Base rounding (e.g., 24 for subtle chamfer). Circle if half the side.
        var cornerRoundnessExponent: Float = 2 // 1 = diamond; 2 = circle; 4 = squircle.
        var materialTint: SIMD4<Float> = .zero // RGBA
        var glassThickness: Float
        var refractiveIndex: Float
        var dispersionStrength: Float
        var fresnelDistanceRange: Float
        var fresnelIntensity: Float
        var fresnelEdgeSharpness: Float
        var glareDistanceRange: Float
        var glareAngleConvergence: Float
        var glareOppositeSideBias: Float
        var glareIntensity: Float
        var glareEdgeSharpness: Float
        var glareDirectionOffset: Float
        var rectangleCount: Int32 = .zero
        var rectangles: (
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
            SIMD4<Float>, SIMD4<Float>, SIMD4<Float>, SIMD4<Float>,
        ) = (
            .zero, .zero, .zero, .zero,
            .zero, .zero, .zero, .zero,
            .zero, .zero, .zero, .zero,
            .zero, .zero, .zero, .zero,
        )
    }

    let shaderUniforms: ShaderUniforms
    let backgroundTextureSizeCoefficient: Double
    let backgroundTextureScaleCoefficient: Double
    let backgroundTextureBlurRadius: Double
    var tintColor: PlatformColor?
    var shadowOverlay: Bool = false

    static func thumb(magnification: Double = 1) -> Self {
        .init(
            shaderUniforms: .init(
                materialTint: .init(x: 0.9, y: 0.95, z: 1.0, w: 0.15),
                glassThickness: 10,
                refractiveIndex: 1.11,
                dispersionStrength: 5,
                fresnelDistanceRange: 70,
                fresnelIntensity: 0,
                fresnelEdgeSharpness: 0,
                glareDistanceRange: 30,
                glareAngleConvergence: 0,
                glareOppositeSideBias: 0,
                glareIntensity: 0.01,
                glareEdgeSharpness: -0.2,
                glareDirectionOffset: .pi * 0.9,
            ),
            backgroundTextureSizeCoefficient: 1 / magnification,
            backgroundTextureScaleCoefficient: magnification,
            backgroundTextureBlurRadius: 0,
            shadowOverlay: true,
        )
    }

    static let lens = Self(
        shaderUniforms: .init(
            glassThickness: 6,
            refractiveIndex: 1.1,
            dispersionStrength: 15,
            fresnelDistanceRange: 70,
            fresnelIntensity: 0,
            fresnelEdgeSharpness: 0,
            glareDistanceRange: 30,
            glareAngleConvergence: 0.1,
            glareOppositeSideBias: 1,
            glareIntensity: 0.1,
            glareEdgeSharpness: -0.1,
            glareDirectionOffset: -.pi / 4,
        ),
        backgroundTextureSizeCoefficient: 1.1,
        backgroundTextureScaleCoefficient: 0.8,
        backgroundTextureBlurRadius: 0,
        shadowOverlay: true,
    )

    static let regular = Self(
        shaderUniforms: .init(
            glassThickness: 10,
            refractiveIndex: 1.5,
            dispersionStrength: 5,
            fresnelDistanceRange: 70,
            fresnelIntensity: 0,
            fresnelEdgeSharpness: 0,
            glareDistanceRange: 30,
            glareAngleConvergence: 0.1,
            glareOppositeSideBias: 1,
            glareIntensity: 0.1,
            glareEdgeSharpness: -0.15,
            glareDirectionOffset: -.pi / 4,
        ),
        backgroundTextureSizeCoefficient: 1,
        backgroundTextureScaleCoefficient: 0.2,
        backgroundTextureBlurRadius: 0.3,
        tintColor: {
            #if canImport(UIKit)
                PlatformColor { traits in
                    traits.userInterfaceStyle == .dark
                        ? PlatformColor(red: 0.0, green: 0.049, blue: 0.099, alpha: 0.798)
                        : PlatformColor(red: 0.902, green: 0.951, blue: 1.0, alpha: 0.800)
                }
            #else
                PlatformColor.windowBackgroundColor.withAlphaComponent(0.8)
            #endif
        }(),
    )
}

#if canImport(UIKit)
    final class BackdropView: UIView {
        override class var layerClass: AnyClass {
            NSClassFromString("CABackdropLayer") ?? CALayer.self
        }

        init() {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            layer.setValue(false, forKey: "layerUsesCoreImageFilters")
            layer.setValue(true, forKey: "windowServerAware")
            layer.setValue(UUID().uuidString, forKey: "groupName")
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }

    final class ShadowView: UIView {
        init() {
            super.init(frame: .zero)
            isUserInteractionEnabled = false
            backgroundColor = .clear
            layer.compositingFilter = "multiplyBlendMode"
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            let shadowRadius = 3.5
            let path = UIBezierPath(
                roundedRect: bounds.insetBy(dx: -1, dy: -shadowRadius / 2),
                cornerRadius: bounds.height / 2,
            )
            let innerPill = UIBezierPath(
                roundedRect: bounds.insetBy(dx: 0, dy: shadowRadius / 2),
                cornerRadius: bounds.height / 2,
            ).reversing()
            path.append(innerPill)

            layer.shadowPath = path.cgPath
            layer.shadowRadius = shadowRadius
            layer.shadowOpacity = 0.2
            layer.shadowOffset = .init(width: 0, height: shadowRadius + 2)
        }
    }

#elseif canImport(AppKit)
    final class BackdropView: NSView {
        private let groupName = UUID().uuidString

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer?.isOpaque = false
            layer?.setValue(false, forKey: "layerUsesCoreImageFilters")
            layer?.setValue(true, forKey: "windowServerAware")
            layer?.setValue(groupName, forKey: "groupName")
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func hitTest(_: NSPoint) -> NSView? {
            nil
        }

        override func makeBackingLayer() -> CALayer {
            let template = NSVisualEffectView(frame: .zero)
            template.blendingMode = .behindWindow
            template.material = .underWindowBackground
            template.state = .active
            template.wantsLayer = true

            let directType = template.layer.map { type(of: $0) }
            let sublayerType = template.layer?.sublayers?.first {
                String(describing: type(of: $0)) == "CABackdropLayer"
            }.map { type(of: $0) }

            let backdropLayerType = directType ?? sublayerType ?? (NSClassFromString("CABackdropLayer") as? CALayer.Type)
            let backdropLayer = backdropLayerType?.init() ?? CALayer()

            backdropLayer.setValue(false, forKey: "layerUsesCoreImageFilters")
            backdropLayer.setValue(true, forKey: "windowServerAware")
            backdropLayer.setValue(groupName, forKey: "groupName")

            return backdropLayer
        }
    }
#endif

final class LiquidGlassRenderer {
    @MainActor static let shared = LiquidGlassRenderer()

    let device: MTLDevice
    let pipelineState: MTLRenderPipelineState

    private init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let library = try? device.makeDefaultLibrary(bundle: .module)
        else {
            fatalError("Metal or Shader not available")
        }
        self.device = device

        let vertexFunction = library.makeFunction(name: "fullscreenQuad")!
        let fragmentFunction = library.makeFunction(name: "liquidGlassEffect")!

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
}

@MainActor final class LiquidGlassView: MTKView, PlatformDisplayLinkDelegate {
    let liquidGlass: LiquidGlass

    private var commandQueue: MTLCommandQueue!
    private var uniformsBuffer: MTLBuffer!
    private var zeroCopyBridge: ZeroCopyBridge!

    private var renderDisplayLink: PlatformDisplayLink?

    private var backgroundTexture: MTLTexture?

    var autoCapture: Bool = true

    var touchPoint: CGPoint?

    var frames: [CGRect] = []

    /// Controls how strongly shapes merge together.
    /// Higher values merge across larger gaps.
    var mergeSpacing: Double = 10

    #if canImport(UIKit)
        private weak var shadowView: ShadowView?
        private let backdropView = BackdropView()
    #elseif canImport(AppKit)
        private let backdropView = BackdropView()
    #endif

    init(_ liquidGlass: LiquidGlass) {
        self.liquidGlass = liquidGlass
        super.init(frame: .zero, device: LiquidGlassRenderer.shared.device)

        #if canImport(AppKit)
            wantsLayer = true
            layer?.isOpaque = false
        #endif

        #if canImport(UIKit)
            if liquidGlass.shadowOverlay {
                let shadowView = ShadowView()
                addSubview(shadowView)
                self.shadowView = shadowView
            }
        #endif

        setupMetal()
        updateDisplayLinkState()
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private var resolvedContentsScale: CGFloat {
        #if canImport(UIKit)
            return window?.screen.scale ?? UIScreen.main.scale
        #else
            return window?.backingScaleFactor ?? NSScreen.main?.backingScaleFactor ?? 1
        #endif
    }

    private var resolvedCornerRadius: CGFloat {
        #if canImport(UIKit)
            return layer.cornerRadius
        #else
            return layer?.cornerRadius ?? 0
        #endif
    }

    private func setupMetal() {
        guard let device else { return }

        commandQueue = device.makeCommandQueue()!
        uniformsBuffer = device.makeBuffer(
            length: MemoryLayout<LiquidGlass.ShaderUniforms>.stride,
            options: [],
        )!
        zeroCopyBridge = .init(device: device)

        #if canImport(UIKit)
            isOpaque = false
            layer.isOpaque = false
        #else
            layer?.isOpaque = false
        #endif

        isPaused = true
        enableSetNeedsDisplay = false
    }

    // MARK: - Display Link

    private func updateDisplayLinkState() {
        let isVisible = window != nil
        if isVisible {
            startDisplayLinkIfNeeded()
        } else {
            stopDisplayLink()
        }
    }

    private func startDisplayLinkIfNeeded() {
        guard renderDisplayLink == nil else { return }
        let link = PlatformDisplayLink()
        link.delegatingObject(self)
        renderDisplayLink = link
    }

    private func stopDisplayLink() {
        renderDisplayLink?.delegatingObject(nil)
        renderDisplayLink = nil
    }

    func synchronization(context _: PlatformDisplayLinkCallbackContext) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        draw()
    }

    #if canImport(UIKit)
        override func didMoveToWindow() {
            super.didMoveToWindow()
            updateDisplayLinkState()
        }

    #elseif canImport(AppKit)
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateDisplayLinkState()
        }
    #endif

    @MainActor deinit {
        renderDisplayLink?.delegatingObject(nil)
    }

    // MARK: - Background Capture

    func captureBackground() {
        #if canImport(UIKit)
            captureBackdrop()
        #elseif canImport(AppKit)
            captureBackdrop()
        #else
            captureRootView()
        #endif
    }

    func captureRootView() {
        guard let rootView = findRootView() else { return }

        let sizeCoefficient = liquidGlass.backgroundTextureSizeCoefficient
        let scaleCoefficient = resolvedContentsScale * liquidGlass.backgroundTextureScaleCoefficient

        #if canImport(UIKit)
            let currentLayer = layer.presentation() ?? layer
            let rootLayer = rootView.layer.presentation() ?? rootView.layer
        #else
            guard let viewLayer = layer else { return }
            guard let rootLayerBase = rootView.layer else { return }
            let currentLayer = viewLayer.presentation() ?? viewLayer
            let rootLayer = rootLayerBase.presentation() ?? rootLayerBase
        #endif

        let frameInRoot = currentLayer.convert(currentLayer.bounds, to: rootLayer)

        let captureSize = CGSize(
            width: frameInRoot.width * sizeCoefficient,
            height: frameInRoot.height * sizeCoefficient,
        )
        let captureRectInRoot = CGRect(
            x: frameInRoot.midX - captureSize.width / 2,
            y: frameInRoot.midY - captureSize.height / 2,
            width: captureSize.width,
            height: captureSize.height,
        )

        backgroundTexture = zeroCopyBridge.render { context in
            let wasHidden = isHidden
            isHidden = true
            defer { isHidden = wasHidden }

            context.scaleBy(x: scaleCoefficient, y: scaleCoefficient)
            context.translateBy(x: -captureRectInRoot.origin.x, y: -captureRectInRoot.origin.y)

            rootLayer.render(in: context)
        }

        blurTexture()
    }

    #if canImport(UIKit)
        func captureBackdrop() {
            guard let superview else { return }

            let sizeCoefficient = liquidGlass.backgroundTextureSizeCoefficient
            let scaleCoefficient = resolvedContentsScale * liquidGlass.backgroundTextureScaleCoefficient

            let currentLayer = layer.presentation() ?? layer
            let frameInSuperview = currentLayer.convert(currentLayer.bounds, to: superview.layer)
            let captureSize = CGSize(
                width: frameInSuperview.width * sizeCoefficient,
                height: frameInSuperview.height * sizeCoefficient,
            )
            let captureOrigin = CGPoint(
                x: frameInSuperview.midX - captureSize.width / 2,
                y: frameInSuperview.midY - captureSize.height / 2,
            )

            backdropView.frame = CGRect(origin: captureOrigin, size: captureSize)

            if backdropView.superview !== superview {
                superview.insertSubview(backdropView, belowSubview: self)
            }

            backgroundTexture = zeroCopyBridge.render { context in
                context.scaleBy(x: scaleCoefficient, y: scaleCoefficient)

                UIGraphicsPushContext(context)
                backdropView.drawHierarchy(in: backdropView.bounds, afterScreenUpdates: false)
                UIGraphicsPopContext()
            }

            blurTexture()
        }

    #elseif canImport(AppKit)
        func captureBackdrop() {
            guard let superview else { return }
            guard let viewLayer = layer else { return }
            guard let superviewLayer = superview.layer else { return }

            let sizeCoefficient = liquidGlass.backgroundTextureSizeCoefficient
            let scaleCoefficient = resolvedContentsScale * liquidGlass.backgroundTextureScaleCoefficient

            let currentLayer = viewLayer.presentation() ?? viewLayer
            let frameInSuperview = currentLayer.convert(currentLayer.bounds, to: superviewLayer)

            let captureSize = CGSize(
                width: frameInSuperview.width * sizeCoefficient,
                height: frameInSuperview.height * sizeCoefficient,
            )
            let captureOrigin = CGPoint(
                x: frameInSuperview.midX - captureSize.width / 2,
                y: frameInSuperview.midY - captureSize.height / 2,
            )

            backdropView.frame = CGRect(origin: captureOrigin, size: captureSize)

            if backdropView.superview !== superview {
                superview.addSubview(backdropView, positioned: .below, relativeTo: self)
            }

            backgroundTexture = zeroCopyBridge.render { context in
                let wasHidden = isHidden
                isHidden = true
                defer { isHidden = wasHidden }

                context.scaleBy(x: scaleCoefficient, y: scaleCoefficient)

                backdropView.display()
                guard let viewLayer = backdropView.layer else { return }
                viewLayer.render(in: context)
            }

            blurTexture()
        }
    #endif

    private func blurTexture() {
        guard liquidGlass.backgroundTextureBlurRadius > 0,
              let device,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              var backgroundTexture else { return }

        let sigma = Float(liquidGlass.backgroundTextureBlurRadius * resolvedContentsScale)
        let blur = MPSImageGaussianBlur(device: device, sigma: sigma)
        blur.edgeMode = .clamp

        blur.encode(commandBuffer: commandBuffer, inPlaceTexture: &backgroundTexture, fallbackCopyAllocator: nil)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }

    private func updateUniforms() {
        var uniforms = liquidGlass.shaderUniforms
        let scaleFactor = resolvedContentsScale

        uniforms.resolution = .init(
            x: Float(bounds.width * scaleFactor),
            y: Float(bounds.height * scaleFactor),
        )
        uniforms.contentsScale = Float(scaleFactor)

        let maxSpacing: Double = 400
        let clampedSpacing = min(max(mergeSpacing, 0), maxSpacing)
        let normalizedSpacing = clampedSpacing / max(bounds.height, 1)
        uniforms.shapeMergeSmoothness = Float(normalizedSpacing)

        let effectiveFrames = frames.isEmpty ? [bounds] : frames
        uniforms.rectangleCount = Int32(min(effectiveFrames.count, LiquidGlass.maxRectangles))

        var rects: [SIMD4<Float>] = []
        rects.reserveCapacity(LiquidGlass.maxRectangles)

        for i in 0 ..< LiquidGlass.maxRectangles {
            if i < effectiveFrames.count {
                let frame = effectiveFrames[i]
                rects.append(SIMD4<Float>(
                    Float(frame.origin.x),
                    Float(frame.origin.y),
                    Float(frame.width),
                    Float(frame.height),
                ))
            } else {
                rects.append(.zero)
            }
        }

        uniforms.rectangles = (
            rects[0], rects[1], rects[2], rects[3],
            rects[4], rects[5], rects[6], rects[7],
            rects[8], rects[9], rects[10], rects[11],
            rects[12], rects[13], rects[14], rects[15],
        )

        if let touchPoint {
            uniforms.touchPoint = .init(x: Float(touchPoint.x), y: Float(touchPoint.y))
        }

        uniforms.cornerRadius = Float(resolvedCornerRadius)

        if let tintColor = liquidGlass.tintColor {
            uniforms.materialTint = tintColor.toSimdFloat4()
        }

        uniformsBuffer.contents()
            .assumingMemoryBound(to: LiquidGlass.ShaderUniforms.self)
            .pointee = uniforms
    }

    #if canImport(UIKit)
        override func layoutSubviews() {
            super.layoutSubviews()
            platformLayout()
        }

    #elseif canImport(AppKit)
        override func layout() {
            super.layout()
            platformLayout()
        }
    #endif

    private func platformLayout() {
        updateUniforms()

        let scale = resolvedContentsScale
            * liquidGlass.backgroundTextureSizeCoefficient
            * liquidGlass.backgroundTextureScaleCoefficient

        let width = Int(bounds.width * scale)
        let height = Int(bounds.height * scale)
        if width > 0, height > 0 {
            zeroCopyBridge.setupBuffer(width: width, height: height)
        }

        #if canImport(UIKit)
            shadowView?.frame = bounds
        #endif
    }

    override func draw(_: CGRect) {
        if autoCapture {
            captureBackground()
        }

        guard let drawable = currentDrawable,
              let renderPassDesc = currentRenderPassDescriptor,
              let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDesc) else { return }

        encoder.setRenderPipelineState(LiquidGlassRenderer.shared.pipelineState)
        encoder.setFragmentBuffer(uniformsBuffer, offset: 0, index: 0)

        if let texture = backgroundTexture {
            encoder.setFragmentTexture(texture, index: 0)
        }

        encoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        encoder.endEncoding()

        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}

extension PlatformColor {
    func toSimdFloat4() -> SIMD4<Float> {
        #if canImport(UIKit)
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            getRed(&r, green: &g, blue: &b, alpha: &a)
            return .init(x: Float(r), y: Float(g), z: Float(b), w: Float(a))
        #else
            guard let rgb = usingColorSpace(.deviceRGB) else { return .zero }
            return .init(
                x: Float(rgb.redComponent),
                y: Float(rgb.greenComponent),
                z: Float(rgb.blueComponent),
                w: Float(rgb.alphaComponent),
            )
        #endif
    }
}

#if canImport(UIKit)
    extension UIView {
        func findRootView() -> UIView? {
            var current: UIView? = superview
            while let parent = current?.superview {
                current = parent
            }
            return current
        }
    }

#elseif canImport(AppKit)
    extension NSView {
        func findRootView() -> NSView? {
            var current: NSView? = superview
            while let parent = current?.superview {
                current = parent
            }
            return current
        }
    }
#endif
