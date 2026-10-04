//
//  LearnPalmistryView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public enum LearnTopic: String, CaseIterable, Identifiable {
    case history, hands, lines, mounts, shapes, markings, photo

    public var id: String { rawValue }
    public var titleKey: String { "learn.topic.\(rawValue).title" }

    public var icon: String {
        switch self {
        case .history: return "book.closed.fill"
        case .hands: return "hand.raised.fill"
        case .lines: return "scribble.variable"
        case .mounts: return "circle.hexagongrid.fill"
        case .shapes: return "square.on.circle"
        case .markings: return "sparkles"
        case .photo: return "camera.fill"
        }
    }
}

/// Palmistry guide: interactive palm map, topics and a short quiz
public struct LearnPalmistryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selection: PalmMapItem = .line(.life)

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                CosmicTheme.backgroundDark.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        LearnSectionHeader(key: "learn.map.header")
                        Text(L("learn.map.hint"))
                            .font(.system(size: 12))
                            .foregroundStyle(Color.white.opacity(0.6))

                        PalmMapView(selection: $selection)
                            .frame(height: 400)

                        MapItemDetail(item: selection)

                        LearnSectionHeader(key: "learn.topics.header")
                            .padding(.top, 6)

                        VStack(spacing: 10) {
                            ForEach(LearnTopic.allCases) { topic in
                                NavigationLink {
                                    LearnTopicView(topic: topic)
                                } label: {
                                    LearnRow(icon: topic.icon, titleKey: topic.titleKey, subtitleKey: nil)
                                }
                                .buttonStyle(.plain)
                            }

                            NavigationLink {
                                PalmistryQuizView()
                            } label: {
                                LearnRow(icon: "questionmark.circle.fill", titleKey: "learn.quiz.title", subtitleKey: "learn.quiz.subtitle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle(L("learn.navTitle"))
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
}

// MARK: - Map detail

private struct MapItemDetail: View {
    let item: PalmMapItem

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            switch item {
            case .line(let type):
                HStack(spacing: 8) {
                    Circle().fill(type.accentColor).frame(width: 10, height: 10)
                    Text(type.localizedName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                Text(type.domainArea)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CosmicTheme.mysticGold)
                Text(L("learn.\(type.nameKey).body"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            case .mount(let mount):
                HStack(spacing: 8) {
                    Circle().fill(CosmicTheme.celestialPurple).frame(width: 10, height: 10)
                    Text(mount.localizedName)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(Color.white)
                }
                Text(mount.keyword)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CosmicTheme.mysticGold)
                Text(L("learn.\(mount.nameKey).location"))
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlassCard()
    }
}

// MARK: - Topic pages

public struct LearnTopicView: View {
    public let topic: LearnTopic

    public var body: some View {
        ZStack {
            CosmicTheme.backgroundDark.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(L(topic.titleKey))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        switch topic {
        case .history:
            Paragraph(key: "learn.topic.history.body")
            Paragraph(key: "learn.topic.history.body2")
        case .hands:
            Paragraph(key: "learn.topic.hands.body")
            ForEach(HandType.allCases) { hand in
                EntryCard(title: hand.localizedName, subtitle: nil, text: hand.traditionDescription)
            }
        case .lines:
            ForEach(PalmLineType.allCases) { type in
                EntryCard(title: type.localizedName, subtitle: type.domainArea, text: L("learn.\(type.nameKey).body"), accent: type.accentColor)
            }
        case .mounts:
            ForEach(MountType.allCases) { mount in
                EntryCard(title: mount.localizedName, subtitle: mount.keyword, text: L("learn.\(mount.nameKey).location"))
            }
        case .shapes:
            Paragraph(key: "learn.topic.shapes.body")
            ForEach(["earth", "air", "fire", "water"], id: \.self) { element in
                EntryCard(title: L("element.\(element)"), subtitle: L("archetype.\(element)"), text: L("element.\(element).description"))
            }
        case .markings:
            EntryCard(title: MarkingType.fork.localizedName, subtitle: nil, text: L("marking.fork.reading"))
            EntryCard(title: MarkingType.breakMark.localizedName, subtitle: nil, text: L("marking.break.reading"))
            EntryCard(title: MarkingType.cross.localizedName, subtitle: nil, text: L("marking.cross.reading"))
            EntryCard(title: MarkingType.star.localizedName, subtitle: nil, text: L("learn.marking.star"))
            EntryCard(title: MarkingType.island.localizedName, subtitle: nil, text: L("learn.marking.island"))
            EntryCard(title: MarkingType.triangle.localizedName, subtitle: nil, text: L("marking.triangle.reading"))
            EntryCard(title: MarkingType.square.localizedName, subtitle: nil, text: L("marking.square.reading"))
        case .photo:
            ForEach(1...4, id: \.self) { i in
                EntryCard(title: "\(i)", subtitle: nil, text: L("learn.photo.tip\(i)"))
            }
        }
    }
}

// MARK: - Building blocks

private struct LearnSectionHeader: View {
    let key: String
    var body: some View {
        Text(L(key))
            .font(.system(size: 11, weight: .bold))
            .localizedTracking(1.5)
            .foregroundStyle(CosmicTheme.mysticGold)
    }
}

private struct LearnRow: View {
    let icon: String
    let titleKey: String
    let subtitleKey: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(CosmicTheme.celestialPurple)
                .frame(width: 36, height: 36)
                .background(CosmicTheme.celestialPurple.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(L(titleKey))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.white)
                if let subtitleKey {
                    Text(L(subtitleKey))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.white.opacity(0.55))
                }
            }
            Spacer()
            Image(systemName: "chevron.forward")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.35))
        }
        .padding(12)
        .background(CosmicTheme.surfaceDark.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CosmicTheme.surfaceBorder, lineWidth: 1))
    }
}

private struct Paragraph: View {
    let key: String
    var body: some View {
        Text(L(key))
            .font(.system(size: 14))
            .foregroundStyle(Color.white.opacity(0.85))
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct EntryCard: View {
    let title: String
    let subtitle: String?
    let text: String
    var accent: Color = CosmicTheme.mysticGold

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Circle().fill(accent).frame(width: 8, height: 8)
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.white)
            }
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CosmicTheme.mysticGold)
            }
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.8))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cosmicGlassCard()
    }
}
