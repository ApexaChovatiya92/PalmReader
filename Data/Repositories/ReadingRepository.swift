//
//  ReadingRepository.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import Foundation
import SwiftData

public protocol ReadingRepositoryProtocol {
    func saveReading(_ reading: PalmReadingModel) throws
    func deleteReading(_ reading: PalmReadingModel) throws
    func fetchAllReadings() throws -> [PalmReadingModel]
}

public final class ReadingRepository: ReadingRepositoryProtocol {
    private let modelContext: ModelContext
    
    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    public func saveReading(_ reading: PalmReadingModel) throws {
        modelContext.insert(reading)
        try modelContext.save()
    }
    
    public func deleteReading(_ reading: PalmReadingModel) throws {
        modelContext.delete(reading)
        try modelContext.save()
    }
    
    public func fetchAllReadings() throws -> [PalmReadingModel] {
        let descriptor = FetchDescriptor<PalmReadingModel>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
