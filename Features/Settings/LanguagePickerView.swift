//
//  LanguagePickerView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    private let localization = LocalizationManager.shared

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        Text(L("language.subtitle"))
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 6)

                        ForEach(AppLanguage.allCases) { language in
                            languageRow(language)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L("language.title"))
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

    private func languageRow(_ language: AppLanguage) -> some View {
        let isSelected = localization.language == language
        return Button {
            HapticManager.shared.selectionChanged()
            withAnimation(.easeInOut(duration: 0.2)) {
                localization.language = language
            }
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(language.nativeName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                    if language != .english {
                        Text(language.englishName)
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? CosmicTheme.mysticGold : Color.white.opacity(0.25))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? CosmicTheme.mysticGold.opacity(0.12) : CosmicTheme.surfaceDark.opacity(0.8))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? CosmicTheme.mysticGold : CosmicTheme.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
