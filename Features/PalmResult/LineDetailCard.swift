//
//  LineDetailCard.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct LineDetailCard: View {
    public let line: PalmLine
    public let interpretation: LineInterpretation
    
    public init(line: PalmLine, interpretation: LineInterpretation) {
        self.line = line
        self.interpretation = interpretation
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: line.type.iconName)
                    .font(.system(size: 22))
                    .foregroundStyle(line.type.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(line.type.localizedName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.white)
                    Text(line.type.domainArea)
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.shield.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(CosmicTheme.lifeLineColor)
                    Text(L("line.match", interpretation.confidencePercentage))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(CosmicTheme.surfaceDark)
                .clipShape(Capsule())
            }
            
            Divider().background(CosmicTheme.surfaceBorder)
            
            // Computer Vision Measured Metrics
            Text(L("line.measured"))
                .font(.system(size: 10, weight: .bold))
                .localizedTracking(1.5)
                .foregroundStyle(CosmicTheme.mysticGold)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricItem(title: L("metric.curvature"), value: String(format: "%.0f%%", line.curvature * 100), subtitle: L(line.curvature > 0.25 ? "metric.curvature.high" : "metric.curvature.low"))
                metricItem(title: L("metric.length"), value: String(format: "%.0f%%", line.length * 100), subtitle: L(line.length > 0.5 ? "metric.length.high" : "metric.length.low"))
                metricItem(title: L("metric.depth"), value: String(format: "%.0f%%", line.depth * 100), subtitle: L(line.depth > 0.65 ? "metric.depth.high" : "metric.depth.low"))
                metricItem(title: L("metric.continuity"), value: String(format: "%.0f%%", line.continuity * 100), subtitle: L(line.continuity > 0.88 ? "metric.continuity.high" : "metric.continuity.low"))
            }
            
            Divider().background(CosmicTheme.surfaceBorder)
            
            // Traditional Interpretation
            VStack(alignment: .leading, spacing: 8) {
                Text(L(interpretation.title))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(CosmicTheme.mysticGold)
                
                Text(L(interpretation.detailedReading))
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .lineSpacing(4)
            }
            
            // Key Traits Pills
            if !interpretation.keyTraits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L("line.keyAttributes"))
                        .font(.system(size: 10, weight: .bold))
                        .localizedTracking(1.2)
                        .foregroundStyle(Color.white.opacity(0.5))
                    
                    FlowLayout(spacing: 8) {
                        ForEach(interpretation.keyTraits, id: \.self) { trait in
                            Text(L(trait))
                                .font(.system(size: 11, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(line.type.accentColor.opacity(0.18))
                                .foregroundStyle(line.type.accentColor)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(line.type.accentColor.opacity(0.4), lineWidth: 1))
                        }
                    }
                }
            }
            
            // Guidance Advice Callout
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "sparkle")
                    .font(.system(size: 13))
                    .foregroundStyle(CosmicTheme.mysticGold)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("line.guidance"))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(CosmicTheme.mysticGold)
                    Text(L(interpretation.guidanceAdvice))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.8))
                }
            }
            .padding(12)
            .background(CosmicTheme.surfaceDark.opacity(0.9))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .cosmicGlassCard()
    }
    
    private func metricItem(title: String, value: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.5))
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(value)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(CosmicTheme.mysticGold.opacity(0.85))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(CosmicTheme.surfaceDark.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// Simple Flow layout for trait capsules
public struct FlowLayout: Layout {
    public var spacing: CGFloat = 8
    
    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        height = currentY + lineHeight
        return CGSize(width: width, height: height)
    }
    
    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX {
                currentX = bounds.minX
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
