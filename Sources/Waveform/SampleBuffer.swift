
import Foundation

/// Immutable data for samples so we can quickly compare to see if we should recompute.
public class SampleBuffer {
    let samples: [Float]

    public init(samples: [Float]) {
        self.samples = samples
    }

    public var count: Int {
        samples.count
    }
}
