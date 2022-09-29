import SwiftUI
import MetalKit

#if os(macOS)
public struct Waveform : NSViewRepresentable {

    var samples: [Float]
    var constants: Constants

    public init(samples: [Float], constants: Constants) {
        self.samples = samples
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
        return metalView
    }

    public func updateNSView(_ nsView: NSViewType, context: Context) {
        let renderer = context.coordinator.renderer
        renderer.constants = constants
        renderer.set(samples: samples, binSize: Int(CGFloat(samples.count) / 1024))
        nsView.setNeedsDisplay(nsView.bounds)
    }
}
#else
public struct Waveform : UIViewRepresentable {

    var samples: [Float]
    var constants: Constants

    public init(samples: [Float], constants: Constants) {
        self.samples = samples
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

    public func makeUIView(context: Context) -> some UIView {
        let metalView = MTKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768),
                                device: MTLCreateSystemDefaultDevice()!)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        metalView.delegate = context.coordinator.renderer
        return metalView
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        let renderer = context.coordinator.renderer
        renderer.constants = constants
        renderer.set(samples: samples, binSize: Int(CGFloat(samples.count) / uiView.frame.width))
        uiView.setNeedsDisplay()
    }

}
#endif
