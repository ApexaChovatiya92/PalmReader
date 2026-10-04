//
//  DisclaimerView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

/// One-time notice shown on first launch explaining what the app is (and isn't)
public struct DisclaimerView: View {
    public static let acceptedKey = "app.hasAcceptedDisclaimer"

    @AppStorage(DisclaimerView.acceptedKey) private var hasAccepted = false

    public init() {}

    public var body: some View {
        ZStack {
            CosmicTheme.backgroundDark.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    Image(systemName: "hand.raised.fingers.spread.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(CosmicTheme.mysticGoldGradient)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 30)

                    Text(L("disclaimer.title"))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    point(icon: "sparkles", key: "disclaimer.point1")
                    point(icon: "exclamationmark.shield", key: "disclaimer.point2")
                    point(icon: "lock.fill", key: "disclaimer.point3")

                    Button {
                        HapticManager.shared.lightImpact()
                        hasAccepted = true
                    } label: {
                        Text(L("disclaimer.accept"))
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(CosmicTheme.mysticGoldGradient)
                            .foregroundStyle(CosmicTheme.backgroundDark)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled()
    }

    private func point(icon: String, key: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(CosmicTheme.mysticGold)
                .frame(width: 26)
            Text(L(key))
                .font(.system(size: 15))
                .foregroundStyle(Color.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlassCard()
    }
}
