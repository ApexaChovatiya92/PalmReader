//
//  LineDetector.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import UIKit
import CoreGraphics

/// A palm crease traced from the photo along the corridor where a given line is expected
public struct DetectedLineCandidate {
    public var type: PalmLineType
    /// Traced crease points, normalized to the image (origin bottom-left, like Vision)
    public var points: [CGPoint]
    /// Share of the expected path covered by the traced crease (0...1)
    public var coverage: Double
    /// Share of traced samples where a crease is clearly visible (0...1)
    public var continuity: Double
    /// Crease darkness relative to the rest of the palm (0...1)
    public var depth: Double
    /// How much the traced crease bows away from a straight line (see `bendRatio`)
    public var rawCurvature: Double
    /// Whether the crease splits into two branches at its end
    public var hasTerminalFork: Bool
    /// Normalized location of the largest gap along the crease, if any
    public var breakPoint: CGPoint?
}

public final class LineDetector {
    private let samplesPerLine = 28

    public init() {}

    /// Traces the life, head, heart and fate creases in the image; lines that aren't visible are left out
    public func traceCandidateLines(in image: UIImage, landmarks: HandLandmarks) -> [DetectedLineCandidate] {
        guard let cgImage = image.cgImage, let map = CreaseMap(image: cgImage, maxDimension: 900) else { return [] }

        let frame = HandFrame(landmarks: landmarks, width: CGFloat(map.width), height: CGFloat(map.height))
        guard frame.palmWidth > 20, frame.palmHeight > 20 else { return [] }
        map.computeCreaseStrength(localRadius: max(4, Int(frame.palmWidth * 0.05)))

        guard let stats = map.statistics(in: frame.palmQuad), stats.std > 0.0001 else { return [] }

        var candidates = Self.expectedPaths(in: frame).compactMap { type, path in
            trace(type: type, expected: path, map: map, frame: frame, stats: stats, relaxation: 1.0)
        }
        if !candidates.isEmpty {
            return candidates
        }
        // Fallback pass: slightly more permissive for subtle skin tones or faint creases
        return Self.expectedPaths(in: frame).compactMap { type, path in
            trace(type: type, expected: path, map: map, frame: frame, stats: stats, relaxation: 0.6)
        }
    }

    /// Expected line paths in pixel space (y down), built in the hand's own frame so rotation doesn't matter
    static func expectedPaths(in f: HandFrame) -> [(PalmLineType, [CGPoint])] {
        let W = f.palmWidth, H = f.palmHeight
        func at(_ base: CGPoint, up: CGFloat, thumbward: CGFloat) -> CGPoint {
            CGPoint(x: base.x + f.up.x * up * H + f.thumbward.x * thumbward * W,
                    y: base.y + f.up.y * up * H + f.thumbward.y * thumbward * W)
        }
        let lm = f.px

        let lifeStart = lm.indexMCP.lerp(to: lm.thumbCMC, 0.4)
        let life = [lifeStart,
                    at(lm.palmCenter.lerp(to: lm.wrist, 0.35), up: 0, thumbward: 0.24),
                    at(lm.wrist, up: 0.085, thumbward: 0.15)]
        let head = [at(lifeStart, up: 0.03, thumbward: 0),
                    at(lm.palmCenter, up: 0.04, thumbward: 0),
                    at(lm.palmCenter, up: -0.08, thumbward: -0.62)]
        let heart = [at(lm.littleMCP, up: -0.17, thumbward: -0.09),
                     at(lm.ringMCP.lerp(to: lm.middleMCP, 0.5), up: -0.24, thumbward: 0),
                     at(lm.indexMCP, up: -0.17, thumbward: 0.05)]
        let fate = [at(lm.wrist, up: 0.1, thumbward: 0),
                    lm.palmCenter,
                    at(lm.middleMCP, up: -0.28, thumbward: 0)]

        let controls: [(PalmLineType, [CGPoint])] = [(.life, life), (.head, head), (.heart, heart), (.fate, fate)]
        return controls.map { type, p in (type, quadraticCurve(p[0], p[1], p[2], segments: 40)) }
    }

    // MARK: - Tracing

