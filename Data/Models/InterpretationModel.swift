//
//  InterpretationModel.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation

/// Detailed palmistry interpretation for an individual line
public struct LineInterpretation: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var lineType: PalmLineType
    public var title: String
    public var summary: String
    public var detailedReading: String
    public var keyTraits: [String]
    public var guidanceAdvice: String
    public var confidencePercentage: Int
    
    public init(
        id: UUID = UUID(),
        lineType: PalmLineType,
        title: String,
        summary: String,
        detailedReading: String,
        keyTraits: [String] = [],
        guidanceAdvice: String,
        confidencePercentage: Int = 92
    ) {
        self.id = id
        self.lineType = lineType
        self.title = title
        self.summary = summary
        self.detailedReading = detailedReading
        self.keyTraits = keyTraits
        self.guidanceAdvice = guidanceAdvice
        self.confidencePercentage = confidencePercentage
    }
}

/// Hand and finger proportions measured from the landmarks; each trait is derived from these ratios at display time
public struct HandShapeAnalysis: Codable, Equatable {
    /// Palm height (wrist to middle knuckle) divided by palm width (index to little knuckle)
    public var palmHeightToWidth: Double
    /// Middle finger length divided by palm height
    public var fingerToPalm: Double
    /// Index finger length divided by ring finger length
    public var indexToRing: Double
    /// How far the little fingertip reaches up the hand relative to the ring finger's top joint (1 = level)
    public var littleReach: Double
    /// Thumb length (base joint to tip) divided by index finger length
    public var thumbToIndex: Double
    
    // Thresholds match the element calculation so the hand shape and element always agree
    public var isSquarePalm: Bool { palmHeightToWidth < 1.15 }
    public var hasLongFingers: Bool { fingerToPalm >= 0.75 }
    public var hasLongLittleFinger: Bool { littleReach >= 1 }
    public var hasLongThumb: Bool { thumbToIndex >= 1.2 }
    
    public enum FingerLead { case index, ring, balanced }
    public var fingerLead: FingerLead {
        if indexToRing > 1.02 { return .index }
        if indexToRing < 0.96 { return .ring }
        return .balanced
    }
}

/// Overall holistic reading result synthesizing lines, mounts, and hand shape
public struct FullReadingInterpretation: Codable, Equatable {
    public var archetype: String
    public var palmElement: String // Earth, Air, Fire, Water hand
    public var holisticSummary: String
    public var lineInterpretations: [LineInterpretation]
    public var mountInterpretations: [MountAnalysis]
    public var markings: [MarkingAnalysis]
    public var vitalityScore: Int
    public var intuitionScore: Int
    public var emotionalBalanceScore: Int
    public var focusScore: Int
    /// Missing in readings saved before hand-shape analysis existed
    public var handShape: HandShapeAnalysis?
    
    public init(
        archetype: String,
        palmElement: String,
        holisticSummary: String,
        lineInterpretations: [LineInterpretation],
        mountInterpretations: [MountAnalysis] = [],
        markings: [MarkingAnalysis] = [],
        vitalityScore: Int = 85,
        intuitionScore: Int = 78,
        emotionalBalanceScore: Int = 82,
        focusScore: Int = 90,
        handShape: HandShapeAnalysis? = nil
    ) {
        self.archetype = archetype
        self.palmElement = palmElement
        self.holisticSummary = holisticSummary
        self.lineInterpretations = lineInterpretations
        self.mountInterpretations = mountInterpretations
        self.markings = markings
        self.vitalityScore = vitalityScore
        self.intuitionScore = intuitionScore
        self.emotionalBalanceScore = emotionalBalanceScore
        self.focusScore = focusScore
        self.handShape = handShape
    }
}
