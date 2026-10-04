//
//  PalmResultView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

public struct PalmResultView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    public let readingInterpretation: FullReadingInterpretation
    public let lines: [PalmLine]
    public let palmImage: UIImage
    public let handType: HandType
    
    @State private var viewModel = PalmResultViewModel()
    
    public init(
        readingInterpretation: FullReadingInterpretation,
        lines: [PalmLine],
        palmImage: UIImage,
        handType: HandType
    ) {
        self.readingInterpretation = readingInterpretation
        self.lines = lines
        self.palmImage = palmImage
        self.handType = handType
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Hero Archetype & Elemental Banner
                        heroArchetypeBanner
                        
                        // Interactive Palm Image with AR Vector Line Overlay
                        PalmLineOverlayView(
                            image: palmImage,
                            lines: lines,
                            selectedLineType: $viewModel.selectedLineType
                        )
                        .frame(height: 380)
                        
                        // Line Selector Chips
                        lineSelectorChips
                        
                        if !undetectedLineNames.isEmpty {
                            Text(L("result.notDetected", LocalizationManager.shared.list(undetectedLineNames)))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.white.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Result Section Segmented Control
                        sectionPicker
                        
                        // Section Contents
                        switch viewModel.selectedSection {
                        case .lines:
                            if let selectedLine = lines.first(where: { $0.type == viewModel.selectedLineType }),
                               let interpretation = readingInterpretation.lineInterpretations.first(where: { $0.lineType == viewModel.selectedLineType }) {
                                LineDetailCard(line: selectedLine, interpretation: interpretation)
                            }
                        case .mounts:
                            MountAnalysisView(mounts: readingInterpretation.mountInterpretations)
                        case .markings:
                            markingsSection
                        case .overview:
                            if let shape = readingInterpretation.handShape {
                                HandShapeCard(shape: shape, elementKey: readingInterpretation.palmElement)
                            }
                            holisticOverviewSection
                        }
                        
                        // Action Buttons: Save & Share
                        actionButtons
                        
                        // Traditional Disclaimer Note
                        disclaimerNote
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L("result.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(L("common.done")) {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundStyle(CosmicTheme.mysticGold)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    ShareLink(
                        item: L("result.shareText", L(readingInterpretation.archetype), L(readingInterpretation.holisticSummary)),
                        preview: SharePreview(L("result.sharePreview"), image: Image(uiImage: palmImage))
                    ) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundStyle(CosmicTheme.mysticGold)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Start on a line that was actually found in the photo
            if !lines.contains(where: { $0.type == viewModel.selectedLineType }), let first = lines.first {
                viewModel.selectedLineType = first.type
            }
        }
    }
    
    /// Major lines that weren't clear enough in the photo to trace
    private var undetectedLineNames: [String] {
        [PalmLineType.life, .head, .heart, .fate]
            .filter { type in !lines.contains { $0.type == type } }
            .map(\.localizedName)
    }
    
    // MARK: - Hero Archetype Banner
    private var heroArchetypeBanner: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(CosmicTheme.mysticGold)
                Text("\(handType.localizedName.uppercased()) • \(L(readingInterpretation.palmElement).uppercased())")
                    .font(.system(size: 11, weight: .bold))
                    .localizedTracking(2)
                    .foregroundStyle(CosmicTheme.mysticGold)
            }
            
            Text(L(readingInterpretation.archetype))
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(CosmicTheme.mysticGoldGradient)
            
            Text(L(readingInterpretation.holisticSummary))
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.8))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)
        }
        .padding(.top, 4)
    }
    
    // MARK: - Line Selector Chips
    private var lineSelectorChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(lines) { line in
                    let isSelected = line.type == viewModel.selectedLineType
                    Button {
                        HapticManager.shared.selectionChanged()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.selectedLineType = line.type
                            viewModel.selectedSection = .lines
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(line.type.accentColor)
                                .frame(width: 8, height: 8)
                            Text(line.type.localizedName)
                                .font(.system(size: 13, weight: .bold))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? line.type.accentColor.opacity(0.25) : CosmicTheme.surfaceDark)
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? line.type.accentColor : CosmicTheme.surfaceBorder, lineWidth: 1)
                        )
                        .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.7))
                    }
                }
            }
        }
    }
    
    // MARK: - Section Picker
    private var sectionPicker: some View {
        Picker(L("result.section"), selection: $viewModel.selectedSection) {
            ForEach(PalmResultViewModel.ResultSection.allCases) { sec in
                Text(L(sec.titleKey)).tag(sec)
            }
        }
        .pickerStyle(.segmented)
    }
    
    // MARK: - Markings Section
    private var markingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("markings.header"))
                .font(.system(size: 11, weight: .bold))
                .localizedTracking(1.5)
                .foregroundStyle(CosmicTheme.mysticGold)
            
            if readingInterpretation.markings.isEmpty {
                Text(L("markings.none"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            
            ForEach(readingInterpretation.markings) { mark in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(CosmicTheme.celestialPurple.opacity(0.2))
                            .frame(width: 40, height: 40)
                        Image(systemName: "sparkles")
                            .font(.system(size: 16))
                            .foregroundStyle(CosmicTheme.celestialPurple)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L("markings.titleFormat", mark.type.localizedName, L(mark.location)))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(L(mark.interpretation))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .lineSpacing(2)
                    }
                }
                .padding(12)
                .background(CosmicTheme.surfaceDark.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .cosmicGlassCard()
    }
    
    // MARK: - Holistic Overview Section
    private var holisticOverviewSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L("overview.header"))
                .font(.system(size: 11, weight: .bold))
                .localizedTracking(1.5)
                .foregroundStyle(CosmicTheme.mysticGold)
            
            VStack(spacing: 12) {
                scoreBar(title: L("overview.vitality"), score: readingInterpretation.vitalityScore, color: CosmicTheme.lifeLineColor)
                scoreBar(title: L("overview.intuition"), score: readingInterpretation.intuitionScore, color: CosmicTheme.celestialPurple)
                scoreBar(title: L("overview.emotion"), score: readingInterpretation.emotionalBalanceScore, color: CosmicTheme.heartLineColor)
                scoreBar(title: L("overview.focus"), score: readingInterpretation.focusScore, color: CosmicTheme.headLineColor)
            }
        }
        .cosmicGlassCard()
    }
    
    private func scoreBar(title: String, score: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.9))
                Spacer()
                Text("\(score)%")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(color)
            }
            
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(CosmicTheme.surfaceDark)
                        .frame(height: 8)
                    Capsule()
                        .fill(color)
                        .frame(width: proxy.size.width * CGFloat(score) / 100.0, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.saveReading(
                    interpretation: readingInterpretation,
                    lines: lines,
                    image: palmImage,
                    hand: handType,
                    context: modelContext
                )
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isSaved ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                        .font(.system(size: 16))
                    Text(L(viewModel.isSaved ? "result.saved" : "result.save"))
                        .font(.system(size: 14, weight: .bold))
                        .localizedTracking(1)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(viewModel.isSaved ? CosmicTheme.surfaceDark : CosmicTheme.mysticGold)
                .foregroundStyle(viewModel.isSaved ? CosmicTheme.lifeLineColor : CosmicTheme.backgroundDark)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(viewModel.isSaved ? CosmicTheme.lifeLineColor.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            .disabled(viewModel.isSaved)
        }
    }
    
    // MARK: - Disclaimer Note (Roadmap Section 21)
    private var disclaimerNote: some View {
        Text("\(L("result.methodNote"))\n\n\(L("result.disclaimer"))")
            .font(.system(size: 11))
            .foregroundStyle(Color.white.opacity(0.4))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
    }
}
