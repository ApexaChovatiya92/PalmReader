//
//  ImageQualityAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import CoreGraphics
import Foundation

public struct QualityAssessment {
    public var isGoodQuality: Bool
    public var guidanceMessage: String // localization key
    public var lightingScore: Double // 0 to 1
    public var handCoverageScore: Double // 0 to 1
    public var stabilityScore: Double // 0 to 1
}

public final class ImageQualityAnalyzer {
    private var previousPositions: [CGPoint] = []
    private let maxHistory = 5
    
    public init() {}
    
    public func reset() {
        previousPositions.removeAll()
    }
    
    public func assessHand(landmarks: HandLandmarks?, expectedHand: HandType) -> QualityAssessment {
        guard let landmarks = landmarks, landmarks.confidence > 0.30 else {
            return QualityAssessment(
                isGoodQuality: false,
                guidanceMessage: "guidance.placeHand.\(expectedHand == .right ? "right" : "left")",
                lightingScore: 0.5,
                handCoverageScore: 0.0,
                stabilityScore: 0.0
            )
        }
        
        // 1. Hand side verification
        let detectedHand = landmarks.estimatedHandType
        if detectedHand != expectedHand && landmarks.confidence > 0.75 {
            return QualityAssessment(
                isGoodQuality: false,
                guidanceMessage: "guidance.switchHand.\(expectedHand == .right ? "right" : "left")",
                lightingScore: 0.8,
                handCoverageScore: 0.6,
                stabilityScore: 0.7
            )
        }
        
        // 2. Hand size / distance check
        let palmHeight = landmarks.palmHeight
        let coverageScore = min(1.0, max(0.0, Double(palmHeight) / 0.45))
        
        if palmHeight < 0.18 {
            return QualityAssessment(
                isGoodQuality: false,
                guidanceMessage: "guidance.moveCloser",
                lightingScore: 0.8,
                handCoverageScore: coverageScore,
                stabilityScore: 0.8
            )
        } else if palmHeight > 0.75 {
            return QualityAssessment(
                isGoodQuality: false,
                guidanceMessage: "guidance.moveBack",
                lightingScore: 0.8,
                handCoverageScore: coverageScore,
                stabilityScore: 0.8
            )
        }
        
        // 3. Stability check (movement over recent frames)
        let currentCenter = landmarks.palmCenter
        previousPositions.append(currentCenter)
        if previousPositions.count > maxHistory {
            previousPositions.removeFirst()
        }
        
        var movement: CGFloat = 0
        if previousPositions.count > 1 {
            for i in 0..<(previousPositions.count - 1) {
                movement += previousPositions[i].distance(to: previousPositions[i + 1])
            }
            movement /= CGFloat(previousPositions.count - 1)
        }
        
        let stabilityScore = max(0.0, min(1.0, 1.0 - Double(movement) * 12.0))
        if stabilityScore < 0.45 {
            return QualityAssessment(
                isGoodQuality: false,
                guidanceMessage: "guidance.holdSteady",
                lightingScore: 0.85,
                handCoverageScore: coverageScore,
                stabilityScore: stabilityScore
            )
        }
        
        // 4. Hand tilt check
        let tilt = abs(landmarks.tiltAngle)
        if tilt > 0.55 {
            return QualityAssessment(
                isGoodQuality: false,
                guidanceMessage: "guidance.alignUpright",
                lightingScore: 0.85,
                handCoverageScore: coverageScore,
                stabilityScore: stabilityScore
            )
        }
        
        // Perfect alignment!
        return QualityAssessment(
            isGoodQuality: true,
            guidanceMessage: "guidance.perfect",
            lightingScore: 0.92,
            handCoverageScore: coverageScore,
            stabilityScore: stabilityScore
        )
    }
}
