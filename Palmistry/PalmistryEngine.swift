//
//  PalmistryEngine.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation

public final class PalmistryEngine {
    private let lifeAnalyzer = LifeLineAnalyzer()
    private let heartAnalyzer = HeartLineAnalyzer()
    private let headAnalyzer = HeadLineAnalyzer()
    private let fateAnalyzer = FateLineAnalyzer()
    private let mountAnalyzer = MountAnalyzer()
    private let markingAnalyzer = MarkingAnalyzer()
    
    public init() {}
    
    /// Generates the reading from measured palm lines, detected markings and hand landmarks (pixel space).
    /// The same photo always produces the same reading.
    public func interpret(lines: [PalmLine], markings: [MarkingAnalysis], hand: HandType, landmarks: HandLandmarks?) -> FullReadingInterpretation {
        var lineInterpretations: [LineInterpretation] = []
        
        for line in lines {
            switch line.type {
            case .life:
                lineInterpretations.append(lifeAnalyzer.analyze(line: line, hand: hand))
            case .heart:
                lineInterpretations.append(heartAnalyzer.analyze(line: line, hand: hand))
            case .head:
                lineInterpretations.append(headAnalyzer.analyze(line: line, hand: hand))
            case .fate:
                lineInterpretations.append(fateAnalyzer.analyze(line: line, hand: hand))
            case .sun, .mercury:
                break
            }
        }
        
        let mounts = mountAnalyzer.analyzeMounts(landmarks: landmarks)
        
        // Determine Hand Element (Earth, Air, Fire, Water)
        let elementInfo = determineElement(landmarks: landmarks)
        
        // Stored as keys so the summary is translated at display time
        let summary = LocalizedText.make("summary.holistic", hand.nameKey, "\(elementInfo.element).quality")
        
        let life = lines.first { $0.type == .life }
        let heart = lines.first { $0.type == .heart }
        let head = lines.first { $0.type == .head }
        func prominence(_ mount: MountType) -> Double { mounts.first { $0.mount == mount }?.prominence ?? 0.5 }
        // Lines that weren't found count as neutral (0.5) rather than low
        func score(_ parts: [(Double?, Double)]) -> Int {
            let value = parts.reduce(0) { $0 + ($1.0 ?? 0.5) * $1.1 }
            return Int((0.35 + 0.65 * min(1, max(0, value))) * 100)
        }
        
        return FullReadingInterpretation(
            archetype: elementInfo.archetype,
            palmElement: elementInfo.element,
            holisticSummary: summary,
            lineInterpretations: lineInterpretations,
            mountInterpretations: mounts,
            markings: markings,
            vitalityScore: score([(life?.depth, 0.5), (life?.length, 0.3), (prominence(.venus), 0.2)]),
            intuitionScore: score([(prominence(.moon), 0.5), (head?.curvature, 0.5)]),
            emotionalBalanceScore: score([(heart?.depth, 0.5), (heart?.curvature, 0.3), (heart?.length, 0.2)]),
            focusScore: score([(head?.depth, 0.5), (head.map { 1 - $0.curvature }, 0.3), (head?.continuity, 0.2)]),
            handShape: measureHandShape(landmarks: landmarks)
        )
    }
    
    /// Hand and finger proportions (landmarks in pixel space so ratios aren't skewed by the image aspect)
    private func measureHandShape(landmarks lm: HandLandmarks?) -> HandShapeAnalysis? {
        guard let lm, lm.palmWidth > 0, lm.palmHeight > 0, lm.ringLength > 0, lm.indexLength > 0 else { return nil }
        let up = (lm.middleMCP - lm.wrist).normalized
        let ringTopHeight = (lm.ringDIP - lm.wrist).dot(up)
        return HandShapeAnalysis(
            palmHeightToWidth: Double(lm.palmHeight / lm.palmWidth),
            fingerToPalm: Double(lm.middleTip.distance(to: lm.middleMCP) / lm.palmHeight),
            indexToRing: Double(lm.indexLength / lm.ringLength),
            littleReach: ringTopHeight > 0 ? Double((lm.littleTip - lm.wrist).dot(up) / ringTopHeight) : 0,
            thumbToIndex: Double(lm.thumbLength / lm.indexLength)
        )
    }
    
    /// Returns localization keys for the hand element and its archetype
    private func determineElement(landmarks: HandLandmarks?) -> (element: String, archetype: String) {
        guard let landmarks = landmarks else {
            return ("element.air", "archetype.air")
        }
        
        let palmRatio = landmarks.palmHeight / max(0.001, landmarks.palmWidth)
        let fingerRatio = landmarks.middleTip.distance(to: landmarks.middleMCP) / max(0.001, landmarks.palmHeight)
        
        if palmRatio < 1.15 && fingerRatio < 0.75 {
            return ("element.earth", "archetype.earth")
        } else if palmRatio < 1.15 && fingerRatio >= 0.75 {
            return ("element.air", "archetype.air")
        } else if palmRatio >= 1.15 && fingerRatio < 0.75 {
            return ("element.fire", "archetype.fire")
        } else {
            return ("element.water", "archetype.water")
        }
    }
}
