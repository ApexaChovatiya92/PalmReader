//
//  EdgeDetector.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import CoreImage
import UIKit

public final class EdgeDetector {
    private let context = CIContext()
    
    public init() {}
    
    /// Computes edge gradients using CIEdges filter
    public func detectEdges(in image: UIImage, intensity: Float = 2.0) -> UIImage? {
        guard let ciInput = CIImage(image: image) else { return nil }
        
        let edgesFilter = CIFilter(name: "CIEdges")
        edgesFilter?.setValue(ciInput, forKey: kCIInputImageKey)
        edgesFilter?.setValue(intensity, forKey: kCIInputIntensityKey)
        
        guard let output = edgesFilter?.outputImage,
              let cgImage = context.createCGImage(output, from: ciInput.extent) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}
