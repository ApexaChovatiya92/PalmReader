//
//  SimulatedPalm.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import UIKit

/// Draws a palm with visible creases so the real line detector can be exercised in the iOS Simulator (no camera there)
enum SimulatedPalm {
    static let size = CGSize(width: 900, height: 1200)

    static func image(landmarks: HandLandmarks) -> UIImage {
        let frame = HandFrame(landmarks: landmarks, width: size.width, height: size.height)
        let lm = frame.px
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1

        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            UIColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1).setFill()
            cg.fill(CGRect(origin: .zero, size: size))

            let skin = UIColor(red: 0.84, green: 0.68, blue: 0.58, alpha: 1)
            skin.setFill()
            skin.setStroke()

            // Palm body
            let palm = UIBezierPath()
            let wristThumb = lm.wrist + frame.thumbward * (frame.palmWidth * 0.45)
            let wristLittle = lm.wrist - frame.thumbward * (frame.palmWidth * 0.5)
            palm.move(to: wristThumb)
            [lm.thumbCMC, lm.thumbMP, lm.indexMCP, lm.middleMCP, lm.ringMCP, lm.littleMCP,
             lm.littleMCP - frame.thumbward * (frame.palmWidth * 0.12), wristLittle].forEach { palm.addLine(to: $0) }
            palm.close()
            palm.fill()

            // Fingers and thumb as rounded strokes through their joints
            let fingers = [[lm.thumbCMC, lm.thumbMP, lm.thumbIP, lm.thumbTip],
                           [lm.indexMCP, lm.indexPIP, lm.indexDIP, lm.indexTip],
                           [lm.middleMCP, lm.middlePIP, lm.middleDIP, lm.middleTip],
                           [lm.ringMCP, lm.ringPIP, lm.ringDIP, lm.ringTip],
                           [lm.littleMCP, lm.littlePIP, lm.littleDIP, lm.littleTip]]
            for finger in fingers {
                let path = UIBezierPath()
                path.move(to: finger[0])
                finger.dropFirst().forEach { path.addLine(to: $0) }
                path.lineWidth = frame.palmWidth * 0.26
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.stroke()
            }

            // Fine deterministic skin texture so crease contrast is measured against realistic noise
            var seed: UInt64 = 42
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(seed >> 33) / CGFloat(UInt32.max >> 1)
            }
            cg.saveGState()
            palm.addClip()
            for _ in 0..<5000 {
                UIColor(white: 0.25, alpha: 0.10 * next()).setFill()
                cg.fillEllipse(in: CGRect(x: next() * size.width, y: next() * size.height, width: 2 + next() * 3, height: 2 + next() * 3))
            }
            cg.restoreGState()

            // Creases along the expected paths, slightly wavy; the fate line is fainter and broken, the head line forks
            let crease = UIColor(red: 0.45, green: 0.3, blue: 0.26, alpha: 0.9)
            for (type, path) in LineDetector.expectedPaths(in: frame) {
                let width: CGFloat = type == .fate ? 3 : 6
                let skipped: ClosedRange<Double>? = type == .fate ? 0.45...0.58 : nil
                let bezier = UIBezierPath()
                var drawing = false
                for (i, point) in path.enumerated() {
                    let t = Double(i) / Double(path.count - 1)
                    let wobble = path.normal(at: i) * (sin(CGFloat(t) * 9) * frame.palmWidth * 0.015)
                    let p = point + wobble
                    if let skipped, skipped.contains(t) { drawing = false; continue }
                    if drawing { bezier.addLine(to: p) } else { bezier.move(to: p); drawing = true }
                }
                bezier.lineWidth = width
                bezier.lineCapStyle = .round
                (type == .fate ? crease.withAlphaComponent(0.55) : crease).setStroke()
                bezier.stroke()

                if type == .head, path.count > 10 {
                    let start = path[path.count * 3 / 4]
                    let fork = UIBezierPath()
                    fork.move(to: start)
                    fork.addLine(to: path[path.count - 1] + frame.up * (-frame.palmWidth * 0.08))
                    fork.lineWidth = 5
                    fork.lineCapStyle = .round
                    crease.setStroke()
                    fork.stroke()
                }
            }
        }
    }
}
