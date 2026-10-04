//
//  DailyInsightView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct DailyInsightView: View {
    @Environment(\.dismiss) private var dismiss
    
    // Offline astronomical calculations based on calendar day
    private var dailyMoonPhase: String {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let phases = ["waxingCrescent", "firstQuarter", "waxingGibbous", "fullMoon", "waningGibbous", "lastQuarter", "waningCrescent", "newMoon"]
        return L("moon.\(phases[dayOfYear % phases.count])")
    }
    
    private var dailyFocusElement: String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let elements = ["earth", "moon", "mars", "mercury", "jupiter", "venus", "saturn"]
        return L("focus.\(elements[(weekday - 1) % elements.count])")
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Emblem
                        ZStack {
                            Circle()
                                .fill(CosmicTheme.celestialPurple.opacity(0.2))
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle().stroke(CosmicTheme.celestialPurple.opacity(0.6), lineWidth: 1.5)
                                )
                                .mysticGlow(color: CosmicTheme.celestialPurple, radius: 14)
                            
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 34))
                                .foregroundStyle(CosmicTheme.celestialPurple)
                        }
                        .padding(.top, 16)
                        
                        VStack(spacing: 6) {
                            Text(L("insight.header"))
                                .font(.system(size: 11, weight: .bold))
                                .localizedTracking(2)
                                .foregroundStyle(CosmicTheme.mysticGold)
                            
                            Text(L("insight.title"))
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(Color.white)
                            
                            Text(Date().localizedFormatted(date: .complete, time: .omitted))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.5))
                        }
                        
                        // Today's Alignment Card
                        VStack(alignment: .leading, spacing: 14) {
                            insightRow(icon: "moon.fill", title: L("insight.lunarPhase"), value: dailyMoonPhase, color: CosmicTheme.astralCyan)
                            Divider().background(CosmicTheme.surfaceBorder)
                            insightRow(icon: "sparkles", title: L("insight.planetaryFocus"), value: dailyFocusElement, color: CosmicTheme.mysticGold)
                        }
                        .cosmicGlassCard()
                        
                        // Contemplation & Reflection
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L("insight.reflection.header"))
                                .font(.system(size: 11, weight: .bold))
                                .localizedTracking(1.5)
                                .foregroundStyle(CosmicTheme.mysticGold)
                            
                            Text(L("insight.reflection.body"))
                                .font(.system(size: 14))
                                .foregroundStyle(Color.white.opacity(0.85))
                                .lineSpacing(4)
                        }
                        .cosmicGlassCard()
                        
                        // Offline notice
                        HStack(spacing: 8) {
                            Image(systemName: "airplane")
                                .font(.system(size: 12))
                            Text(L("insight.offlineNotice"))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundStyle(Color.white.opacity(0.4))
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L("insight.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        dismiss()
                    }
                    .foregroundStyle(CosmicTheme.mysticGold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func insightRow(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(color.opacity(0.2))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.5))
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        }
    }
}
