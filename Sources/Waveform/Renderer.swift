// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import Foundation
import Metal
import MetalKit
import SwiftUI

let MaxBuffers = 3

/// Parameters defining the look and feel of the waveform
struct Constants {

    /// Foreground color
    var color = SIMD4<Float>(1,1,1,1)

    /// Initialize the Constants structure
    /// - Parameter color: Foreground color
    init(color: Color = .white) {
        self.color = color.components
    }
}

class Renderer: NSObject, MTKViewDelegate {
    var device: MTLDevice!
    var queue: MTLCommandQueue!
    var pipeline: MTLRenderPipelineState!
    var source = ""
    public var constants = Constants()

    private let inflightSemaphore = DispatchSemaphore(value: MaxBuffers)

    var minBuffers: [MTLBuffer] = []
    var maxBuffers: [MTLBuffer] = []

    var samples = SampleBuffer(samples: [0])
    var start = 0
    var length = 0

    init(device: MTLDevice) {
        self.device = device
        queue = device.makeCommandQueue()

        let library = try! device.makeDefaultLibrary(bundle: Bundle.module)

        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = library.makeFunction(name: "waveform_vert")
        rpd.fragmentFunction = library.makeFunction(name: "waveform_frag")

        let colorAttachment = rpd.colorAttachments[0]!
        colorAttachment.pixelFormat = .bgra8Unorm
        colorAttachment.isBlendingEnabled = true
        colorAttachment.sourceRGBBlendFactor = .sourceAlpha
        colorAttachment.sourceAlphaBlendFactor = .sourceAlpha
        colorAttachment.destinationRGBBlendFactor = .oneMinusSourceAlpha
        colorAttachment.destinationAlphaBlendFactor = .oneMinusSourceAlpha

        pipeline = try! device.makeRenderPipelineState(descriptor: rpd)

        minBuffers = [device.makeBuffer([0])!]
        maxBuffers = [device.makeBuffer([0])!]

        super.init()
    }

    func mtkView(_: MTKView, drawableSizeWillChange _: CGSize) {}

    func selectBuffers(width: CGFloat) -> (MTLBuffer?, MTLBuffer?) {
        var level = 0
        for (minBuffer, maxBuffer) in zip(minBuffers, maxBuffers) {
            if CGFloat(minBuffer.length / MemoryLayout<Float>.size) < width {
                return (minBuffer, maxBuffer)
            }
            level += 1
        }

        // Use optional binding to safely access last element of each array
        if let minBufferLast = minBuffers.last, let maxBufferLast = maxBuffers.last {
            return (minBufferLast, maxBufferLast)
        } else {
            // If either array is empty, return nil
            return (nil, nil)
        }
    }
    
    func encode(to commandBuffer: MTLCommandBuffer,
                pass: MTLRenderPassDescriptor,
                width: CGFloat)
    {
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)

        let highestResolutionCount = Float(samples.samples.count)
        let startFactor = Float(start) / highestResolutionCount
        let lengthFactor = Float(length) / highestResolutionCount

        let (minBufferOpt, maxBufferOpt) = selectBuffers(width: width / CGFloat(lengthFactor))
        guard let minBuffer = minBufferOpt, let maxBuffer = maxBufferOpt else {
            //early return to gracefully fail.
            return
        }

        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
        enc.setRenderPipelineState(pipeline)

        let bufferLength = Float(minBuffer.length / MemoryLayout<Float>.size)
        let bufferStart = Int(bufferLength * startFactor)
        var bufferCount = Int(bufferLength * lengthFactor)

        enc.setFragmentBuffer(minBuffer, offset: bufferStart * MemoryLayout<Float>.size, index: 0)
        enc.setFragmentBuffer(maxBuffer, offset: bufferStart * MemoryLayout<Float>.size, index: 1)
        assert(minBuffer.length == maxBuffer.length)
        enc.setFragmentBytes(&bufferCount, length: MemoryLayout<Int32>.size, index: 2)
        let c = [constants]
        enc.setFragmentBytes(c, length: MemoryLayout<Constants>.size, index: 3)
        enc.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        enc.endEncoding()
    }

    func draw(in view: MTKView) {
        let size = view.frame.size
        let w = Float(size.width)
        let h = Float(size.height)
        // let scale = Float(view.contentScaleFactor)

        if w == 0 || h == 0 {
            return
        }

        // use semaphore to encode 3 frames ahead
        _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)

        let commandBuffer = queue.makeCommandBuffer()!

        let semaphore = inflightSemaphore
        commandBuffer.addCompletedHandler { _ in
            semaphore.signal()
        }

        if let renderPassDescriptor = view.currentRenderPassDescriptor, let currentDrawable = view.currentDrawable {
            encode(to: commandBuffer, pass: renderPassDescriptor, width: size.width)

            commandBuffer.present(currentDrawable)
        }
        commandBuffer.commit()
    }

    func set(samples: SampleBuffer, start: Int, length: Int) {
        self.start = start
        self.length = length
        if samples === self.samples {
            return
        }
        self.samples = samples

        let buffers = makeBuffers(device: device, samples: samples)
        self.minBuffers = buffers.0
        self.maxBuffers = buffers.1
    }
}

func makeBuffers(device: MTLDevice, samples: SampleBuffer) -> ([MTLBuffer], [MTLBuffer]) {
    var minSamples = samples.samples
    var maxSamples = samples.samples

    var s = samples.samples.count
    var minBuffers: [MTLBuffer] = []
    var maxBuffers: [MTLBuffer] = []
    while s > 2 {
        minBuffers.append(device.makeBuffer(minSamples)!)
        maxBuffers.append(device.makeBuffer(maxSamples)!)

        minSamples = binMin(samples: minSamples, binSize: 2)
        maxSamples = binMax(samples: maxSamples, binSize: 2)
        s /= 2
    }
    return (minBuffers, maxBuffers)
}
