//
//  LifeLineAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation

public final class LifeLineAnalyzer {
    public init() {}
    
    public func analyze(line: PalmLine, hand: HandType) -> LineInterpretation {
        let isCurved = line.curvature >= 0.28
        let isDeep = line.depth >= 0.70
        let confidenceInt = Int(line.confidence * 100)
        
        let variant: String
        if isCurved && isDeep {
            variant = "expansive"
        } else if isCurved {
            variant = "flowing"
        } else {
            variant = "deliberate"
        }
        
        // Variants with a hand-specific reading carry separate right/left keys
        let base = "life.\(variant)"
        let handedVariants: Set<String> = ["expansive"]
        let detailedKey = handedVariants.contains(variant) ? "\(base).detailed.\(hand == .right ? "right" : "left")" : "\(base).detailed"
        
        return LineInterpretation(
            lineType: .life,
            title: "\(base).title",
            summary: "\(base).summary",
            detailedReading: detailedKey,
            keyTraits: (1...4).map { "\(base).trait\($0)" },
            guidanceAdvice: "\(base).advice",
            confidencePercentage: confidenceInt
        )
    }
}
