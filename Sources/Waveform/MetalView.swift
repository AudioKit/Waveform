// Copyright AudioKit. All Rights Reserved. Revision History at http://github.com/AudioKit/Waveform/

import Foundation
import UIKit

#if os(iOS)
class MetalView: UIView {

    var renderer: Renderer?

    @objc static override var layerClass: AnyClass {
        CAMetalLayer.self
    }

    var metalLayer: CAMetalLayer {
        layer as! CAMetalLayer
    }

    override func draw(_ rect: CGRect) {
        render()
    }

    override func draw(_ layer: CALayer, in ctx: CGContext) {
        render()
    }

    override func display(_ layer: CALayer) {
        render()
    }

    func render() {
        guard let renderer else { return }
        renderer.draw(to: metalLayer)
    }

    func resizeDrawable() {
        let scaleFactor = self.window?.screen.nativeScale ?? 1

        var newSize = bounds.size
        newSize.width *= scaleFactor
        newSize.height *= scaleFactor

        if newSize.width <= 0 || newSize.height <= 0 {
            return
        }

        if newSize.width == metalLayer.drawableSize.width &&
            newSize.height == metalLayer.drawableSize.height {
            return
        }

        metalLayer.drawableSize = newSize

        setNeedsDisplay()
    }

    @objc override var frame: CGRect {
        get { super.frame }
        set {
            super.frame = newValue
            resizeDrawable()
        }
    }

    @objc override func layoutSubviews() {
        super.layoutSubviews()
        resizeDrawable()
    }

    @objc override var bounds: CGRect {
        get { super.bounds }
        set {
            super.bounds = newValue
            resizeDrawable()
        }
    }

}
#endif
