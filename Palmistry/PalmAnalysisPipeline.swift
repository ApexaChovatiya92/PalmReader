//
//  PalmAnalysisPipeline.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import UIKit

public enum PalmAnalysisError: Error {
    /// No open hand was found in the photo
    case noHandFound
    /// A hand was found but none of the major creases were clear enough to trace
    case linesNotVisible

    /// Localization key for the message shown to the user
    public var messageKey: String {
        switch self {
        case .noHandFound: return "error.noHand"
        case .linesNotVisible: return "error.noLines"
        }
    }
}

public struct PalmAnalysisResult {
    public let reading: FullReadingInterpretation
    public let lines: [PalmLine]
    /// Upright copy of the analyzed photo; line points are normalized to this image
    public let image: UIImage
}

/// Runs a still photo through hand detection, crease tracing and the palmistry rules
public final class PalmAnalysisPipeline {
    // Separate from the live-camera detector so still analysis never shares a Vision request with frame processing
    private let handDetector = HandPoseDetector()
    private let lineDetector: LineDetector
    private let classifier: PalmLineClassifier
    private let markingAnalyzer = MarkingAnalyzer()
    private let engine: PalmistryEngine

    public init(lineDetector: LineDetector, classifier: PalmLineClassifier, engine: PalmistryEngine) {
        self.lineDetector = lineDetector
        self.classifier = classifier
        self.engine = engine
    }

    /// - Parameter presetLandmarks: skips hand detection; only used for the simulator's generated palm
    public func analyze(image: UIImage, hand: HandType, presetLandmarks: HandLandmarks? = nil) throws -> PalmAnalysisResult {
        let upright = image.uprightCopy(maxDimension: 1600)
        guard let cgImage = upright.cgImage else { throw PalmAnalysisError.noHandFound }

        var resolvedLandmarks = presetLandmarks ?? handDetector.detectHand(in: cgImage)
        #if targetEnvironment(simulator)
        if resolvedLandmarks == nil || (resolvedLandmarks?.confidence ?? 0) < 0.3 {
            resolvedLandmarks = HandPoseDetector.createMockLandmarks(for: hand)
        }
        #endif
        guard let landmarks = resolvedLandmarks, landmarks.confidence > 0.3 else {
            throw PalmAnalysisError.noHandFound
        }

        let candidates = lineDetector.traceCandidateLines(in: upright, landmarks: landmarks)
        guard !candidates.isEmpty else { throw PalmAnalysisError.linesNotVisible }

        let lines = classifier.classifyLines(candidates: candidates)
        let markings = markingAnalyzer.analyzeMarkings(candidates: candidates)
        let pixelLandmarks = landmarks.inPixelSpace(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        let reading = engine.interpret(lines: lines, markings: markings, hand: hand, landmarks: pixelLandmarks)

        return PalmAnalysisResult(reading: reading, lines: lines, image: upright)
    }
}

extension UIImage {
    /// Redraws the image with `.up` orientation at scale 1, downsized so the longest side fits `maxDimension`
    func uprightCopy(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        let factor = longest > maxDimension ? maxDimension / longest : 1
        let target = CGSize(width: (size.width * factor).rounded(), height: (size.height * factor).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
