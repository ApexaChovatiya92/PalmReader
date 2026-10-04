//
//  PalmistryApp.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

@main
public struct PalmistryApp: App {
    @State private var environment = AppEnvironment.shared
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            HomeView()
                .appLanguageEnvironment()
                .environment(environment)
                .modelContainer(environment.database.container)
        }
    }
}
