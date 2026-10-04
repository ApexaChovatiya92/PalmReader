//
//  PalmLineClassifier.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation
import CoreGraphics

public protocol PalmLineClassifying {
    func classifyLines(candidates: [DetectedLineCandidate]) -> [PalmLine]
}

public final class PalmLineClassifier: PalmLineClassifying {
    public init() {}

    /// Converts traced creases into palm lines with normalized metrics; every value comes from the photo
    public func classifyLines(candidates: [DetectedLineCandidate]) -> [PalmLine] {
        candidates.map { candidate in
            // Scaled so a gently arched crease reads ~0.3 and a strongly arched one (quarter circle) ~0.6
            let curvature = min(1.0, max(0.05, candidate.rawCurvature * 3))
            // Match reflects how much of the expected path was found, how unbroken it is, and how clear it is
            let confidence = min(1.0, 0.5 * candidate.coverage + 0.3 * candidate.continuity + 0.2 * candidate.depth)

            return PalmLine(
                type: candidate.type,
                points: candidate.points,
                length: candidate.coverage,
                curvature: curvature,
                depth: candidate.depth,
                continuity: candidate.continuity,
                confidence: confidence
            )
        }
    }
}
