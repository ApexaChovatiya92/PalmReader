//
//  PalmLineModels.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import Foundation

/// Represents the analyzed hand orientation
public enum HandType: String, Codable, CaseIterable, Identifiable {
    case right = "Right Hand"
    case left = "Left Hand"
    
    public var id: String { rawValue }
    
    /// Localization key; `rawValue` stays English because it is persisted
    public var nameKey: String {
        switch self {
        case .right: return "hand.right"
        case .left: return "hand.left"
        }
    }
    
    public var localizedName: String { L(nameKey) }
    
    public var traditionDescription: String { L("\(nameKey).tradition") }
}

/// The major and secondary palm lines
public enum PalmLineType: String, Codable, CaseIterable, Identifiable {
    case life = "Life Line"
    case heart = "Heart Line"
    case head = "Head Line"
    case fate = "Fate Line"
    case sun = "Sun (Apollo) Line"
    case mercury = "Mercury (Health) Line"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .life: return "bolt.heart.fill"
        case .heart: return "heart.fill"
        case .head: return "brain.head.profile"
        case .fate: return "sparkles"
        case .sun: return "sun.max.fill"
        case .mercury: return "cross.case.fill"
        }
    }
    
    public var accentColor: Color {
        switch self {
        case .life: return CosmicTheme.lifeLineColor
        case .heart: return CosmicTheme.heartLineColor
        case .head: return CosmicTheme.headLineColor
        case .fate: return CosmicTheme.fateLineColor
        case .sun: return CosmicTheme.mysticGold
        case .mercury: return CosmicTheme.secondaryLineColor
        }
    }
    
    /// Localization key; `rawValue` stays English because it is persisted
    public var nameKey: String {
        switch self {
        case .life: return "line.life"
        case .heart: return "line.heart"
        case .head: return "line.head"
        case .fate: return "line.fate"
        case .sun: return "line.sun"
        case .mercury: return "line.mercury"
        }
    }
    
    public var localizedName: String { L(nameKey) }
    
    public var domainArea: String { L("\(nameKey).domain") }
}

/// Structured measurement characteristics of an extracted palm line
public struct PalmLine: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var type: PalmLineType
    public var points: [CodablePoint]
    
    /// Normalized metrics [0.0 - 1.0]
    public var length: Double
    public var curvature: Double
    public var depth: Double
    public var continuity: Double // 1.0 = unbroken, lower = fragmented
    public var confidence: Double // Vision / CV confidence score
    
    public init(
        id: UUID = UUID(),
        type: PalmLineType,
        points: [CGPoint] = [],
        length: Double = 0.5,
        curvature: Double = 0.3,
        depth: Double = 0.7,
        continuity: Double = 0.9,
        confidence: Double = 0.88
    ) {
        self.id = id
        self.type = type
        self.points = points.map { CodablePoint(x: $0.x, y: $0.y) }
        self.length = length
        self.curvature = curvature
        self.depth = depth
        self.continuity = continuity
        self.confidence = confidence
    }
    
    public var cgPoints: [CGPoint] {
        points.map { CGPoint(x: $0.x, y: $0.y) }
    }
}

/// Codable representation for CGPoint coordinates
public struct CodablePoint: Codable, Equatable {
    public var x: Double
    public var y: Double
    
    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

/// Palm Mounts (energetic elevations under fingers and palm base)
public enum MountType: String, Codable, CaseIterable, Identifiable {
    case jupiter = "Mount of Jupiter" // Under Index
    case saturn = "Mount of Saturn"   // Under Middle
    case apollo = "Mount of Apollo"   // Under Ring
    case mercury = "Mount of Mercury" // Under Little
    case venus = "Mount of Venus"     // Base of Thumb
    case moon = "Mount of Moon (Luna)"// Lower percussion
    case mars = "Mount of Mars"       // Upper & Lower Mars
    
    public var id: String { rawValue }
    
    /// Localization key; `rawValue` stays English because it is persisted
    public var nameKey: String {
        switch self {
        case .jupiter: return "mount.jupiter"
        case .saturn: return "mount.saturn"
        case .apollo: return "mount.apollo"
        case .mercury: return "mount.mercury"
        case .venus: return "mount.venus"
        case .moon: return "mount.moon"
        case .mars: return "mount.mars"
        }
    }
    
    public var localizedName: String { L(nameKey) }
    
    public var keyword: String { L("\(nameKey).keyword") }
}

public struct MountAnalysis: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var mount: MountType
    public var prominence: Double // 0.0 (flat) to 1.0 (well-developed)
    public var interpretation: String
}

/// Special Markings (breaks, forks, stars, islands, crosses)
public enum MarkingType: String, Codable, CaseIterable {
    case fork = "Fork"
    case star = "Star"
    case cross = "Cross"
    case island = "Island"
    case triangle = "Triangle"
    case breakMark = "Break"
    case square = "Square (Protection)"
    
    /// Localization key; `rawValue` stays English because it is persisted
    public var nameKey: String {
        switch self {
        case .fork: return "marking.fork"
        case .star: return "marking.star"
        case .cross: return "marking.cross"
        case .island: return "marking.island"
        case .triangle: return "marking.triangle"
        case .breakMark: return "marking.break"
        case .square: return "marking.square"
        }
    }
    
    public var localizedName: String { L(nameKey) }
}

public struct MarkingAnalysis: Identifiable, Codable, Equatable {
    public var id: UUID = UUID()
    public var type: MarkingType
    public var location: String
    public var interpretation: String
    public var coordinates: CodablePoint?
}
