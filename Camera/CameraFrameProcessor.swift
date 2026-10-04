//
//  CameraFrameProcessor.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import CoreMedia
import CoreImage
import UIKit

public final class CameraFrameProcessor {
    private let context = CIContext()
    
    public init() {}
    
    /// Converts a CMSampleBuffer to a CGImage efficiently
    public func processSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        return context.createCGImage(ciImage, from: ciImage.extent)
    }
}
