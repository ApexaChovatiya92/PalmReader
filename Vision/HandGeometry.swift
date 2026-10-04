//
//  HandGeometry.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import CoreGraphics
import Vision

public struct HandLandmarks {
    public var wrist: CGPoint
    public var thumbCMC: CGPoint
    public var thumbMP: CGPoint
    public var thumbIP: CGPoint
    public var thumbTip: CGPoint
    
    public var indexMCP: CGPoint
    public var indexPIP: CGPoint
    public var indexDIP: CGPoint
    public var indexTip: CGPoint
    
    public var middleMCP: CGPoint
    public var middlePIP: CGPoint
    public var middleDIP: CGPoint
    public var middleTip: CGPoint
    
    public var ringMCP: CGPoint
    public var ringPIP: CGPoint
    public var ringDIP: CGPoint
    public var ringTip: CGPoint
    
    public var littleMCP: CGPoint
    public var littlePIP: CGPoint
    public var littleDIP: CGPoint
    public var littleTip: CGPoint
    
    public var confidence: Float
    
    public init(
        wrist: CGPoint = .zero,
        thumbCMC: CGPoint = .zero,
        thumbMP: CGPoint = .zero,
        thumbIP: CGPoint = .zero,
        thumbTip: CGPoint = .zero,
        indexMCP: CGPoint = .zero,
        indexPIP: CGPoint = .zero,
        indexDIP: CGPoint = .zero,
        indexTip: CGPoint = .zero,
        middleMCP: CGPoint = .zero,
        middlePIP: CGPoint = .zero,
        middleDIP: CGPoint = .zero,
        middleTip: CGPoint = .zero,
        ringMCP: CGPoint = .zero,
        ringPIP: CGPoint = .zero,
        ringDIP: CGPoint = .zero,
        ringTip: CGPoint = .zero,
        littleMCP: CGPoint = .zero,
        littlePIP: CGPoint = .zero,
        littleDIP: CGPoint = .zero,
        littleTip: CGPoint = .zero,
        confidence: Float = 0.0
    ) {
        self.wrist = wrist
        self.thumbCMC = thumbCMC
        self.thumbMP = thumbMP
        self.thumbIP = thumbIP
        self.thumbTip = thumbTip
        self.indexMCP = indexMCP
        self.indexPIP = indexPIP
        self.indexDIP = indexDIP
        self.indexTip = indexTip
        self.middleMCP = middleMCP
        self.middlePIP = middlePIP
        self.middleDIP = middleDIP
        self.middleTip = middleTip
        self.ringMCP = ringMCP
        self.ringPIP = ringPIP
        self.ringDIP = ringDIP
        self.ringTip = ringTip
        self.littleMCP = littleMCP
        self.littlePIP = littlePIP
        self.littleDIP = littleDIP
        self.littleTip = littleTip
        self.confidence = confidence
    }
    
    /// Estimated center of the palm
    public var palmCenter: CGPoint {
        let mcpMid = indexMCP.midpoint(to: littleMCP)
        return wrist.midpoint(to: mcpMid)
    }
    
    /// Palm width across MCP joints
    public var palmWidth: CGFloat {
        indexMCP.distance(to: littleMCP)
    }
    
    /// Palm height from wrist to middle MCP
    public var palmHeight: CGFloat {
        wrist.distance(to: middleMCP)
    }
    
    /// Rotation angle (tilt) of the hand in radians relative to vertical
    public var tiltAngle: CGFloat {
        let dx = middleMCP.x - wrist.x
        let dy = middleMCP.y - wrist.y
        return atan2(dx, dy)
    }
    
    /// Same landmarks in image pixel coordinates (origin top-left), so distances aren't skewed by the aspect ratio
    public func inPixelSpace(width: CGFloat, height: CGFloat) -> HandLandmarks {
        func convert(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x * width, y: (1 - p.y) * height) }
        return HandLandmarks(
            wrist: convert(wrist), thumbCMC: convert(thumbCMC), thumbMP: convert(thumbMP), thumbIP: convert(thumbIP), thumbTip: convert(thumbTip),
            indexMCP: convert(indexMCP), indexPIP: convert(indexPIP), indexDIP: convert(indexDIP), indexTip: convert(indexTip),
            middleMCP: convert(middleMCP), middlePIP: convert(middlePIP), middleDIP: convert(middleDIP), middleTip: convert(middleTip),
            ringMCP: convert(ringMCP), ringPIP: convert(ringPIP), ringDIP: convert(ringDIP), ringTip: convert(ringTip),
            littleMCP: convert(littleMCP), littlePIP: convert(littlePIP), littleDIP: convert(littleDIP), littleTip: convert(littleTip),
            confidence: confidence
        )
    }
    
    /// Finger lengths (knuckle to tip), in the same units as the landmarks
    public var indexLength: CGFloat { indexMCP.distance(to: indexPIP) + indexPIP.distance(to: indexDIP) + indexDIP.distance(to: indexTip) }
    public var middleLength: CGFloat { middleMCP.distance(to: middlePIP) + middlePIP.distance(to: middleDIP) + middleDIP.distance(to: middleTip) }
    public var ringLength: CGFloat { ringMCP.distance(to: ringPIP) + ringPIP.distance(to: ringDIP) + ringDIP.distance(to: ringTip) }
    public var littleLength: CGFloat { littleMCP.distance(to: littlePIP) + littlePIP.distance(to: littleDIP) + littleDIP.distance(to: littleTip) }
    public var thumbLength: CGFloat { thumbCMC.distance(to: thumbMP) + thumbMP.distance(to: thumbIP) + thumbIP.distance(to: thumbTip) }
    
    /// Checks whether thumb is to the right or left of palm axis to verify hand side (palm facing camera)
    public var estimatedHandType: HandType {
        // Hand axis from wrist to middle knuckle (Vision coordinates: y is up)
        let axis = CGPoint(x: middleMCP.x - wrist.x, y: middleMCP.y - wrist.y)
        // Perpendicular vector pointing to the right side of the hand axis
        let rightPerpendicular = CGPoint(x: axis.y, y: -axis.x)
        // Thumb position relative to wrist
        let thumbVec = CGPoint(x: thumbTip.x - wrist.x, y: thumbTip.y - wrist.y)
        // For a palm facing the camera:
        // Right hand: thumb is to the right of the palm axis (dot >= 0)
        // Left hand: thumb is to the left of the palm axis (dot < 0)
        let dot = thumbVec.x * rightPerpendicular.x + thumbVec.y * rightPerpendicular.y
        return dot >= 0 ? .right : .left
    }
}
