//
//  PalmResultViewModel.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

@Observable
public final class PalmResultViewModel {
    public enum ResultSection: String, CaseIterable, Identifiable {
        case lines = "Lines"
        case mounts = "Mounts"
        case markings = "Markings"
        case overview = "Overview"
        
        public var id: String { rawValue }
        
        public var titleKey: String { "section.\(rawValue.lowercased())" }
    }
    
    public var selectedSection: ResultSection = .lines
    public var selectedLineType: PalmLineType = .life
    public var isSaved = false
    public var isShowingShareSheet = false
    
    public init() {}
    
    public func saveReading(
        interpretation: FullReadingInterpretation,
        lines: [PalmLine],
        image: UIImage,
        hand: HandType,
        context: ModelContext
    ) {
        guard !isSaved else { return }
        
        let newReading = PalmReadingModel(
            hand: hand,
            archetype: interpretation.archetype,
            palmElement: interpretation.palmElement,
            summary: interpretation.holisticSummary,
            palmImage: image,
            lines: lines,
            mounts: interpretation.mountInterpretations,
            markings: interpretation.markings,
            interpretation: interpretation
        )
        
        context.insert(newReading)
        do {
            try context.save()
            isSaved = true
            HapticManager.shared.notifySuccess()
        } catch {
            print("Failed to save reading: \(error.localizedDescription)")
        }
    }
}
