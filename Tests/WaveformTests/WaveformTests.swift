import XCTest
@testable import Waveform
import AVFoundation
import Metal
import MetalKit
import CoreFoundation
import CoreGraphics

final class WaveformTests: XCTestCase {
    let device = MTLCreateSystemDefaultDevice()!
    var queue: MTLCommandQueue!
    var texture: MTLTexture!
    var pass: MTLRenderPassDescriptor!
    
    override func setUp() {
        
        queue = device.makeCommandQueue()!

        let w = 512
        let h = 512

        let textureDesc = MTLTextureDescriptor()
        textureDesc.pixelFormat = .bgra8Unorm
        textureDesc.width = w
        textureDesc.height = h

        textureDesc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        textureDesc.storageMode = .shared

        texture = device.makeTexture(descriptor: textureDesc)
        XCTAssertNotNil(texture)

        pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1)
    }
    
    func writeCGImage(image: CGImage, url: CFURL) {
        let dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        assert(CGImageDestinationFinalize(dest))
    }
    
    func testRenderWaveform() throws {
        guard let url = Bundle.module.url(forResource: "beat", withExtension: "aiff") else {
            XCTFail()
            return
        }
        
        let file = try! AVAudioFile(forReading: url)
        
        let audioFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                        sampleRate: file.fileFormat.sampleRate,
                                        channels: file.fileFormat.channelCount, interleaved: false)!
        
        let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(file.length))!
        
        try! file.read(into: buffer)
        
        let renderer = Renderer(device: device)
        
        let leftChannelData = buffer.floatChannelData![0]
        
        renderer.minWaveformBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(leftChannelData),
                                                    length: Int(file.length) * MemoryLayout<Float>.size)
        renderer.maxWaveformBuffer = device.makeBuffer(bytes: UnsafeMutablePointer(leftChannelData),
                                                    length: Int(file.length) * MemoryLayout<Float>.size)
        
        let commandBuffer = queue.makeCommandBuffer()!
        renderer.encode(to: commandBuffer, pass: pass)
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        let tex = texture
        print("done")
    }
}
