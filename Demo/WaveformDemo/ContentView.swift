// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import AVFoundation
import SwiftUI
import Waveform

class WaveformDemoModel: ObservableObject {
    var samples: SampleBuffer

    init(file: AVAudioFile) {
        let stereo = file.floatChannelData()!
        samples = SampleBuffer(samples: stereo[0])
    }
}

func getFile() -> AVAudioFile {
    let url = Bundle.main.url(forResource: "Piano", withExtension: "mp3")!
    return try! AVAudioFile(forReading: url)
}

func clamp(_ x: Double, _ inf: Double, _ sup: Double) -> Double {
    max(min(x, sup), inf)
}

struct ContentView: View {
    @StateObject var model = WaveformDemoModel(file: getFile())

    @State var start = 0.0
    @State var length = 1.0

    let formatter = NumberFormatter()
    var body: some View {
        VStack {
            ZStack(alignment: .leading) {
                Waveform(samples: model.samples).foregroundColor(.cyan)
                    .padding(.vertical, 5)
                MinimapView(start: $start, length: $length)
            }
            .frame(height: 100)
            .padding()
            Waveform(samples: model.samples,
                     start: Int(start * Double(model.samples.count - 1)),
                     length: Int(length * Double(model.samples.count)))
            .foregroundColor(.blue)
        }
        .padding()
    }
}
