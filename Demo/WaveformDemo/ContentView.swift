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

    @State var sampleCount = 20000
    var body: some View {
        VStack {

            Waveform(samples: model.samples, start: sampleCount, length: sampleCount)
//            Waveform(file: file, start: sampleCount, length: sampleCount)
                .gesture(DragGesture(minimumDistance: 0).onChanged { touch in
                    sampleCount += Int(touch.translation.width * 100)
                    print(sampleCount)

                })

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
