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

    init(file: AVAudioFile) {
        let stereo = file.toFloatChannelData()!
        samples = SampleBuffer(samples: stereo[0])
    }
}

func getFile() -> AVAudioFile {
    let url = Bundle.main.url(forResource: "beat", withExtension: "aiff")!
    return try! AVAudioFile(forReading: url)
}

struct ContentView: View {

    @StateObject var model = WaveformDemoModel(file: getFile())

    @State var start = 0.0
    @State var newOffset = 0.0
    @State var length = 100000.0

    let formatter = NumberFormatter()
    var body: some View {
        VStack {

            GeometryReader { gp in
                ZStack(alignment: .leading) {
                    Waveform(samples: model.samples)
                    RoundedRectangle(cornerRadius: 10)
                        .frame(width: min(gp.size.width * length / Double(model.samples.count),
                                          gp.size.width - max(0, start * (gp.size.width / Double(model.samples.count))  + newOffset)))
                        .offset(x: max(0, start * (gp.size.width / Double(model.samples.count))  + newOffset))
                        .opacity(0.5)
                        .gesture(DragGesture()
                            .onChanged { drag in
                                newOffset = drag.location.x - drag.startLocation.x
                            }
                            .onEnded { _ in
                                start += newOffset / (gp.size.width / Double(model.samples.count))
                                if start < 0 {
                                    start = 0.0
                                }
                                newOffset = 0.0
                            }

                        )
                }
            }
            .frame(height: 100)
            Waveform(samples: model.samples, start: Int(start), length: Int(length))

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
