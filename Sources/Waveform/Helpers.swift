// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import Foundation
import Metal
import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
