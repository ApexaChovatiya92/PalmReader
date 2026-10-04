//
//  HistoryDetailView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

public struct HistoryDetailView: View {
    @Bindable public var reading: PalmReadingModel
    @Environment(\.modelContext) private var modelContext
    @State private var selectedLineType: PalmLineType = .life
    
    public init(reading: PalmReadingModel) {
        self.reading = reading
    }
    
    public var body: some View {
        ZStack {
            CosmicTheme.backgroundDark.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Details
                    VStack(spacing: 6) {
                        Text("\(reading.hand.localizedName.uppercased()) • \(L(reading.palmElement).uppercased())")
                            .font(.system(size: 11, weight: .bold))
                            .localizedTracking(2)
                            .foregroundStyle(CosmicTheme.mysticGold)
                        
                        Text(L(reading.archetype))
                            .font(.system(size: 22, weight: .black))
                            .foregroundStyle(CosmicTheme.mysticGoldGradient)
                        
                        Text(reading.timestamp.localizedFormatted(date: .complete, time: .shortened))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                    .padding(.top, 8)
                    
                    // Palm Image with lines
                    if let image = reading.palmImage {
                        PalmLineOverlayView(
                            image: image,
                            lines: reading.lines,
                            selectedLineType: $selectedLineType
                        )
                        .frame(height: 360)
                    }
                    
                    // Personal Reflection Notes (Interactive TextField)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L("history.notes.header"))
                            .font(.system(size: 11, weight: .bold))
                            .localizedTracking(1.5)
                            .foregroundStyle(CosmicTheme.mysticGold)
                        
                        TextField(L("history.notes.placeholder"), text: $reading.notes, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(12)
                            .background(CosmicTheme.surfaceDark)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(CosmicTheme.surfaceBorder, lineWidth: 1)
                            )
                            .onChange(of: reading.notes) {
                                try? modelContext.save()
                            }
                    }
                    .cosmicGlassCard()
                    
                    if let interpretation = reading.fullInterpretation, let shape = interpretation.handShape {
                        HandShapeCard(shape: shape, elementKey: interpretation.palmElement)
                    }
                    
                    // Saved Line Interpretations
                    if let interpretation = reading.fullInterpretation {
                        VStack(alignment: .leading, spacing: 16) {
                            Text(L("history.savedAnalysis"))
                                .font(.system(size: 11, weight: .bold))
                                .localizedTracking(1.5)
                                .foregroundStyle(CosmicTheme.mysticGold)
                            
                            ForEach(interpretation.lineInterpretations) { lineInterp in
                                if let matchedLine = reading.lines.first(where: { $0.type == lineInterp.lineType }) {
                                    LineDetailCard(line: matchedLine, interpretation: lineInterp)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(L(reading.archetype))
        .onAppear {
            let lines = reading.lines
            if !lines.contains(where: { $0.type == selectedLineType }), let first = lines.first {
                selectedLineType = first.type
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
