import AVFoundation
import SwiftUI
import Waveform

struct ContentView: View {

    var samples: [Float] {
        var s: [Float] = []
        let size = 4410
        for i in 0..<size {
            let sine = sin(Float(i * 2) * .pi / Float(size)) * 0.9
            s.append(sine + 0.1 * Float.random(in: -1...1))
        }
        return s
    }

    var fileSamples: [Float] {
        let url = Bundle.main.url(forResource: "beat", withExtension: "aiff")!
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
        return leftSamples
    }
    var body: some View {
        VStack {

            Waveform(samples: samples)
            Waveform(samples: fileSamples)

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
