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
        #if os(macOS)
        let dest = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, nil)!
        CGImageDestinationAddImage(dest, image, nil)
        assert(CGImageDestinationFinalize(dest))
        #endif
    }
    
    func showTexture(texture: MTLTexture, name: String) {
        let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        print("saving to \(tmpURL)")
        writeCGImage(image: texture.cgImage, url: tmpURL as CFURL)
    }

    func render(samples: [Float]) {

        let renderer = Renderer(device: device)
        
        renderer.set(samples: SampleBuffer(samples: samples), start: 0, length: samples.count)

        let commandBuffer = queue.makeCommandBuffer()!
        renderer.encode(to: commandBuffer, pass: pass, width: 512)

        #if os(macOS)
        let blit = commandBuffer.makeBlitCommandEncoder()!
        blit.synchronize(resource: texture)
        blit.endEncoding()
        #endif

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        XCTAssertFalse(texture.isBlack)

        showTexture(texture: texture, name: "Waveform.png")

    }
    
    func testRenderBeat() throws {
        guard let url = Bundle.module.url(forResource: "beat", withExtension: "aiff") else {
            XCTFail()
            return
        }
        
        let file = try! AVAudioFile(forReading: url)
        
        let stereo = file.toFloatChannelData()!

        render(samples: stereo[0])

    }
}
