//
//  PalmReadingModel.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftData
import Foundation
import UIKit

@Model
public final class PalmReadingModel {
    @Attribute(.unique) public var id: UUID
    public var timestamp: Date
    public var handRawValue: String
    public var archetype: String
    public var palmElement: String
    public var summary: String
    public var notes: String
    
    // Serialized Data payloads for SwiftData safety & offline indexing
    public var linesPayload: Data?
    public var mountsPayload: Data?
    public var markingsPayload: Data?
    public var fullInterpretationPayload: Data?
    
    // Optional JPEG snapshot data of the analyzed palm image
    @Attribute(.externalStorage) public var palmImageData: Data?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        hand: HandType,
        archetype: String,
        palmElement: String,
        summary: String,
        notes: String = "",
        palmImage: UIImage? = nil,
        lines: [PalmLine] = [],
        mounts: [MountAnalysis] = [],
        markings: [MarkingAnalysis] = [],
        interpretation: FullReadingInterpretation? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.handRawValue = hand.rawValue
        self.archetype = archetype
        self.palmElement = palmElement
        self.summary = summary
        self.notes = notes
        
        if let palmImage = palmImage {
            self.palmImageData = palmImage.jpegData(compressionQuality: 0.75)
        }
        
        let encoder = JSONEncoder()
        self.linesPayload = try? encoder.encode(lines)
        self.mountsPayload = try? encoder.encode(mounts)
        self.markingsPayload = try? encoder.encode(markings)
        self.fullInterpretationPayload = try? encoder.encode(interpretation)
    }
    
    public var hand: HandType {
        HandType(rawValue: handRawValue) ?? .right
    }
    
    public var lines: [PalmLine] {
        guard let data = linesPayload,
              let decoded = try? JSONDecoder().decode([PalmLine].self, from: data) else {
            return []
        }
        return decoded
    }
    
    public var mounts: [MountAnalysis] {
        guard let data = mountsPayload,
              let decoded = try? JSONDecoder().decode([MountAnalysis].self, from: data) else {
            return []
        }
        return decoded
    }
    
    public var markings: [MarkingAnalysis] {
        guard let data = markingsPayload,
              let decoded = try? JSONDecoder().decode([MarkingAnalysis].self, from: data) else {
            return []
        }
        return decoded
    }
    
    public var fullInterpretation: FullReadingInterpretation? {
        guard let data = fullInterpretationPayload,
              let decoded = try? JSONDecoder().decode(FullReadingInterpretation.self, from: data) else {
            return nil
        }
        return decoded
    }
    
    public var palmImage: UIImage? {
        guard let data = palmImageData else { return nil }
        return UIImage(data: data)
    }
}
