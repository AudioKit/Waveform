// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import Foundation
import Metal

func binMin(samples: [Float], binSize: Int) -> [Float] {
    var out: [Float] = []
    for bin in 0 ..< samples.count / binSize {
        out.append(samples[(bin * binSize) ..< ((bin + 1) * binSize)].min()!)
    }
    return out
}

func binMax(samples: [Float], binSize: Int) -> [Float] {
    var out: [Float] = []
    for bin in 0 ..< samples.count / binSize {
        out.append(samples[(bin * binSize) ..< ((bin + 1) * binSize)].max()!)
    }
    return out
}

extension MTLDevice {
    func makeBuffer(_ values: [Float]) -> MTLBuffer? {
        makeBuffer(bytes: values, length: MemoryLayout<Float>.size * values.count)
    }
}
