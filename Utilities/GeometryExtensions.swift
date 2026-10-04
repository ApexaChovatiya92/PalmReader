//
//  GeometryExtensions.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import CoreGraphics

public extension CGPoint {
    /// Euclidean distance to another point
    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// Midpoint between two points
    func midpoint(to other: CGPoint) -> CGPoint {
        CGPoint(x: (x + other.x) / 2.0, y: (y + other.y) / 2.0)
    }
    
    /// Angle in radians towards another point
    func angle(to other: CGPoint) -> CGFloat {
        atan2(other.y - y, other.x - x)
    }
    
    /// Linear interpolation toward another point (t = 0 returns self)
    func lerp(to other: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: x + (other.x - x) * t, y: y + (other.y - y) * t)
    }
    
    func dot(_ other: CGPoint) -> CGFloat { x * other.x + y * other.y }
    
    var length: CGFloat { sqrt(x * x + y * y) }
    
    var normalized: CGPoint {
        let len = length
        return len > 0 ? CGPoint(x: x / len, y: y / len) : .zero
    }
    
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y) }
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint { CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y) }
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint { CGPoint(x: lhs.x * rhs, y: lhs.y * rhs) }
    
    /// Converts Vision normalized point (0...1, origin bottom-left) to SwiftUI/Screen coordinates
    func visionToScreen(viewSize: CGSize) -> CGPoint {
        CGPoint(
            x: x * viewSize.width,
            y: (1.0 - y) * viewSize.height
        )
    }
}

public extension Array where Element == CGPoint {
    /// Calculates cumulative line length across consecutive points
    var totalLength: CGFloat {
        guard count > 1 else { return 0 }
        var sum: CGFloat = 0
        for i in 0..<(count - 1) {
            sum += self[i].distance(to: self[i + 1])
        }
        return sum
    }
    
    /// Estimates curvature: ratio between Euclidean straight-line distance and actual line length
    /// Curvature close to 0 means straight line, higher values indicate curving/arched line
    var estimatedCurvature: CGFloat {
        guard count >= 3, let first = first, let last = last else { return 0 }
        let straightDist = first.distance(to: last)
        let total = totalLength
        guard total > 0.0001 else { return 0 }
        return Swift.max(0, Swift.min(1.0, 1.0 - (straightDist / total)))
    }
    
    /// Points spaced evenly along the polyline
    func resampled(count target: Int) -> [CGPoint] {
        guard count > 1, target > 1 else { return self }
        let total = totalLength
        guard total > 0 else { return self }
        var result: [CGPoint] = []
        var segment = 0, travelled: CGFloat = 0
        for i in 0..<target {
            let distance = total * CGFloat(i) / CGFloat(target - 1)
            while segment < count - 2 && travelled + self[segment].distance(to: self[segment + 1]) < distance {
                travelled += self[segment].distance(to: self[segment + 1])
                segment += 1
            }
            let segmentLength = self[segment].distance(to: self[segment + 1])
            let t = segmentLength > 0 ? Swift.min(1, (distance - travelled) / segmentLength) : 0
            result.append(self[segment].lerp(to: self[segment + 1], t))
        }
        return result
    }
    
    /// Unit vector perpendicular to the polyline at the given index
    func normal(at index: Int) -> CGPoint {
        guard count > 1 else { return CGPoint(x: 1, y: 0) }
        let tangent = (self[Swift.min(count - 1, index + 1)] - self[Swift.max(0, index - 1)]).normalized
        return CGPoint(x: -tangent.y, y: tangent.x)
    }
    
    /// Moving-average smoothing that keeps the end points in place
    func smoothed(window: Int) -> [CGPoint] {
        guard count > 2, window > 1 else { return self }
        let half = window / 2
        return indices.map { i in
            if i == 0 || i == count - 1 { return self[i] }
            let range = Swift.max(0, i - half)...Swift.min(count - 1, i + half)
            let sum = range.reduce(CGPoint.zero) { $0 + self[$1] }
            return sum * (1 / CGFloat(range.count))
        }
    }
    
    /// How far the line bows away from the straight chord between its ends, relative to the chord length
    /// (0 = straight, ~0.2 = quarter circle, 0.5 = semicircle)
    var bendRatio: CGFloat {
        guard count >= 3, let first = first, let last = last else { return 0 }
        let chord = last - first
        let chordLength = chord.length
        guard chordLength > 0.0001 else { return 0 }
        let perpendicular = CGPoint(x: -chord.y / chordLength, y: chord.x / chordLength)
        let maxDeviation = map { abs(($0 - first).dot(perpendicular)) }.max() ?? 0
        return maxDeviation / chordLength
    }
    
    /// Generates a smooth cubic bezier SwiftUI Path connecting points
    func smoothedPath() -> Path {
        var path = Path()
        guard count > 1 else { return path }
        
        path.move(to: self[0])
        if count == 2 {
            path.addLine(to: self[1])
            return path
        }
        
        for i in 1..<count {
            let p0 = self[Swift.max(0, i - 1)]
            let p1 = self[i]
            let mid = p0.midpoint(to: p1)
            path.addQuadCurve(to: mid, control: p0)
        }
        if let lastPoint = self.last {
            path.addLine(to: lastPoint)
        }
        
        return path
    }
}
