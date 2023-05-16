// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import Foundation
import Metal
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Returns the minimums of chunks of binSize.
func binMin(samples: [Float], binSize: Int) -> [Float] {
    var out: [Float] = .init(repeating: 0.0, count: samples.count / binSize)

    // Note: we have to use a dumb while loop to avoid swift's Range and have
    //       decent perf in debug.
    var bin = 0
    while bin < out.count {

        // Note: we could do the following but it's too slow in debug
        // out[bin] = samples[(bin * binSize) ..< ((bin + 1) * binSize)].min()!

        var v = Float.greatestFiniteMagnitude
        let start: Int = bin * binSize
        let end: Int = (bin + 1) * binSize
        var i = start
        while i < end {
            v = min(samples[i], v)
            i += 1
        }
        out[bin] = v
        bin += 1
    }
    return out
}

/// Returns the maximums of chunks of binSize.
func binMax(samples: [Float], binSize: Int) -> [Float] {
    var out: [Float] = .init(repeating: 0.0, count: samples.count / binSize)

    // Note: we have to use a dumb while loop to avoid swift's Range and have
    //       decent perf in debug.
    var bin = 0
    while bin < out.count {

        // Note: we could do the following but it's too slow in debug
        // out[bin] = samples[(bin * binSize) ..< ((bin + 1) * binSize)].max()!

        var v = -Float.greatestFiniteMagnitude
        let start: Int = bin * binSize
        let end: Int = (bin + 1) * binSize
        var i = start
        while i < end {
            v = max(samples[i], v)
            i += 1
        }
        out[bin] = v
        bin += 1
    }
    return out
}

extension MTLDevice {
    func makeBuffer(_ values: [Float]) -> MTLBuffer? {
        makeBuffer(bytes: values, length: MemoryLayout<Float>.size * values.count)
    }
}

public extension MTLRenderCommandEncoder {
    func setFragmentBytes<T>(_ value: T, index: Int) {
        var copy = value
        setFragmentBytes(&copy, length: MemoryLayout<T>.size, index: index)
    }

    func setFragmentBytes<T>(_ value: T, index: Int32) {
        var copy = value
        setFragmentBytes(&copy, length: MemoryLayout<T>.size, index: Int(index))
    }
}

extension Color {
    var components: SIMD4<Float> {

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if canImport(UIKit)
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        #elseif canImport(AppKit)
        NSColor(self).usingColorSpace(.deviceRGB)!.getRed(&r, green: &g, blue: &b, alpha: &a)
        #endif

        return .init(Float(r), Float(g), Float(b), Float(a))
    }
}
