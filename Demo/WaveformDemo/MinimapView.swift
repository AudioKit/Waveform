// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import AVFoundation
import SwiftUI
import Waveform

struct MinimapView: View {
    @Binding var start: Double
    @Binding var length: Double

    @GestureState var initialStart: Double?
    @GestureState var initialLength: Double?

    let indicatorSize = 10.0

    var body: some View {
        GeometryReader { gp in
            RoundedRectangle(cornerRadius: indicatorSize)
                .frame(width: length * gp.size.width)
                .offset(x: start * gp.size.width)
                .opacity(0.3)
                .gesture(DragGesture()
                    .updating($initialStart) { _, state, _ in
                        if state == nil {
                            state = start
                        }
                    }
                    .onChanged { drag in
                        if let initialStart = initialStart {
                            start = clamp(initialStart + drag.translation.width / gp.size.width, 0, 1 - length)
                        }
                    }
                )

            RoundedRectangle(cornerRadius: indicatorSize)
                .foregroundColor(.white)
                .frame(width: indicatorSize).opacity(0.3)
                .offset(x: (start + length) * gp.size.width)
                .padding(indicatorSize)
                .gesture(DragGesture()
                    .updating($initialLength) { _, state, _ in
                        if state == nil {
                            state = length
                        }
                    }
                    .onChanged { drag in
                        if let initialLength = initialLength {
                            length = clamp(initialLength + drag.translation.width / gp.size.width, 0, 1 - start)
                        }
                    }
                )
        }
    }
}
