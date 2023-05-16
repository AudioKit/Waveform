// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import AVFoundation
import MetalKit
import SwiftUI

#if os(macOS)
/// Waveform SwiftUI View
public struct Waveform: NSViewRepresentable {
    var samples: SampleBuffer
    var start: Int
    var length: Int
    var constants: Constants = Constants()


    /// Initialize the waveform
    /// - Parameters:
    ///   - samples: All samples able to be displayed
    ///   - start: Which sample on which to start displaying samples
    ///   - length: The width of the entire waveform in samples
    ///   - constants: Look and feel parameters for the waveform
    public init(samples: SampleBuffer, start: Int = 0, length: Int = 0) {
        self.samples = samples
        self.start = start
        if length > 0 {
            self.length = min(length, samples.samples.count - start)
        } else {
            self.length = samples.samples.count - start
        }
    }

    /// Class required by NSViewRepresentable
    public class Coordinator {
        var renderer: Renderer

        init(constants: Constants) {
            renderer = Renderer(device: MTLCreateSystemDefaultDevice()!)
            renderer.constants = constants
        }
    }

    /// Required by NSViewRepresentable
    public func makeCoordinator() -> Coordinator {
        return Coordinator(constants: constants)
    }

    /// Required by NSViewRepresentable
    public func makeNSView(context: Context) -> some NSView {
        let metalView = MTKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768),
                                device: MTLCreateSystemDefaultDevice()!)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        metalView.delegate = context.coordinator.renderer
        metalView.layer?.isOpaque = false
        return metalView
    }

    /// Required by NSViewRepresentable
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        let renderer = context.coordinator.renderer
        renderer.constants = constants
        Task {
            await renderer.set(samples: samples,
                               start: start,
                               length: length)
            nsView.setNeedsDisplay(nsView.bounds)
        }
        nsView.setNeedsDisplay(nsView.bounds)
    }
}
#else
/// Waveform SwiftUI View
public struct Waveform: UIViewRepresentable {
    var samples: SampleBuffer
    var start: Int
    var length: Int
    var constants: Constants = Constants()

    /// Initialize the waveform
    /// - Parameters:
    ///   - samples: All samples able to be displayed
    ///   - start: Which sample on which to start displaying samples
    ///   - length: The width of the entire waveform in samples
    ///   - constants: Look and feel parameters for the waveform
    public init(samples: SampleBuffer, start: Int = 0, length: Int = 0) {
        self.samples = samples
        self.start = start
        if length > 0 {
            self.length = length
        } else {
            self.length = samples.samples.count
        }
    }

    /// Required by UIViewRepresentable
    public class Coordinator {
        var renderer: Renderer

        init(constants: Constants) {
            renderer = Renderer(device: MTLCreateSystemDefaultDevice()!)
        }
    }

    /// Required by UIViewRepresentable
    public func makeCoordinator() -> Coordinator {
        return Coordinator(constants: constants)
    }

    /// Required by UIViewRepresentable
    public func makeUIView(context: Context) -> some UIView {
        let metalView = MTKView(frame: CGRect(x: 0, y: 0, width: 1024, height: 768),
                                device: MTLCreateSystemDefaultDevice()!)
        metalView.enableSetNeedsDisplay = true
        metalView.isPaused = true
        metalView.delegate = context.coordinator.renderer
        metalView.layer.isOpaque = false
        return metalView
    }

    /// Required by UIViewRepresentable
    public func updateUIView(_ uiView: UIViewType, context: Context) {
        let renderer = context.coordinator.renderer
        renderer.constants = constants
        Task {
            await renderer.set(samples: samples,
                               start: start,
                               length: length)
            uiView.setNeedsDisplay()
        }
        uiView.setNeedsDisplay()
    }
}
#endif

extension Waveform {
    /// Modifer to change the foreground color of the wheel
    /// - Parameter foregroundColor: foreground color
    public func foregroundColor(_ foregroundColor: Color) -> Waveform {
        var copy = self
        copy.constants = Constants(color: foregroundColor)
        return copy
    }
}
