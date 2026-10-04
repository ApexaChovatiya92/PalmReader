//
//  PalmistryQuizView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

private struct QuizQuestion {
    let promptKey: String
    let optionKeys: [String]
    let answerIndex: Int
}

/// Five questions drawn from the Learn topics
public struct PalmistryQuizView: View {
    private let questions = [
        QuizQuestion(promptKey: "quiz.q1", optionKeys: ["line.head", "line.life", "line.heart"], answerIndex: 1),
        QuizQuestion(promptKey: "quiz.q2", optionKeys: ["mount.saturn", "mount.venus", "mount.jupiter"], answerIndex: 2),
        QuizQuestion(promptKey: "quiz.q3", optionKeys: ["line.fate", "line.sun", "line.heart"], answerIndex: 0),
        QuizQuestion(promptKey: "quiz.q4", optionKeys: ["quiz.q4.b", "quiz.q4.a", "quiz.q4.c"], answerIndex: 1),
        QuizQuestion(promptKey: "quiz.q5", optionKeys: ["mount.moon", "mount.mars", "mount.venus"], answerIndex: 2)
    ]

    @State private var index = 0
    @State private var chosen: Int?
    @State private var score = 0
    @State private var isFinished = false

    public init() {}

    public var body: some View {
        ZStack {
            CosmicTheme.backgroundDark.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    if isFinished {
                        resultView
                    } else {
                        questionView(questions[index])
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle(L("learn.quiz.title"))
        .navigationBarTitleDisplayMode(.inline)
    }

    private func questionView(_ question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L("quiz.questionFormat", index + 1, questions.count))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(CosmicTheme.mysticGold)

            Text(L(question.promptKey))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(question.optionKeys.indices, id: \.self) { option in
                Button {
                    guard chosen == nil else { return }
                    chosen = option
                    if option == question.answerIndex {
                        score += 1
                        HapticManager.shared.notifySuccess()
                    } else {
                        HapticManager.shared.notifyError()
                    }
                } label: {
                    HStack {
                        Text(L(question.optionKeys[option]))
                            .font(.system(size: 15, weight: .semibold))
                            .multilineTextAlignment(.leading)
                        Spacer()
                        if let chosen, option == question.answerIndex || option == chosen {
                            Image(systemName: option == question.answerIndex ? "checkmark.circle.fill" : "xmark.circle.fill")
                        }
                    }
                    .padding(14)
                    .foregroundStyle(Color.white)
                    .background(RoundedRectangle(cornerRadius: 14).fill(optionColor(option, question: question)))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(CosmicTheme.surfaceBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if let chosen {
                Text(chosen == question.answerIndex
                     ? L("quiz.correct")
                     : L("quiz.incorrect", L(question.optionKeys[question.answerIndex])))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(chosen == question.answerIndex ? CosmicTheme.lifeLineColor : CosmicTheme.heartLineColor)

                Button {
                    if index + 1 < questions.count {
                        index += 1
                        self.chosen = nil
                    } else {
                        isFinished = true
                    }
                } label: {
                    Text(L(index + 1 < questions.count ? "quiz.next" : "quiz.finish"))
                        .font(.system(size: 15, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CosmicTheme.mysticGold)
                        .foregroundStyle(CosmicTheme.backgroundDark)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func optionColor(_ option: Int, question: QuizQuestion) -> Color {
        guard let chosen else { return CosmicTheme.surfaceDark.opacity(0.8) }
        if option == question.answerIndex { return CosmicTheme.lifeLineColor.opacity(0.3) }
        if option == chosen { return CosmicTheme.heartLineColor.opacity(0.3) }
        return CosmicTheme.surfaceDark.opacity(0.8)
    }

    private var resultView: some View {
        VStack(spacing: 18) {
            Image(systemName: score == questions.count ? "star.circle.fill" : "sparkles")
                .font(.system(size: 54))
                .foregroundStyle(CosmicTheme.mysticGoldGradient)
                .padding(.top, 30)
            Text(L("quiz.scoreFormat", score, questions.count))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
            Button {
                index = 0
                chosen = nil
                score = 0
                isFinished = false
            } label: {
                Text(L("quiz.retry"))
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CosmicTheme.mysticGold)
                    .foregroundStyle(CosmicTheme.backgroundDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .frame(maxWidth: .infinity)
    }
}
