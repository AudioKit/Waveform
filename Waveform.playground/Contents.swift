import PlaygroundSupport
import SwiftUI
import Waveform

struct WaveformDemoView: View {
    var samples: [Float] {
        var s: [Float] = []
        let size = 1000
        for i in 0 ..< size {
            let sine = sin(Float(i * 2) * .pi / Float(size)) * 0.9
            s.append(sine + 0.1 * Float.random(in: -1 ... 1))
        }
        return s
    }

    @State var start = 0.0
    @State var length = 1.0

    let formatter = NumberFormatter()
    var body: some View {
        Waveform(samples: SampleBuffer(samples: samples),
                 start: 0,
                 length: 1000)
            .padding()
    }
}

PlaygroundPage.current.setLiveView(WaveformDemoView().frame(width: 1100, height: 500))
PlaygroundPage.current.needsIndefiniteExecution = true
