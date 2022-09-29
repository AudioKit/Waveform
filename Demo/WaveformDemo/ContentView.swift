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
    var body: some View {
        VStack {
            Waveform(samples: samples, constants: Constants())
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
