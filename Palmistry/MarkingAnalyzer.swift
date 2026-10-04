//
//  MarkingAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation
import CoreGraphics

public final class MarkingAnalyzer {
    public init() {}

    /// Reports only markings that were actually found in the traced creases
    public func analyzeMarkings(candidates: [DetectedLineCandidate]) -> [MarkingAnalysis] {
        var markings: [MarkingAnalysis] = []

        // Writer's Fork: the head line splits into two branches at its end
        if let head = candidates.first(where: { $0.type == .head }), head.hasTerminalFork, let end = head.points.last {
            markings.append(MarkingAnalysis(
                type: .fork,
                location: "marking.fork.location",
                interpretation: "marking.fork.reading",
                coordinates: CodablePoint(x: end.x, y: end.y)
            ))
        }

        // Breaks: a clear gap along a line
        for candidate in candidates {
            guard let gap = candidate.breakPoint else { continue }
            markings.append(MarkingAnalysis(
                type: .breakMark,
                location: LocalizedText.make("marking.break.location", candidate.type.nameKey),
                interpretation: "marking.break.reading",
                coordinates: CodablePoint(x: gap.x, y: gap.y)
            ))
        }

        return markings
    }
}
