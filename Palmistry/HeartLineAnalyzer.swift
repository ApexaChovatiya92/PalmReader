//
//  HeartLineAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation

public final class HeartLineAnalyzer {
    public init() {}
    
    public func analyze(line: PalmLine, hand: HandType) -> LineInterpretation {
        let isCurved = line.curvature >= 0.25
        let isLong = line.length >= 0.55
        let confidenceInt = Int(line.confidence * 100)
        
        let variant: String
        if isCurved && isLong {
            variant = "noble"
        } else if isCurved {
            variant = "warm"
        } else {
            variant = "discerning"
        }
        
        // Variants with a hand-specific reading carry separate right/left keys
        let base = "heart.\(variant)"
        let handedVariants: Set<String> = ["noble"]
        let detailedKey = handedVariants.contains(variant) ? "\(base).detailed.\(hand == .right ? "right" : "left")" : "\(base).detailed"
        
        return LineInterpretation(
            lineType: .heart,
            title: "\(base).title",
            summary: "\(base).summary",
            detailedReading: detailedKey,
            keyTraits: (1...4).map { "\(base).trait\($0)" },
            guidanceAdvice: "\(base).advice",
            confidencePercentage: confidenceInt
        )
    }
}