    private func trace(type: PalmLineType, expected: [CGPoint], map: CreaseMap, frame: HandFrame, stats: CreaseMap.Stats, relaxation: Double = 1.0) -> DetectedLineCandidate? {
        let guide = expected.resampled(count: samplesPerLine)
        let band = frame.palmWidth * 0.22
        let step = max(1, band / 14)
        let offsets = Array(stride(from: -band, through: band, by: step))
        let normals = guide.indices.map { guide.normal(at: $0) }

        // Strength of the crease at every candidate offset across the corridor
        let strength: [[Float]] = guide.indices.map { i in
            offsets.map { map.strength(at: guide[i] + normals[i] * $0) }
        }

        // Dynamic programming: follow the darkest crease while penalizing sideways jumps
        let jumpPenalty = Float(0.4) * stats.std / Float(max(1, offsets.count / 10))
        var score = strength[0]
        var back = [[Int]](repeating: [Int](repeating: 0, count: offsets.count), count: guide.count)
        for i in 1..<guide.count {
            var next = [Float](repeating: -.infinity, count: offsets.count)
            for k in offsets.indices {
                for j in max(0, k - 3)...min(offsets.count - 1, k + 3) {
                    let candidate = score[j] - jumpPenalty * Float(abs(k - j))
                    if candidate > next[k] { next[k] = candidate; back[i][k] = j }
                }
                next[k] += strength[i][k]
            }
            score = next
        }
        var chosen = [Int](repeating: 0, count: guide.count)
        chosen[guide.count - 1] = score.indices.max { score[$0] < score[$1] } ?? 0
        for i in stride(from: guide.count - 1, to: 0, by: -1) { chosen[i - 1] = back[i][chosen[i]] }

        let traced = guide.indices.map { guide[$0] + normals[$0] * offsets[chosen[$0]] }
        let values = guide.indices.map { strength[$0][chosen[$0]] }
        // Adaptive threshold: accounts for subtle skin tone contrast
        let threshold = stats.mean + stats.std * Float(0.40 * relaxation)
        let present = values.map { $0 > threshold }

        // Longest stretch of visible crease, bridging short natural gaps (e.g. skin pore breaks)
        guard let segment = longestSegment(present, maxGap: 4) else { return nil }
        let segmentLength = segment.count
        let visible = segment.filter { present[$0] }
        let meanVisible = visible.map { values[$0] }.reduce(0, +) / Float(max(1, visible.count))
        let contrast = (meanVisible - stats.mean) / max(0.0001, stats.std)
        guard Double(segmentLength) >= Double(samplesPerLine) * (0.22 * relaxation), contrast >= Float(0.50 * relaxation) else { return nil }

        let segmentPoints = segment.map { traced[$0] }.smoothed(window: 5)
        let largestGap = largestGapCenter(in: segment, present: present)

        return DetectedLineCandidate(
            type: type,
            points: segmentPoints.map { map.normalized($0) },
            coverage: Double(segmentLength) / Double(samplesPerLine),
            continuity: Double(visible.count) / Double(segmentLength),
            depth: min(1, max(0, Double(contrast) / 3.5)),
            rawCurvature: Double(segmentPoints.bendRatio),
            hasTerminalFork: type == .head && hasFork(near: segment.suffix(3), guide: guide, normals: normals, offsets: offsets, strength: strength, chosen: chosen, band: band, stats: stats),
            breakPoint: largestGap.map { map.normalized(traced[$0]) }
        )
    }

    /// Indices of the longest run of visible samples, allowing short gaps inside it
    private func longestSegment(_ present: [Bool], maxGap: Int) -> [Int]? {
        var best: [Int] = [], current: [Int] = [], gap = 0
        for (i, isPresent) in present.enumerated() {
            if isPresent {
                if !current.isEmpty && gap > maxGap { current = [] }
                if !current.isEmpty { current += (i - gap)..<i }
                current.append(i)
                gap = 0
                if current.count > best.count { best = current }
            } else if !current.isEmpty {
                gap += 1
            }
        }
        return best.isEmpty ? nil : best
    }

    /// Center of the widest internal gap (2+ samples), treated as a break in the line
    private func largestGapCenter(in segment: [Int], present: [Bool]) -> Int? {
        var bestStart = 0, bestLength = 0, runStart = 0, runLength = 0
        for i in segment {
            if present[i] {
                if runLength > bestLength { bestLength = runLength; bestStart = runStart }
                runLength = 0
            } else {
                if runLength == 0 { runStart = i }
                runLength += 1
            }
        }
        return bestLength >= 2 ? bestStart + bestLength / 2 : nil
    }

    /// A fork shows as a second strong crease beside the traced one near the line's end
    private func hasFork(near tail: ArraySlice<Int>, guide: [CGPoint], normals: [CGPoint], offsets: [CGFloat], strength: [[Float]], chosen: [Int], band: CGFloat, stats: CreaseMap.Stats) -> Bool {
        let strong = stats.mean + 1.2 * stats.std
        let branches = tail.filter { i in
            let main = chosen[i]
            return offsets.indices.contains { k in
                let separation = abs(offsets[k] - offsets[main])
                let isPeak = k > 0 && k < offsets.count - 1 && strength[i][k] >= strength[i][k - 1] && strength[i][k] >= strength[i][k + 1]
                return isPeak && strength[i][k] > strong && separation >= band * 0.25 && separation <= band * 0.8
            }
        }
        guard let end = tail.last, strength[end][chosen[end]] > strong else { return false }
        return branches.count >= 2
    }

    private static func quadraticCurve(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, segments: Int) -> [CGPoint] {
        (0...segments).map { i -> CGPoint in
            let t = CGFloat(i) / CGFloat(segments)
            let u: CGFloat = 1 - t
            let a = p0 * (u * u)
            let b = p1 * (2 * u * t)
            let c = p2 * (t * t)
            return a + b + c
        }
    }
}

