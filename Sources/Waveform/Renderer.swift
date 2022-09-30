

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
    
    var minBuffers: [MTLBuffer] = []
    var maxBuffers: [MTLBuffer] = []

    var lastSamples: [Float] = []
    var start = 0
    var length = 0

    init(device: MTLDevice) {
        self.device = device
        queue = device.makeCommandQueue()
        
        let library = try! device.makeDefaultLibrary(bundle: Bundle.module)
        
        let rpd = MTLRenderPipelineDescriptor()
        rpd.vertexFunction = library.makeFunction(name: "waveform_vert")
        rpd.fragmentFunction = library.makeFunction(name: "waveform_frag")
        rpd.colorAttachments[0].pixelFormat = .bgra8Unorm

        pipeline = try! device.makeRenderPipelineState(descriptor: rpd)
        
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
    
    func selectBuffers(width: CGFloat) -> (MTLBuffer, MTLBuffer) {
        
        var level = 0
        for (minBuffer, maxBuffer) in zip(minBuffers, maxBuffers) {
            if CGFloat(minBuffer.length / MemoryLayout<Float>.size) < width {
                print("selected level \(level)")
                return (minBuffer, maxBuffer)
            }
            level += 1
        }
        
        return (minBuffers.last!, maxBuffers.last!)
    }
    
    func encode(to commandBuffer: MTLCommandBuffer,
                pass: MTLRenderPassDescriptor,
                width: CGFloat) {
        
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
        
        let (minBuffer, maxBuffer) = selectBuffers(width: width)

        let enc = commandBuffer.makeRenderCommandEncoder(descriptor: pass)!
        enc.setRenderPipelineState(pipeline)
        enc.setFragmentBuffer(minBuffer, offset: 0, index: 0)
        enc.setFragmentBuffer(maxBuffer, offset: 0, index: 1)
        assert(minBuffer.length == maxBuffer.length)
        var count = minBuffer.length / MemoryLayout<Float>.size
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
            
            encode(to: commandBuffer, pass: renderPassDescriptor, width: size.width)

            commandBuffer.present(currentDrawable)
        }
        commandBuffer.commit()

    }

    func set(samples: [Float], start: Int, length: Int) {
        self.start = start
        self.length = length
        guard samples != lastSamples else { return }
        lastSamples = samples
        minBuffers.removeAll()
        maxBuffers.removeAll()
        
        var minSamples = samples
        var maxSamples = samples
        
        var s = samples.count
        while s > 2 {
            print("samples: \(s)")
            minSamples = binMin(samples: minSamples, binSize: 2)
            maxSamples = binMax(samples: maxSamples, binSize: 2)
            s /= 2
            
            minBuffers.append(device.makeBuffer(minSamples)!)
            maxBuffers.append(device.makeBuffer(maxSamples)!)
        }
    }
}
