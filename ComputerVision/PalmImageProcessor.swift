//
//  PalmImageProcessor.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import CoreImage
import UIKit

public final class PalmImageProcessor {
    private let context = CIContext(options: [.useSoftwareRenderer: false])
    
    public init() {}
    
    /// Processes RGB palm image into an edge-enhanced grayscale representation optimized for line tracing
    public func enhancePalmLines(image: UIImage) -> UIImage? {
        guard let ciInput = CIImage(image: image) else { return nil }
        
        // 1. Grayscale conversion
        let monoFilter = CIFilter(name: "CIPhotoEffectMono")
        monoFilter?.setValue(ciInput, forKey: kCIInputImageKey)
        guard let monoOutput = monoFilter?.outputImage else { return nil }
        
        // 2. High Contrast Adjustment
        let contrastFilter = CIFilter(name: "CIColorControls")
        contrastFilter?.setValue(monoOutput, forKey: kCIInputImageKey)
        contrastFilter?.setValue(1.6, forKey: kCIInputContrastKey)
        contrastFilter?.setValue(-0.05, forKey: kCIInputBrightnessKey)
        guard let contrastOutput = contrastFilter?.outputImage else { return nil }
        
        // 3. Noise reduction with subtle Gaussian Blur
        let blurFilter = CIFilter(name: "CIGaussianBlur")
        blurFilter?.setValue(contrastOutput, forKey: kCIInputImageKey)
        blurFilter?.setValue(1.0, forKey: kCIInputRadiusKey)
        guard let blurred = blurFilter?.outputImage else { return nil }
        
        // 4. Unsharp Mask to sharpen palm crease edges
        let unsharpFilter = CIFilter(name: "CIUnsharpMask")
        unsharpFilter?.setValue(blurred, forKey: kCIInputImageKey)
        unsharpFilter?.setValue(2.5, forKey: kCIInputRadiusKey)
        unsharpFilter?.setValue(0.8, forKey: kCIInputIntensityKey)
        guard let finalOutput = unsharpFilter?.outputImage else { return nil }
        
        guard let cgImage = context.createCGImage(finalOutput, from: ciInput.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
