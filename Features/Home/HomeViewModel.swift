//
//  HomeViewModel.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

@Observable
public final class HomeViewModel {
    public var selectedHand: HandType = .right
    public var isShowingScanner = false
    public var isShowingHistory = false
    public var isShowingDailyInsight = false
    public var isShowingLanguagePicker = false
    public var isShowingAbout = false
    public var isShowingLearn = false
    
    public init() {}
    
    public var handTraditionNote: String {
        selectedHand.traditionDescription
    }
}
