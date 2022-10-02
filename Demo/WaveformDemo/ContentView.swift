import AVFoundation
import SwiftUI
import Waveform

class WaveformDemoModel: ObservableObject {
    var samples: SampleBuffer

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

    let indicatorSize = 10.0

    let formatter = NumberFormatter()
    var body: some View {
        VStack {

            GeometryReader { gp in
                ZStack(alignment: .leading) {
                    Waveform(samples: model.samples)
                    ZStack(alignment: .leading)  {
                        RoundedRectangle(cornerRadius: indicatorSize)
                            .frame(width: max(3 * indicatorSize, min(gp.size.width * (length + dragLength),
                                              gp.size.width - min(1, max(0, (start + dragStart))) * gp.size.width)))
                            .offset(x: min(gp.size.width - 3 * indicatorSize, min(1, max(0, (start + dragStart))) * gp.size.width))
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
                                    if start > 1 {
                                        start = 1
                                    }
                                    length = min(length, 1 - start)
                                }

                            )
                        RoundedRectangle(cornerRadius: indicatorSize)
                            .foregroundColor(.black)
                            .frame(width: indicatorSize).opacity(0.3)
                            .offset(x: max(0, min(1, max(0, start + dragStart) + length + dragLength) * gp.size.width - 3 * indicatorSize))
                            .padding(indicatorSize)
                            .gesture(DragGesture()
                                .updating($dragLength) { drag, dragLength, _ in
                                    dragLength = (drag.location.x - drag.startLocation.x) / gp.size.width
                                }
                                .onEnded { drag in
                                    length += (drag.location.x - drag.startLocation.x) / gp.size.width
                                    if length < 0 {
                                        print("resetting length")
                                        length = 1
                                    }
                                }

                            )

                    }
                }
            }
            .frame(height: 100)
            Waveform(samples: model.samples,
                     start: Int(max(0, min(1,(start + dragStart))) * Double(model.samples.count)),
                     length: Int(max(0, min(1, (length + dragLength))) * Double(model.samples.count)))
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
