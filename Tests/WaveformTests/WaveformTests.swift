import XCTest
@testable import Waveform

final class WaveformTests: XCTestCase {
    func testRenderWaveform() throws {
        let url = Bundle.module.url(forResource: "beat", withExtension: "aiff")
        XCTAssertNotNil(url)
    }
}
