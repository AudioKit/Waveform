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

        texture = device.makeTexture(descriptor: textureDesc)
        XCTAssertNotNil(texture)

        pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].loadAction = .clear
    }
    
    func writeCGImage(image: CGImage, url: CFURL) {
        let dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        assert(CGImageDestinationFinalize(dest))
    }
    
    func showTexture(texture: MTLTexture, name: String) {
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        print("saving to \(tmpURL)")
        writeCGImage(image: texture.cgImage, url: tmpURL as CFURL)
    }

    func render(minValues: [Float], maxValues: [Float]) {

        let renderer = Renderer(device: device)

        minValues.withUnsafeBufferPointer { ptr in
            renderer.minWaveformBuffer = device.makeBuffer(bytes: ptr.baseAddress!,
                                                        length: Int(minValues.count) * MemoryLayout<Float>.size)
        }

        maxValues.withUnsafeBufferPointer { ptr in
            renderer.maxWaveformBuffer = device.makeBuffer(bytes: ptr.baseAddress!,
                                                           length: Int(maxValues.count) * MemoryLayout<Float>.size)
        }

        let commandBuffer = queue.makeCommandBuffer()!
        renderer.encode(to: commandBuffer, pass: pass)

        let blit = commandBuffer.makeBlitCommandEncoder()!
        blit.synchronize(resource: texture)
        blit.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        XCTAssertFalse(texture.isBlack)

        showTexture(texture: texture, name: "Waveform.png")

    }

    func testRenderBasic() throws {

        let minSamples: [Float] = [-0.1, -0.2, -0.1, -0.1]
        let maxSamples: [Float] = [0.1, 0.1, 0.2, 0.1]

        render(minValues: minSamples, maxValues: maxSamples)
    }

    func binMin(samples: [Float], binSize: Int) -> [Float] {
        var out: [Float] = []
        for bin in 0..<samples.count/binSize {
            out.append(samples[(bin*binSize) ..< ((bin+1)*binSize)].min()!)
        }
        return out
    }

    func binMax(samples: [Float], binSize: Int) -> [Float] {
        var out: [Float] = []
        for bin in 0..<samples.count/binSize {
            out.append(samples[(bin*binSize) ..< ((bin+1)*binSize)].max()!)
        }
        return out
    }
    
    func testRenderBeat() throws {
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
        
        let leftChannelData = buffer.floatChannelData![0]

        var leftSamples: [Float] = []
        for i in 0..<Int(buffer.frameLength) {
            leftSamples.append(leftChannelData[i*Int(buffer.stride)])
        }

        let binSize = leftSamples.count / 2048 // four bins per pixel for AA
        let minSamples = binMin(samples: leftSamples, binSize: binSize)
        let maxSamples = binMax(samples: leftSamples, binSize: binSize)

        render(minValues: minSamples, maxValues: maxSamples)

    }
}
