//
//  PalmistryDatabase.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftData
import Foundation

public final class PalmistryDatabase {
    public static let shared = PalmistryDatabase()
    
    public let container: ModelContainer
    
    private init(inMemory: Bool = false) {
        do {
            let schema = Schema([
                PalmReadingModel.self
            ])
            let configuration = ModelConfiguration(
                isStoredInMemoryOnly: inMemory
            )
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }
    
    /// Dedicated in-memory container for Xcode Previews and unit tests
    public static var previewContainer: ModelContainer = {
        let db = PalmistryDatabase(inMemory: true)
        return db.container
    }()
}
