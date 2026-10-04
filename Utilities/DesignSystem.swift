//
//  DesignSystem.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

/// Cosmic and Mystic Design System Tokens
public enum CosmicTheme {
    // MARK: - Core Palette
    public static let backgroundDark = Color(red: 0.05, green: 0.05, blue: 0.09) // #0D0D17
    public static let surfaceDark = Color(red: 0.09, green: 0.09, blue: 0.16)    // #171729
    public static let surfaceGlass = Color(red: 0.13, green: 0.13, blue: 0.22).opacity(0.7)
    public static let surfaceBorder = Color.white.opacity(0.12)
    
    // Accents
    public static let mysticGold = Color(red: 0.95, green: 0.78, blue: 0.38)     // #F2C761
    public static let celestialPurple = Color(red: 0.61, green: 0.42, blue: 0.96) // #9B6BF5
    public static let astralCyan = Color(red: 0.28, green: 0.82, blue: 0.92)     // #47D1EB
    public static let deepIndigo = Color(red: 0.18, green: 0.16, blue: 0.38)     // #2E2961
    
    // Line Specific Colors
    public static let lifeLineColor = Color(red: 0.26, green: 0.85, blue: 0.58)  // Emerald Green
    public static let heartLineColor = Color(red: 0.96, green: 0.38, blue: 0.54) // Rose Quartz / Ruby
    public static let headLineColor = Color(red: 0.98, green: 0.65, blue: 0.24)  // Amber Gold
    public static let fateLineColor = Color(red: 0.58, green: 0.44, blue: 0.98)  // Amethyst Violet
    public static let secondaryLineColor = Color(red: 0.4, green: 0.75, blue: 0.98) // Cyan Light
    
    // MARK: - Gradients
    public static let backgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.04, green: 0.04, blue: 0.08),
            Color(red: 0.08, green: 0.07, blue: 0.16),
            Color(red: 0.04, green: 0.04, blue: 0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let mysticGoldGradient = LinearGradient(
        colors: [
            Color(red: 1.0, green: 0.86, blue: 0.52),
            Color(red: 0.91, green: 0.68, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let auraGradient = LinearGradient(
        colors: [
            celestialPurple.opacity(0.8),
            astralCyan.opacity(0.7)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    public static let cardGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.08),
            Color.white.opacity(0.02)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - View Modifiers
public struct CosmicGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var borderColor: Color = CosmicTheme.surfaceBorder
    
    public func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(CosmicTheme.surfaceGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)
    }
}

public struct MysticGlowModifier: ViewModifier {
    var color: Color = CosmicTheme.mysticGold
    var radius: CGFloat = 8
    
    public func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
    }
}

public extension View {
    func cosmicGlassCard(cornerRadius: CGFloat = 20, borderColor: Color = CosmicTheme.surfaceBorder) -> some View {
        modifier(CosmicGlassCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }
    
    func mysticGlow(color: Color = CosmicTheme.mysticGold, radius: CGFloat = 8) -> some View {
        modifier(MysticGlowModifier(color: color, radius: radius))
    }
}
