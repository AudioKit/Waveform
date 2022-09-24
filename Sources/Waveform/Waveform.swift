import SwiftUI
import MetalKit

#if os(macOS)
public struct Waveform : NSViewRepresentable {

    var shader: String?
    var constants: Constants

    public init(shader: String, constants: Constants) {
        self.shader = shader
        self.constants = constants
    }

    public init(constants: Constants) {
        self.constants = constants
    }

    public class Coordinator {
        var renderer: Renderer

        init(constants: Constants) {
            renderer = Renderer(device: MTLCreateSystemDefaultDevice()!)
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(constants: constants)
    }

    public func makeNSView(context: Context) -> some NSView {
        let metalView = MTKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768),
                                device: MTLCreateSystemDefaultDevice()!)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        metalView.delegate = context.coordinator.renderer
//        if let shader = shader {
//            context.coordinator.renderer.setShader(source: shader)
//        } else {
//            context.coordinator.renderer.setDefaultShader()
//        }
        return metalView
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
//        if let shader = shader {
//            context.coordinator.renderer.setShader(source: shader)
//        }
        context.coordinator.renderer.constants = constants
        nsView.setNeedsDisplay(nsView.bounds)
    }
}
#else
/// Shadertoy-style view. Specify a fragment shader (must be named "mainImage") and a struct of constants
/// to pass to the shader. In order to ensure the constants struct is consistent with the MSL version, it's
/// best to include it in a Swift briding header. Constants are bound at position 0, and a uint2 for the view size
/// is bound at position 1.
public struct Waveform<Constants> : UIViewRepresentable {

    var shader: String
    var constants: Constants

    public init(shader: String, constants: Constants) {
        self.shader = shader
        self.constants = constants
    }

    public class Coordinator {
        var renderer: Renderer<Constants>

        init(constants: Constants) {
            renderer = Renderer<Constants>(device: MTLCreateSystemDefaultDevice()!, constants: constants)
        }
    }

    public func makeCoordinator() -> Coordinator {
        return Coordinator(constants: constants)
    }

    public func makeUIView(context: Context) -> some UIView {
        let metalView = MTKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768),
                                device: MTLCreateSystemDefaultDevice()!)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        metalView.delegate = context.coordinator.renderer
        context.coordinator.renderer.setShader(source: shader)
        return metalView
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        context.coordinator.renderer.setShader(source: shader)
        context.coordinator.renderer.constants = constants
        uiView.setNeedsDisplay()
    }

}
#endif
