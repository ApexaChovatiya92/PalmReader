//
//  HapticManager.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import UIKit

/// Manages subtle tactile and haptic feedback during scanning and interactions.
public final class HapticManager {
    public static let shared = HapticManager()
    
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()
    
    private init() {
        prepare()
    }
    
    public func prepare() {
        impactLight.prepare()
        impactMedium.prepare()
        selection.prepare()
    }
    
    public func lightImpact() {
        impactLight.impactOccurred()
    }
    
    public func mediumImpact() {
        impactMedium.impactOccurred()
    }
    
    public func heavyImpact() {
        impactHeavy.impactOccurred()
    }
    
    public func selectionChanged() {
        selection.selectionChanged()
    }
    
    public func notifySuccess() {
        notification.notificationOccurred(.success)
    }
    
    public func notifyWarning() {
        notification.notificationOccurred(.warning)
    }
    
    public func notifyError() {
        notification.notificationOccurred(.error)
    }
}
