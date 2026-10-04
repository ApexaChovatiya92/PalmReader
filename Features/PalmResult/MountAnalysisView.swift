//
//  MountAnalysisView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct MountAnalysisView: View {
    public let mounts: [MountAnalysis]
    
    public init(mounts: [MountAnalysis]) {
        self.mounts = mounts
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L("mounts.header"))
                .font(.system(size: 11, weight: .bold))
                .localizedTracking(1.5)
                .foregroundStyle(CosmicTheme.mysticGold)
            
            ForEach(mounts) { mount in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(mount.mount.localizedName)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(mount.mount.keyword)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(CosmicTheme.celestialPurple)
                            Text(L(levelKey(for: mount.prominence)))
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(CosmicTheme.mysticGold)
                        }
                    }
                    
                    // Prominence progress bar
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(CosmicTheme.surfaceDark)
                                .frame(height: 6)
                            
                            Capsule()
                                .fill(CosmicTheme.mysticGoldGradient)
                                .frame(width: proxy.size.width * CGFloat(mount.prominence), height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    // The traditional reading describes a developed mount; soft mounts get a gentler note
                    Text(mount.prominence >= 0.4 ? L(mount.interpretation) : L("mount.lowNote"))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .lineSpacing(2)
                }
                .padding(14)
                .background(CosmicTheme.surfaceDark.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(CosmicTheme.surfaceBorder, lineWidth: 0.8)
                )
            }
        }
        .cosmicGlassCard()
    }
    
    private func levelKey(for prominence: Double) -> String {
        switch prominence {
        case 0.66...: return "mount.level.high"
        case 0.4..<0.66: return "mount.level.mid"
        default: return "mount.level.low"
        }
    }
}
