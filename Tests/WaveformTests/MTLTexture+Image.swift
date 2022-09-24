

import Foundation
import Metal
import CoreGraphics

func createImage(data: UnsafeMutablePointer<UInt8>, w: Int, h: Int) -> CGImage {

    let dataSize = 4 * w * h

    let provider = CGDataProvider(dataInfo: nil, data: data, size: dataSize, releaseData: {_,_,_ in })!

    let colorSpace = CGColorSpaceCreateDeviceRGB()

    let image = CGImage(width: w,
                        height: h,
                        bitsPerComponent: 8,
                        bitsPerPixel: 32,
                        bytesPerRow: w*4,
                        space: colorSpace,
                        bitmapInfo: .init(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                        provider: provider,
                        decode: nil,
                        shouldInterpolate: true,
                        intent: .defaultIntent)!

    return image

}

extension MTLTexture {
    var cgImage: CGImage {
        
        let dataSize = width*height*4
        let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
        
        switch pixelFormat {
        case .bgra8Unorm:
            getBytes(ptr, bytesPerRow: width*4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        default:
            fatalError()
        }
        
        return createImage(data: ptr, w: width, h: height)
    }
    
    var isBlack: Bool {
        
        let dataSize = width*height*4
        let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
        defer {
            ptr.deallocate()
        }
        
        switch pixelFormat {
        case .bgra8Unorm:
            getBytes(ptr, bytesPerRow: width*4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        default:
            fatalError()
        }
        
        for x in 0..<dataSize {
            if ptr[x] != 0 {
                return false
            }
        }
        
        return true
    }
}
