import XCTest
@testable import Waveform
import AVFoundation

final class WaveformTests: XCTestCase {
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
    }
}
