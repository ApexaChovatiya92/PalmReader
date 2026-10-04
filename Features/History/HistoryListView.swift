//
//  HistoryListView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

public struct HistoryListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PalmReadingModel.timestamp, order: .reverse) private var readings: [PalmReadingModel]
    
    @State private var filterHand: HandType? = nil
    
    public init() {}
    
    private var filteredReadings: [PalmReadingModel] {
        if let filter = filterHand {
            return readings.filter { $0.hand == filter }
        }
        return readings
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()
                
                if readings.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 16) {
                        // Filter Chips
                        filterBar
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                        // Readings List
                        List {
                            ForEach(filteredReadings) { reading in
                                NavigationLink {
                                    HistoryDetailView(reading: reading)
                                } label: {
                                    historyRow(for: reading)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteReading(reading)
                                    } label: {
                                        Label(L("common.delete"), systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .navigationTitle(L("history.navTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) {
                        HapticManager.shared.lightImpact()
                        dismiss()
                    }
                    .foregroundStyle(CosmicTheme.mysticGold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private var filterBar: some View {
        HStack(spacing: 8) {
            filterChip(title: "\(L("history.filter.all")) (\(readings.count))", isSelected: filterHand == nil) {
                filterHand = nil
            }
            
            ForEach(HandType.allCases) { hand in
                let count = readings.filter { $0.hand == hand }.count
                filterChip(title: "\(hand.localizedName) (\(count))", isSelected: filterHand == hand) {
                    filterHand = hand
                }
            }
            Spacer()
        }
    }
    
    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticManager.shared.selectionChanged()
            action()
        }) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? CosmicTheme.mysticGold : CosmicTheme.surfaceDark)
                .foregroundStyle(isSelected ? CosmicTheme.backgroundDark : Color.white.opacity(0.8))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? CosmicTheme.mysticGold : CosmicTheme.surfaceBorder, lineWidth: 1)
                )
        }
    }
    
    private func historyRow(for reading: PalmReadingModel) -> some View {
        HStack(spacing: 14) {
            if let image = reading.palmImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 54, height: 54)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(CosmicTheme.surfaceDark)
                    .frame(width: 54, height: 54)
                    .overlay(
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(CosmicTheme.mysticGold)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(L(reading.archetype))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white)
                    
                    Text(verbatim: "•")
                        .foregroundStyle(Color.white.opacity(0.3))
                    
                    Text(L(reading.palmElement))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(CosmicTheme.mysticGold)
                }
                
                Text(L(reading.summary))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.65))
                    .lineLimit(1)
                
                Text("\(reading.hand.localizedName) • \(reading.timestamp.localizedFormatted(date: .abbreviated, time: .shortened))")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.white.opacity(0.4))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.3))
        }
        .cosmicGlassCard()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "books.vertical.fill")
                .font(.system(size: 40))
                .foregroundStyle(CosmicTheme.mysticGold.opacity(0.6))
            
            Text(L("history.empty.title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
            
            Text(L("history.empty.subtitle"))
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
    
    private func deleteReading(_ reading: PalmReadingModel) {
        withAnimation {
            modelContext.delete(reading)
            try? modelContext.save()
            HapticManager.shared.lightImpact()
        }
    }
}
