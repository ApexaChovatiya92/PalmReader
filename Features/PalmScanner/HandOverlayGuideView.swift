//
//  HandOverlayGuideView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct HandOverlayGuideView: View {
    public var landmarks: HandLandmarks?
    public var quality: QualityAssessment
    public var handType: HandType
    
    public init(landmarks: HandLandmarks?, quality: QualityAssessment, handType: HandType) {
        self.landmarks = landmarks
        self.quality = quality
        self.handType = handType
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                // Outer subtle silhouette target box
                handGuideSilhouette(in: size)
                
                // Real-time landmark skeleton overlay if detected
                if let landmarks = landmarks, landmarks.confidence > 0.3 {
                    handSkeletonView(landmarks: landmarks, in: size)
                }
            }
        }
        // Drawn in image coordinates, so it must not mirror in right-to-left languages
        .environment(\.layoutDirection, .leftToRight)
    }
    
    private var guideColor: Color {
        quality.isGoodQuality ? CosmicTheme.lifeLineColor : CosmicTheme.mysticGold
    }
    
    // MARK: - Hand Guide Silhouette
    private func handGuideSilhouette(in size: CGSize) -> some View {
        let boxWidth = size.width * 0.72
        let boxHeight = size.height * 0.62
        
        return ZStack {
            // Target dashed rounded rectangle
            RoundedRectangle(cornerRadius: 32)
                .stroke(
                    guideColor.opacity(quality.isGoodQuality ? 0.9 : 0.4),
                    style: StrokeStyle(lineWidth: 2, dash: quality.isGoodQuality ? [] : [10, 8])
                )
                .frame(width: boxWidth, height: boxHeight)
                .overlay(
                    // Corner accents
                    ZStack {
                        cornerMarker(rotation: 0)
                            .offset(x: -boxWidth / 2, y: -boxHeight / 2)
                        cornerMarker(rotation: 90)
                            .offset(x: boxWidth / 2, y: -boxHeight / 2)
                        cornerMarker(rotation: 180)
                            .offset(x: boxWidth / 2, y: boxHeight / 2)
                        cornerMarker(rotation: 270)
                            .offset(x: -boxWidth / 2, y: boxHeight / 2)
                    }
                )
                .mysticGlow(color: guideColor, radius: quality.isGoodQuality ? 12 : 4)
                .animation(.easeInOut(duration: 0.3), value: quality.isGoodQuality)
        }
    }
    
    private func cornerMarker(rotation: Double) -> some View {
        Path { p in
            p.move(to: CGPoint(x: 0, y: 24))
            p.addLine(to: CGPoint(x: 0, y: 0))
            p.addLine(to: CGPoint(x: 24, y: 0))
        }
        .stroke(guideColor, lineWidth: 3.5)
        .frame(width: 24, height: 24)
        .rotationEffect(.degrees(rotation))
    }
    
    // MARK: - Real-time Landmark Skeleton
    private func handSkeletonView(landmarks: HandLandmarks, in size: CGSize) -> some View {
        Canvas { context, _ in
            let points = [
                landmarks.wrist,
                landmarks.thumbCMC, landmarks.thumbMP, landmarks.thumbIP, landmarks.thumbTip,
                landmarks.indexMCP, landmarks.indexPIP, landmarks.indexDIP, landmarks.indexTip,
                landmarks.middleMCP, landmarks.middlePIP, landmarks.middleDIP, landmarks.middleTip,
                landmarks.ringMCP, landmarks.ringPIP, landmarks.ringDIP, landmarks.ringTip,
                landmarks.littleMCP, landmarks.littlePIP, landmarks.littleDIP, landmarks.littleTip
            ]
            
            // Draw connecting finger bones
            let fingers = [
                [landmarks.wrist, landmarks.thumbCMC, landmarks.thumbMP, landmarks.thumbIP, landmarks.thumbTip],
                [landmarks.wrist, landmarks.indexMCP, landmarks.indexPIP, landmarks.indexDIP, landmarks.indexTip],
                [landmarks.wrist, landmarks.middleMCP, landmarks.middlePIP, landmarks.middleDIP, landmarks.middleTip],
                [landmarks.wrist, landmarks.ringMCP, landmarks.ringPIP, landmarks.ringDIP, landmarks.ringTip],
                [landmarks.wrist, landmarks.littleMCP, landmarks.littlePIP, landmarks.littleDIP, landmarks.littleTip]
            ]
            
            for finger in fingers {
                var path = Path()
                guard let first = finger.first else { continue }
                path.move(to: first.visionToScreen(viewSize: size))
                for pt in finger.dropFirst() {
                    path.addLine(to: pt.visionToScreen(viewSize: size))
                }
                context.stroke(path, with: .color(guideColor.opacity(0.6)), lineWidth: 2)
            }
            
            // Draw joint nodes
            for pt in points {
                let screenPt = pt.visionToScreen(viewSize: size)
                let rect = CGRect(x: screenPt.x - 4, y: screenPt.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: rect), with: .color(guideColor))
            }
        }
    }
}
