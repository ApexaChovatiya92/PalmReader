//
//  FateLineAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation

public final class FateLineAnalyzer {
    public init() {}
    
    public func analyze(line: PalmLine, hand: HandType) -> LineInterpretation {
        let isProminent = line.length >= 0.45 && line.depth >= 0.50
        let confidenceInt = Int(line.confidence * 100)
        
        let variant: String
        if isProminent {
            variant = "purpose"
        } else {
            variant = "explorer"
        }
        
        // Variants with a hand-specific reading carry separate right/left keys
        let base = "fate.\(variant)"
        let handedVariants: Set<String> = ["purpose"]
        let detailedKey = handedVariants.contains(variant) ? "\(base).detailed.\(hand == .right ? "right" : "left")" : "\(base).detailed"
        
        return LineInterpretation(
            lineType: .fate,
            title: "\(base).title",
            summary: "\(base).summary",
            detailedReading: detailedKey,
            keyTraits: (1...4).map { "\(base).trait\($0)" },
            guidanceAdvice: "\(base).advice",
            confidencePercentage: confidenceInt
        )
    }
}
