import AVFoundation
import SwiftUI
import Waveform

class WaveformDemoModel: ObservableObject {
    var samples: SampleBuffer

    init() {
        var s: [Float] = []
        let size = 44100
        for i in 0..<size {
            let sine = sin(Float(i * 2) * .pi / Float(size)) * 0.9
            s.append(sine + 0.1 * Float.random(in: -1...1))
        }
        samples = SampleBuffer(samples: s)
    }
}

struct ContentView: View {

    var file: AVAudioFile {
        let url = Bundle.main.url(forResource: "beat", withExtension: "aiff")!
        return try! AVAudioFile(forReading: url)

    }

    @StateObject var model = WaveformDemoModel()

    @State var start = 0.0
    @State var length = 0.0
    let formatter = NumberFormatter()
    var body: some View {
        VStack {

            Waveform(samples: model.samples, start: Int(start), length: Int(length))
//            Waveform(file: file, start: sampleCount, length: sampleCount)

            HStack {
                Slider(value: $start, in: 0...Double(model.samples.count-1))
                Slider(value: $length, in: 0...Double(model.samples.count-1))
            }

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
