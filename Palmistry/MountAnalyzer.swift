//
//  MountAnalyzer.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation
import CoreGraphics

public final class MountAnalyzer {
    public init() {}

    /// Estimates mount prominence from measured hand proportions (landmarks in pixel space).
    /// Each mount is tied to its finger in traditional palmistry, so relative finger length drives the value.
    public func analyzeMounts(landmarks: HandLandmarks?) -> [MountAnalysis] {
        guard let lm = landmarks, lm.palmHeight > 0, lm.ringLength > 0, lm.indexLength > 0 else { return [] }

        func level(_ ratio: CGFloat, typical: CGFloat, sensitivity: CGFloat) -> Double {
            Double(min(0.95, max(0.1, 0.5 + (ratio - typical) * sensitivity)))
        }

        let values: [(MountType, Double)] = [
            (.jupiter, level(lm.indexLength / lm.ringLength, typical: 0.97, sensitivity: 4)),
            (.saturn, level(lm.middleLength / lm.palmHeight, typical: 0.8, sensitivity: 2)),
            (.apollo, level(lm.ringLength / lm.indexLength, typical: 1.03, sensitivity: 4)),
            (.mercury, level(lm.littleLength / lm.ringLength, typical: 0.8, sensitivity: 2.5)),
            (.venus, level(lm.thumbLength / lm.palmHeight, typical: 1.0, sensitivity: 1.5)),
            (.moon, level(lm.palmWidth / lm.palmHeight, typical: 0.75, sensitivity: 2))
        ]

        return values.map { mount, prominence in
            MountAnalysis(mount: mount, prominence: prominence, interpretation: "\(mount.nameKey).reading")
        }
    }
}
