// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Waveform",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [.library(name: "Waveform", targets: ["Waveform"])],
    targets: [
        .target(name: "Waveform", resources: [.process("Waveform.docc")]),
        .testTarget(name: "WaveformTests", dependencies: ["Waveform"], resources: [.copy("beat.aiff")]),
    ]
)