// MARK: - Hand frame

/// Landmarks in image pixel space plus the hand's own up / thumb-side directions
struct HandFrame {
    let px: HandLandmarks
    let up: CGPoint
    let thumbward: CGPoint
    let palmWidth: CGFloat
    let palmHeight: CGFloat

    init(landmarks: HandLandmarks, width: CGFloat, height: CGFloat) {
        px = landmarks.inPixelSpace(width: width, height: height)
        let axis = px.middleMCP - px.wrist
        up = axis.normalized
        let perpendicular = CGPoint(x: -up.y, y: up.x)
        thumbward = (px.thumbCMC - px.wrist).dot(perpendicular) >= 0 ? perpendicular : perpendicular * -1
        palmWidth = px.palmWidth
        palmHeight = px.palmHeight
    }

    /// Corners of the palm area used for background statistics
    var palmQuad: [CGPoint] {
        [px.indexMCP, px.littleMCP,
         px.wrist - thumbward * (palmWidth * 0.4),
         px.wrist + thumbward * (palmWidth * 0.4)]
    }
}

// MARK: - Crease map

/// Grayscale image where each pixel's value is how much darker it is than its neighborhood (creases are dark valleys)
final class CreaseMap {
    struct Stats { let mean: Float; let std: Float }

    let width: Int
    let height: Int
    private var gray: [Float]
    private var crease: [Float] = []

    init?(image: CGImage, maxDimension: Int) {
        let scale = min(1, CGFloat(maxDimension) / CGFloat(max(image.width, image.height)))
        let w = max(1, Int(CGFloat(image.width) * scale))
        let h = max(1, Int(CGFloat(image.height) * scale))
        width = w
        height = h
        var bytes = [UInt8](repeating: 0, count: w * h)
        let drawn = bytes.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                          bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                          bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            context.interpolationQuality = .medium
            context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return nil }
        gray = bytes.map(Float.init)
    }

    func computeCreaseStrength(localRadius: Int) {
        let smooth = boxBlur(gray, radius: 1)
        let local = boxBlur(gray, radius: localRadius)
        crease = zip(smooth, local).map { s, l in max(0, (l - s) / max(l, 8)) }
    }

    /// Average crease strength in a 3x3 neighborhood (pixel space, y down)
    func strength(at p: CGPoint) -> Float {
        let cx = Int(p.x.rounded()), cy = Int(p.y.rounded())
        var total: Float = 0, count: Float = 0
        for y in (cy - 1)...(cy + 1) where y >= 0 && y < height {
            for x in (cx - 1)...(cx + 1) where x >= 0 && x < width {
                total += crease[y * width + x]; count += 1
            }
        }
        return count > 0 ? total / count : 0
    }

    /// Mean and spread of crease strength over a grid inside the palm quad
    func statistics(in quad: [CGPoint]) -> Stats? {
        guard quad.count == 4 else { return nil }
        var values: [Float] = []
        for i in 0...20 {
            for j in 0...20 {
                let u = CGFloat(i) / 20, v = CGFloat(j) / 20
                let top = quad[0].lerp(to: quad[1], u), bottom = quad[3].lerp(to: quad[2], u)
                let p = top.lerp(to: bottom, v)
                if p.x >= 0, p.y >= 0, Int(p.x) < width, Int(p.y) < height { values.append(strength(at: p)) }
            }
        }
        guard values.count > 50 else { return nil }
        let mean = values.reduce(0, +) / Float(values.count)
        let variance = values.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Float(values.count)
        return Stats(mean: mean, std: variance.squareRoot())
    }

    /// Pixel point to Vision-style normalized coordinates (origin bottom-left)
    func normalized(_ p: CGPoint) -> CGPoint {
        CGPoint(x: p.x / CGFloat(width), y: 1 - p.y / CGFloat(height))
    }

    private func boxBlur(_ source: [Float], radius: Int) -> [Float] {
        // Summed-area table for constant-time box averages
        var integral = [Double](repeating: 0, count: (width + 1) * (height + 1))
        for y in 0..<height {
            var rowSum = 0.0
            for x in 0..<width {
                rowSum += Double(source[y * width + x])
                integral[(y + 1) * (width + 1) + (x + 1)] = integral[y * (width + 1) + (x + 1)] + rowSum
            }
        }
        var output = [Float](repeating: 0, count: width * height)
        for y in 0..<height {
            let y0 = max(0, y - radius), y1 = min(height, y + radius + 1)
            for x in 0..<width {
                let x0 = max(0, x - radius), x1 = min(width, x + radius + 1)
                let sum = integral[y1 * (width + 1) + x1] - integral[y0 * (width + 1) + x1]
                    - integral[y1 * (width + 1) + x0] + integral[y0 * (width + 1) + x0]
                output[y * width + x] = Float(sum / Double((x1 - x0) * (y1 - y0)))
            }
        }
        return output
    }
}
