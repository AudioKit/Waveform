// swift-tools-version: 5.7

import PackageDescription

let package = Package(name: "Waveform", products: [ .library(name: "Waveform", targets: ["Waveform"])],
    targets: [
        .target(name: "Waveform", dependencies: []),
        .testTarget(name: "WaveformTests", dependencies: ["Waveform"], resources: [.copy("beat.aiff")]),
    ]
)
