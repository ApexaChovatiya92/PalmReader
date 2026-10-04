//
//  HandPoseDetector.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Vision
import CoreGraphics
import UIKit

public final class HandPoseDetector {
    private let handPoseRequest: VNDetectHumanHandPoseRequest
    
    public init() {
        handPoseRequest = VNDetectHumanHandPoseRequest()
        handPoseRequest.maximumHandCount = 1
    }
    
    public func detectHand(in cgImage: CGImage, orientation: CGImagePropertyOrientation = .up) -> HandLandmarks? {
        if let landmarks = performDetection(on: cgImage, orientation: orientation) {
            return landmarks
        }
        // Fallback to other orientations in case the photo was captured rotated
        let fallbacks: [CGImagePropertyOrientation] = [.right, .left, .down]
        for fallback in fallbacks where fallback != orientation {
            if let landmarks = performDetection(on: cgImage, orientation: fallback) {
                return landmarks
            }
        }
        #if targetEnvironment(simulator)
        // Simulator runtime does not include Apple Neural Engine hand-pose weights
        return Self.createMockLandmarks(for: .right)
        #else
        return nil
        #endif
    }
    
    public func detectHand(in pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) -> HandLandmarks? {
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                return nil
            }
            return extractLandmarks(from: observation)
        } catch {
            return nil
        }
    }
    
    private func performDetection(on cgImage: CGImage, orientation: CGImagePropertyOrientation) -> HandLandmarks? {
        let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])
        do {
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                return nil
            }
            return extractLandmarks(from: observation)
        } catch {
            return nil
        }
    }
    
    private func extractLandmarks(from observation: VNHumanHandPoseObservation) -> HandLandmarks? {
        guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
            return nil
        }
        
        func point(for key: VNHumanHandPoseObservation.JointName) -> (CGPoint, Float) {
            if let recognizedPoint = recognizedPoints[key], recognizedPoint.confidence > 0.15 {
                return (CGPoint(x: recognizedPoint.location.x, y: recognizedPoint.location.y), Float(recognizedPoint.confidence))
            }
            return (.zero, 0.0)
        }
        
        var totalConfidence: Float = 0
        var validPointsCount: Float = 0
        
        var (wrist, cWrist) = point(for: .wrist)
        var (thumbCMC, cTCMC) = point(for: .thumbCMC)
        let (thumbMP, cTMP) = point(for: .thumbMP)
        let (thumbIP, cTIP) = point(for: .thumbIP)
        let (thumbTip, cTTip) = point(for: .thumbTip)
        
        let (indexMCP, cIMCP) = point(for: .indexMCP)
        let (indexPIP, cIPIP) = point(for: .indexPIP)
        let (indexDIP, cIDIP) = point(for: .indexDIP)
        let (indexTip, cITip) = point(for: .indexTip)
        
        let (middleMCP, cMMCP) = point(for: .middleMCP)
        let (middlePIP, cMPIP) = point(for: .middlePIP)
        let (middleDIP, cMDIP) = point(for: .middleDIP)
        let (middleTip, cMTip) = point(for: .middleTip)
        
        let (ringMCP, cRMCP) = point(for: .ringMCP)
        let (ringPIP, cRPIP) = point(for: .ringPIP)
        let (ringDIP, cRDIP) = point(for: .ringDIP)
        let (ringTip, cRTip) = point(for: .ringTip)
        
        let (littleMCP, cLMCP) = point(for: .littleMCP)
        let (littlePIP, cLPIP) = point(for: .littlePIP)
        let (littleDIP, cLDIP) = point(for: .littleDIP)
        let (littleTip, cLTip) = point(for: .littleTip)
        
        let confidences = [cWrist, cTCMC, cTMP, cTIP, cTTip, cIMCP, cIPIP, cIDIP, cITip, cMMCP, cMPIP, cMDIP, cMTip, cRMCP, cRPIP, cRDIP, cRTip, cLMCP, cLPIP, cLDIP, cLTip]
        for c in confidences where c > 0 {
            totalConfidence += c
            validPointsCount += 1
        }
        
        guard validPointsCount >= 8 else { return nil }
        
        // Recover wrist if it fell slightly outside the image frame
        if wrist == .zero && middleMCP != .zero && indexMCP != .zero && littleMCP != .zero {
            let mcpMid = indexMCP.midpoint(to: littleMCP)
            let palmHeight = indexMCP.distance(to: littleMCP) * 1.15
            let up = (middleMCP - mcpMid).normalized
            wrist = CGPoint(x: mcpMid.x - up.x * palmHeight, y: mcpMid.y - up.y * palmHeight)
        }
        
        // Recover thumbCMC if missing
        if thumbCMC == .zero && wrist != .zero && thumbMP != .zero {
            thumbCMC = wrist.midpoint(to: thumbMP)
        }
        
        let avgConfidence = totalConfidence / validPointsCount
        
        return HandLandmarks(
            wrist: wrist,
            thumbCMC: thumbCMC,
            thumbMP: thumbMP,
            thumbIP: thumbIP,
            thumbTip: thumbTip,
            indexMCP: indexMCP,
            indexPIP: indexPIP,
            indexDIP: indexDIP,
            indexTip: indexTip,
            middleMCP: middleMCP,
            middlePIP: middlePIP,
            middleDIP: middleDIP,
            middleTip: middleTip,
            ringMCP: ringMCP,
            ringPIP: ringPIP,
            ringDIP: ringDIP,
            ringTip: ringTip,
            littleMCP: littleMCP,
            littlePIP: littlePIP,
            littleDIP: littleDIP,
            littleTip: littleTip,
            confidence: avgConfidence
        )
    }
    
    /// Generates mock landmarks for Xcode Preview or iOS Simulator testing (palm facing camera)
    public static func createMockLandmarks(for hand: HandType = .right) -> HandLandmarks {
        let isRight = (hand == .right)
        return HandLandmarks(
            wrist: CGPoint(x: 0.50, y: 0.15),
            // Right Palm: thumb is on the RIGHT (x ~ 0.82), pinky on LEFT (x ~ 0.20)
            // Left Palm: thumb is on the LEFT (x ~ 0.18), pinky on RIGHT (x ~ 0.80)
            thumbCMC: CGPoint(x: isRight ? 0.62 : 0.38, y: 0.25),
            thumbMP: CGPoint(x: isRight ? 0.72 : 0.28, y: 0.38),
            thumbIP: CGPoint(x: isRight ? 0.78 : 0.22, y: 0.48),
            thumbTip: CGPoint(x: isRight ? 0.82 : 0.18, y: 0.58),
            indexMCP: CGPoint(x: isRight ? 0.62 : 0.38, y: 0.60),
            indexPIP: CGPoint(x: isRight ? 0.64 : 0.36, y: 0.74),
            indexDIP: CGPoint(x: isRight ? 0.65 : 0.35, y: 0.82),
            indexTip: CGPoint(x: isRight ? 0.66 : 0.34, y: 0.88),
            middleMCP: CGPoint(x: 0.50, y: 0.62),
            middlePIP: CGPoint(x: 0.50, y: 0.78),
            middleDIP: CGPoint(x: 0.50, y: 0.86),
            middleTip: CGPoint(x: 0.50, y: 0.94),
            ringMCP: CGPoint(x: isRight ? 0.38 : 0.62, y: 0.59),
            ringPIP: CGPoint(x: isRight ? 0.36 : 0.64, y: 0.74),
            ringDIP: CGPoint(x: isRight ? 0.35 : 0.65, y: 0.82),
            ringTip: CGPoint(x: isRight ? 0.34 : 0.66, y: 0.88),
            littleMCP: CGPoint(x: isRight ? 0.28 : 0.72, y: 0.52),
            littlePIP: CGPoint(x: isRight ? 0.24 : 0.76, y: 0.64),
            littleDIP: CGPoint(x: isRight ? 0.22 : 0.78, y: 0.72),
            littleTip: CGPoint(x: isRight ? 0.20 : 0.80, y: 0.78),
            confidence: 0.95
        )
    }
}
