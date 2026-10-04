//
//  HomeView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

public struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @Query(sort: \PalmReadingModel.timestamp, order: .reverse) private var recentReadings: [PalmReadingModel]
    @State private var viewModel = HomeViewModel()
    @AppStorage(DisclaimerView.acceptedKey) private var hasAcceptedDisclaimer = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()
                
                // Mystic ambient background glows
                VStack {
                    Circle()
                        .fill(CosmicTheme.celestialPurple.opacity(0.18))
                        .blur(radius: 90)
                        .frame(width: 320, height: 320)
                        .offset(x: -60, y: -100)
                    Spacer()
                    Circle()
                        .fill(CosmicTheme.astralCyan.opacity(0.15))
                        .blur(radius: 90)
                        .frame(width: 320, height: 320)
                        .offset(x: 80, y: 100)
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header Title & Emblem
                        headerSection
                        
                        // Hand Selection Card
                        handSelectionCard
                        
                        // Primary Scan CTA Button
                        startScanButton
                        
                        // Daily Wisdom / Offline Insight Card
                        dailyWisdomCard
                        
                        // Palmistry guide, map and quiz
                        learnCard
                        
                        // Recent Readings Preview
                        recentReadingsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.shared.lightImpact()
                        viewModel.isShowingLanguagePicker = true
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "globe")
                                .font(.system(size: 14, weight: .semibold))
                            Text(LocalizationManager.shared.language.nativeName)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundStyle(CosmicTheme.mysticGold)
                    }
                    .accessibilityLabel(L("language.title"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        viewModel.isShowingAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(CosmicTheme.mysticGold)
                    }
                    .accessibilityLabel(L("about.title"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.shared.lightImpact()
                        viewModel.isShowingHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(CosmicTheme.mysticGold)
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.isShowingScanner) {
                PalmScannerView(handType: viewModel.selectedHand)
            }
            .sheet(isPresented: $viewModel.isShowingHistory) {
                HistoryListView()
            }
            .sheet(isPresented: $viewModel.isShowingDailyInsight) {
                DailyInsightView()
            }
            .sheet(isPresented: $viewModel.isShowingLanguagePicker) {
                LanguagePickerView()
            }
            .sheet(isPresented: $viewModel.isShowingLearn) {
                LearnPalmistryView()
            }
            .sheet(isPresented: $viewModel.isShowingAbout) {
                AboutView()
            }
            .fullScreenCover(isPresented: Binding(
                get: { !hasAcceptedDisclaimer },
                set: { _ in }
            )) {
                DisclaimerView()
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(CosmicTheme.surfaceDark)
                    .frame(width: 72, height: 72)
                    .overlay(
                        Circle().stroke(CosmicTheme.mysticGold.opacity(0.5), lineWidth: 1.5)
                    )
                    .mysticGlow(color: CosmicTheme.mysticGold, radius: 10)
                
                Image(systemName: "hand.raised.fingers.spread.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(CosmicTheme.mysticGoldGradient)
            }
            .padding(.top, 10)
            
            Text(verbatim: "AURA PALM")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .localizedTracking(3)
                .foregroundStyle(CosmicTheme.mysticGoldGradient)
            
            Text(L("home.subtitle"))
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.6))
        }
    }
    
    // MARK: - Hand Selection Card
    private var handSelectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("home.selectHand"))
                .font(.system(size: 11, weight: .bold))
                .localizedTracking(1.5)
                .foregroundStyle(CosmicTheme.mysticGold.opacity(0.9))
            
            HStack(spacing: 12) {
                ForEach(HandType.allCases) { hand in
                    let isSelected = viewModel.selectedHand == hand
                    Button {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedHand = hand
                        }
                    } label: {
                        HStack {
                            Image(systemName: hand == .right ? "hand.point.right.fill" : "hand.point.left.fill")
                                .font(.system(size: 16))
                            Text(hand.localizedName)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(isSelected ? CosmicTheme.mysticGold : CosmicTheme.surfaceDark.opacity(0.8))
                        )
                        .foregroundStyle(isSelected ? CosmicTheme.backgroundDark : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? CosmicTheme.mysticGold : CosmicTheme.surfaceBorder, lineWidth: 1)
                        )
                    }
                }
            }
            
            // Educational note about dominant hand
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.system(size: 13))
                    .foregroundStyle(CosmicTheme.celestialPurple)
                    .padding(.top, 2)
                
                Text(viewModel.handTraditionNote)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineSpacing(2)
            }
            .padding(.top, 4)
        }
        .cosmicGlassCard()
    }
    
    // MARK: - Start Scan Button
    private var startScanButton: some View {
        Button {
            HapticManager.shared.mediumImpact()
            viewModel.isShowingScanner = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "viewfinder")
                    .font(.system(size: 20, weight: .bold))
                
                Text(L("home.scanNow"))
                    .font(.system(size: 15, weight: .black))
                    .localizedTracking(1.5)
                
                Spacer()
                
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
            .background(CosmicTheme.mysticGoldGradient)
            .foregroundStyle(CosmicTheme.backgroundDark)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .mysticGlow(color: CosmicTheme.mysticGold, radius: 14)
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Daily Wisdom Card
    private var dailyWisdomCard: some View {
        Button {
            HapticManager.shared.lightImpact()
            viewModel.isShowingDailyInsight = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.celestialPurple.opacity(0.2))
                        .frame(width: 46, height: 46)
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(CosmicTheme.celestialPurple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("home.dailyInsight.title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text(L("home.dailyInsight.subtitle"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .cosmicGlassCard()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Learn Card
    private var learnCard: some View {
        Button {
            HapticManager.shared.lightImpact()
            viewModel.isShowingLearn = true
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CosmicTheme.mysticGold.opacity(0.18))
                        .frame(width: 46, height: 46)
                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(CosmicTheme.mysticGold)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("home.learn.title"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text(L("home.learn.subtitle"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            .cosmicGlassCard()
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Recent Readings
    private var recentReadingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L("home.recentReadings"))
                    .font(.system(size: 11, weight: .bold))
                    .localizedTracking(1.5)
                    .foregroundStyle(Color.white.opacity(0.5))
                
                Spacer()
                
                if !recentReadings.isEmpty {
                    Button(L("home.viewAll")) {
                        viewModel.isShowingHistory = true
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CosmicTheme.mysticGold)
                }
            }
            
            if recentReadings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "hand.wave")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.white.opacity(0.3))
                    Text(L("home.empty.title"))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.6))
                    Text(L("home.empty.subtitle"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .cosmicGlassCard()
            } else {
                ForEach(recentReadings.prefix(3)) { reading in
                    NavigationLink {
                        HistoryDetailView(reading: reading)
                    } label: {
                        HStack(spacing: 14) {
                            Circle()
                                .fill(CosmicTheme.mysticGold.opacity(0.2))
                                .frame(width: 42, height: 42)
                                .overlay(
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16))
                                        .foregroundStyle(CosmicTheme.mysticGold)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L(reading.archetype))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.white)
                                Text("\(reading.hand.localizedName) • \(reading.timestamp.localizedFormatted(date: .abbreviated, time: .shortened))")
                                    .font(.system(size: 11))
                                    .foregroundStyle(Color.white.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.3))
                        }
                        .cosmicGlassCard()
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
