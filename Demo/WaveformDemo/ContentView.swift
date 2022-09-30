import AVFoundation
import SwiftUI
import Waveform

struct ContentView: View {

    var samples: [Float] {
        var s: [Float] = []
        let size = 44100
        for i in 0..<size {
            let sine = sin(Float(i * 2) * .pi / Float(size)) * 0.9
            s.append(sine + 0.1 * Float.random(in: -1...1))
        }
        return s
    }

    var file: AVAudioFile {
        let url = Bundle.main.url(forResource: "beat", withExtension: "aiff")!
        return try! AVAudioFile(forReading: url)

    }
    var body: some View {
        VStack {

            Waveform(samples: samples, start: 20000, length: 20000)
            Waveform(file: file, start: 20000, length: 20000)

        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
