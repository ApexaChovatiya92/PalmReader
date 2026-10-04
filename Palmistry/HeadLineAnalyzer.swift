//
//  HeadLineAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation

public final class HeadLineAnalyzer {
    public init() {}
    
    public func analyze(line: PalmLine, hand: HandType) -> LineInterpretation {
        let isSloping = line.curvature >= 0.22
        let isDeep = line.depth >= 0.70
        let confidenceInt = Int(line.confidence * 100)
        
        let variant: String
        if isSloping && isDeep {
            variant = "imaginative"
        } else if isSloping {
            variant = "adaptive"
        } else {
            variant = "analytical"
        }
        
        // Variants with a hand-specific reading carry separate right/left keys
        let base = "head.\(variant)"
        let handedVariants: Set<String> = ["imaginative"]
        let detailedKey = handedVariants.contains(variant) ? "\(base).detailed.\(hand == .right ? "right" : "left")" : "\(base).detailed"
        
        return LineInterpretation(
            lineType: .head,
            title: "\(base).title",
            summary: "\(base).summary",
            detailedReading: detailedKey,
            keyTraits: (1...4).map { "\(base).trait\($0)" },
            guidanceAdvice: "\(base).advice",
            confidencePercentage: confidenceInt
        )
    }
}
