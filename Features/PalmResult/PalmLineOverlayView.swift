//
//  PalmLineOverlayView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public struct PalmLineOverlayView: View {
    public let image: UIImage
    public let lines: [PalmLine]
    @Binding public var selectedLineType: PalmLineType
    
    public init(image: UIImage, lines: [PalmLine], selectedLineType: Binding<PalmLineType>) {
        self.image = image
        self.lines = lines
        self._selectedLineType = selectedLineType
    }
    
    public var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            ZStack {
                // Captured Palm Image
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size.width, height: size.height)
                    .clipped()
                
                // Dark mystical overlay to make vector lines glow prominently
                Color.black.opacity(0.35)
                
                // Vector lines overlay
                ForEach(lines) { line in
                    let isSelected = line.type == selectedLineType
                    let path = linePath(for: line, in: size)
                    
                    // Outer glow for selected line
                    if isSelected {
                        path
                            .stroke(
                                line.type.accentColor.opacity(0.7),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round)
                            )
                            .blur(radius: 6)
                    }
                    
                    // Main vector path line
                    path
                        .stroke(
                            line.type.accentColor.opacity(isSelected ? 1.0 : 0.55),
                            style: StrokeStyle(
                                lineWidth: isSelected ? 4.5 : 2.5,
                                lineCap: .round,
                                lineJoin: .round,
                                dash: line.continuity < 0.85 ? [12, 4] : []
                            )
                        )
                        .mysticGlow(color: isSelected ? line.type.accentColor : Color.clear, radius: isSelected ? 10 : 0)
                        .onTapGesture {
                            HapticManager.shared.selectionChanged()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedLineType = line.type
                            }
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(CosmicTheme.surfaceBorder, lineWidth: 1.5)
            )
        }
        // Drawn in image coordinates, so it must not mirror in right-to-left languages
        .environment(\.layoutDirection, .leftToRight)
    }
    
    private func linePath(for line: PalmLine, in size: CGSize) -> Path {
        var path = Path()
        // The photo is drawn aspect-fill, so map points through the same scale and centered crop
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return path }
        let scale = max(size.width / imageSize.width, size.height / imageSize.height)
        let drawn = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let origin = CGPoint(x: (size.width - drawn.width) / 2, y: (size.height - drawn.height) / 2)
        let screenPoints = line.points.map { pt in
            CGPoint(x: origin.x + pt.x * drawn.width, y: origin.y + (1.0 - pt.y) * drawn.height)
        }
        
        guard let first = screenPoints.first else { return path }
        path.move(to: first)
        
        for i in 1..<screenPoints.count {
            let p0 = screenPoints[max(0, i - 1)]
            let p1 = screenPoints[i]
            let mid = p0.midpoint(to: p1)
            path.addQuadCurve(to: mid, control: p0)
        }
        if let last = screenPoints.last {
            path.addLine(to: last)
        }
        
        return path
    }
}
