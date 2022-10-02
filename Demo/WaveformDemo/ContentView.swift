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
    @GestureState var dragStart = 0.0
    @State var length = 1.0
    @GestureState var dragLength = 0.0

    let formatter = NumberFormatter()
    var body: some View {
        VStack {

            GeometryReader { gp in
                ZStack(alignment: .leading) {
                    Waveform(samples: model.samples)
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(width: min(gp.size.width * length,
                                              gp.size.width - max(0, (start + dragStart) * gp.size.width)))
                            .offset(x: max(0, (start + dragStart) * gp.size.width))
                            .opacity(0.5)
                            .gesture(DragGesture()
                                .updating($dragStart) { drag, dragStart, _ in
                                    dragStart = (drag.location.x - drag.startLocation.x) / gp.size.width
                                }
                                .onEnded { drag in
                                    start += (drag.location.x - drag.startLocation.x) / gp.size.width
                                    if start < 0 {
                                        start = 0.0
                                    }
                                }

                            )
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 10)
                                .foregroundColor(.black)
                                .frame(width: 10).opacity(0.3)
                                .padding(10)
                                .gesture(DragGesture()
                                    .updating($dragLength) { drag, dragLength, _ in
                                        print("x")
                                        dragLength = (drag.location.x - drag.startLocation.x) / gp.size.width
                                    }
                                    .onEnded { drag in
                                        length += (drag.location.x - drag.startLocation.x) / gp.size.width
                                        if length < 0.01 {
                                            length = 0.01
                                        }
                                    }

                                )
                        }
                        .frame(width: min(gp.size.width * length,
                                          gp.size.width - max(0, (start + dragStart) * gp.size.width)))
                        .offset(x: max(0, (start + dragStart) * gp.size.width))
                    }
                }
            }
            .frame(height: 100)
            Waveform(samples: model.samples, start: Int(max(0, (start + dragStart)) * Double(model.samples.count)), length: Int(min(1, (length + dragLength)) * Double(model.samples.count)))

            HStack {
                Slider(value: $start)
                Slider(value: $length)
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
