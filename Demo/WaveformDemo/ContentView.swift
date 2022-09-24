import SwiftUI
import Waveform

struct ContentView: View {
    var body: some View {
        VStack {
            Waveform(constants: Constants())
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
