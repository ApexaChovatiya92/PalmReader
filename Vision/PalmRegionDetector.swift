//
//  PalmRegionDetector.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import CoreGraphics
import UIKit

public struct PalmBoundingRegion {
    public var rect: CGRect
    public var center: CGPoint
    public var rotationAngle: CGFloat
    public var normalizedPolygon: [CGPoint]
}

public final class PalmRegionDetector {
    public init() {}
    
    /// Computes the exact palm region from recognized hand landmarks
    public func detectPalmRegion(from landmarks: HandLandmarks) -> PalmBoundingRegion {
        // Key landmark bounds: wrist, thumbCMC, indexMCP, littleMCP
        let wrist = landmarks.wrist
        let indexMCP = landmarks.indexMCP
        let littleMCP = landmarks.littleMCP
        let thumbCMC = landmarks.thumbCMC
        
        // Palm polygon boundary
        let polygon = [wrist, thumbCMC, indexMCP, landmarks.middleMCP, landmarks.ringMCP, littleMCP]
        
        let minX = polygon.map(\.x).min() ?? 0.2
        let maxX = polygon.map(\.x).max() ?? 0.8
        let minY = polygon.map(\.y).min() ?? 0.1
        let maxY = polygon.map(\.y).max() ?? 0.65
        
        // Expand slightly for edge safety (10% padding)
        let padX = (maxX - minX) * 0.10
        let padY = (maxY - minY) * 0.10
        
        let palmRect = CGRect(
            x: max(0, minX - padX),
            y: max(0, minY - padY),
            width: min(1.0, (maxX - minX) + padX * 2),
            height: min(1.0, (maxY - minY) + padY * 2)
        )
        
        return PalmBoundingRegion(
            rect: palmRect,
            center: landmarks.palmCenter,
            rotationAngle: landmarks.tiltAngle,
            normalizedPolygon: polygon
        )
    }
    
    /// Crops and rotates the palm region from an original full frame UIImage
    public func cropAndNormalizePalm(image: UIImage, region: PalmBoundingRegion) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let imgWidth = CGFloat(cgImage.width)
        let imgHeight = CGFloat(cgImage.height)
        
        // Convert normalized coordinates (Vision bottom-left origin) to CGImage pixel coordinates
        let pixelRect = CGRect(
            x: region.rect.origin.x * imgWidth,
            y: (1.0 - region.rect.origin.y - region.rect.height) * imgHeight,
            width: region.rect.width * imgWidth,
            height: region.rect.height * imgHeight
        )
        
        guard let cropped = cgImage.cropping(to: pixelRect) else {
            return nil
        }
        
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}
