

import Foundation
import Metal
import MetalKit

let MaxBuffers = 3

public struct Constants {
    public init() {
        
    }
}

class Renderer: NSObject, MTKViewDelegate {

    var device: MTLDevice!
    var queue: MTLCommandQueue!
    var pipeline: MTLRenderPipelineState!
    var source = ""
    public var constants = Constants()

    private let inflightSemaphore = DispatchSemaphore(value: MaxBuffers)
    
    public var minWaveformBuffer: MTLBuffer!
    public var maxWaveformBuffer: MTLBuffer!

    init(device: MTLDevice) {
        self.device = device
        queue = device.makeCommandQueue()
        
        let library = try! device.makeDefaultLibrary(bundle: Bundle.module)
        
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = library.makeFunction(name: "waveform_vert")
        rpd.fragmentFunction = library.makeFunction(name: "waveform_frag")
        rpd.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipeline = try! device.makeRenderPipelineState(descriptor: rpd)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
    
    func encode(to commandBuffer: MTLCommandBuffer,
              pass: MTLRenderPassDescriptor) {
        
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)

        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentBuffer(minWaveformBuffer, offset: 0, index: 0)
        enc.setFragmentBuffer(maxWaveformBuffer, offset: 0, index: 1)
        assert(minWaveformBuffer.length == maxWaveformBuffer.length)
        var count = minWaveformBuffer.length / MemoryLayout<Float>.size
        enc.setFragmentBytes(&count, length: MemoryLayout<Int32>.size, index: 2)
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
            
            encode(to: commandBuffer, pass: renderPassDescriptor)

            commandBuffer.present(currentDrawable)
        }
        commandBuffer.commit()

    }
}
