//
//  HandShapeCard.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

/// Measured hand element, palm shape and finger proportions with their traditional meanings
public struct HandShapeCard: View {
    public let shape: HandShapeAnalysis
    /// Element localization key, e.g. "element.air"
    public let elementKey: String

    public init(shape: HandShapeAnalysis, elementKey: String) {
        self.shape = shape
        self.elementKey = elementKey
    }

    private struct Trait: Identifiable {
        let id: String
        let icon: String
        let labelKey: String
        let ratio: Double
        let key: String
    }

    private var traits: [Trait] {
        let lead: String
        switch shape.fingerLead {
        case .index: lead = "handShape.indexRing.index"
        case .ring: lead = "handShape.indexRing.ring"
        case .balanced: lead = "handShape.indexRing.equal"
        }
        return [
            Trait(id: "palm", icon: "square.dashed", labelKey: "handShape.palm", ratio: shape.palmHeightToWidth,
                  key: shape.isSquarePalm ? "handShape.palm.square" : "handShape.palm.long"),
            Trait(id: "fingers", icon: "hand.raised", labelKey: "handShape.fingers", ratio: shape.fingerToPalm,
                  key: shape.hasLongFingers ? "handShape.fingers.long" : "handShape.fingers.short"),
            Trait(id: "indexRing", icon: "arrow.left.and.right", labelKey: "handShape.indexRing", ratio: shape.indexToRing, key: lead),
            Trait(id: "little", icon: "arrow.up.to.line", labelKey: "handShape.little", ratio: shape.littleReach,
                  key: shape.hasLongLittleFinger ? "handShape.little.long" : "handShape.little.short"),
            Trait(id: "thumb", icon: "hand.thumbsup", labelKey: "handShape.thumb", ratio: shape.thumbToIndex,
                  key: shape.hasLongThumb ? "handShape.thumb.long" : "handShape.thumb.short")
        ]
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L("handShape.header"))
                .font(.system(size: 11, weight: .bold))
                .localizedTracking(1.5)
                .foregroundStyle(CosmicTheme.mysticGold)

            // Element summary
            VStack(alignment: .leading, spacing: 4) {
                Text(L(elementKey))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.white)
                Text(L("\(elementKey).description"))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .lineSpacing(2)
            }

            ForEach(traits) { trait in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: trait.icon)
                        .font(.system(size: 15))
                        .foregroundStyle(CosmicTheme.celestialPurple)
                        .frame(width: 22)
                        .padding(.top, 2)

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(L(trait.labelKey))
                                .font(.system(size: 11))
                                .foregroundStyle(Color.white.opacity(0.5))
                            Spacer()
                            Text(L("handShape.ratio", String(format: "%.2f", trait.ratio)))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.white.opacity(0.4))
                        }
                        Text(L(trait.key))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.white)
                        Text(L("\(trait.key).meaning"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.75))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(12)
                .background(CosmicTheme.surfaceDark.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Text(L("handShape.note"))
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.45))
        }
        .cosmicGlassCard()
    }
}
