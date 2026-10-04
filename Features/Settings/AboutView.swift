//
//  AboutView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

/// What the app does, how readings are made, and how data is handled
public struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    public init() {}

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        section(icon: "hand.raised.fingers.spread.fill", titleKey: "about.what.header", bodyKey: "about.what.body")
                        section(icon: "ruler", titleKey: "about.how.header", bodyKey: "result.methodNote")
                        section(icon: "lock.fill", titleKey: "about.privacy.header", bodyKey: "about.privacy.body")
                        section(icon: "camera.fill", titleKey: "about.camera.header", bodyKey: "about.camera.body")
                        section(icon: "exclamationmark.shield", titleKey: "about.notice.header", bodyKey: "result.disclaimer")

                        Text(verbatim: "Aura Palm \(version)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L("about.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L("common.done")) { dismiss() }
                        .foregroundStyle(CosmicTheme.mysticGold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func section(icon: String, titleKey: String, bodyKey: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(L(titleKey), systemImage: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(CosmicTheme.mysticGold)
            Text(L(bodyKey))
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlassCard()
    }
}
