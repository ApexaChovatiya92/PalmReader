//
//  PalmAnalysisProgressView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct PalmAnalysisProgressView: View {
    @State private var rotationAngle: Double = 0
    @State private var pulseScale: CGFloat = 0.95
    @State private var currentStepIndex = 0
    
    private let analysisSteps = (1...5).map { "analysis.step\($0)" }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.black.opacity(0.85).ignoresSafeArea()
            
            VStack(spacing: 36) {
                // Sacred Geometry / Rotating Cosmic Rings
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [CosmicTheme.celestialPurple, CosmicTheme.astralCyan, CosmicTheme.mysticGold, CosmicTheme.celestialPurple],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(rotationAngle))
                    
                    // Dashed middle ring
                    Circle()
                        .stroke(CosmicTheme.mysticGold.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6]))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-rotationAngle * 0.8))
                    
                    // Center glowing mystic eye/hand icon
                    ZStack {
                        Circle()
                            .fill(CosmicTheme.deepIndigo)
                            .frame(width: 75, height: 75)
                            .scaleEffect(pulseScale)
                            .mysticGlow(color: CosmicTheme.mysticGold, radius: 18)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 30))
                            .foregroundStyle(CosmicTheme.mysticGoldGradient)
                    }
                }
                
                // Animated Status Text
                VStack(spacing: 10) {
                    Text(L("analysis.header"))
                        .font(.system(size: 13, weight: .bold))
                        .localizedTracking(3)
                        .foregroundStyle(CosmicTheme.mysticGold)
                    
                    Text(L(analysisSteps[currentStepIndex]))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .frame(height: 24)
                        .id(currentStepIndex)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                // Progress Dots
                HStack(spacing: 8) {
                    ForEach(0..<analysisSteps.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStepIndex ? CosmicTheme.mysticGold : Color.white.opacity(0.2))
                            .frame(width: 6, height: 6)
                            .animation(.easeInOut, value: currentStepIndex)
                    }
                }
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
            }
            // Cycle through step messages
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { timer in
                if currentStepIndex < analysisSteps.count - 1 {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStepIndex += 1
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
