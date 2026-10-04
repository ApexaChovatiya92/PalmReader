//
//  PalmMapView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI

public enum PalmMapItem: Hashable {
    case line(PalmLineType)
    case mount(MountType)
}

/// Diagram geometry in the drawn palm's pixel space; built once and reused
struct PalmMapModel {
    static let shared = PalmMapModel()

    let image: UIImage
    let size: CGSize
    let lines: [(PalmLineType, [CGPoint])]
    let mounts: [(MountType, CGPoint)]

    private init() {
        let landmarks = HandPoseDetector.createMockLandmarks(for: .right)
        size = SimulatedPalm.size
        image = SimulatedPalm.image(landmarks: landmarks)
        let frame = HandFrame(landmarks: landmarks, width: size.width, height: size.height)
        let lm = frame.px
        func at(_ base: CGPoint, up: CGFloat, thumbward: CGFloat) -> CGPoint {
            base + frame.up * (up * frame.palmHeight) + frame.thumbward * (thumbward * frame.palmWidth)
        }

        // Sun and Mercury lines are often faint, so the scanner doesn't trace them; they're drawn here for learning
        let sun = [at(lm.palmCenter, up: -0.2, thumbward: -0.2), at(lm.ringMCP, up: -0.3, thumbward: 0)]
        let mercury = [at(lm.wrist, up: 0.2, thumbward: -0.3), at(lm.littleMCP, up: -0.3, thumbward: 0.05)]
        lines = LineDetector.expectedPaths(in: frame) + [(.sun, sun.resampled(count: 20)), (.mercury, mercury.resampled(count: 20))]

        mounts = [
            (.jupiter, at(lm.indexMCP, up: -0.1, thumbward: 0)),
            (.saturn, at(lm.middleMCP, up: -0.1, thumbward: 0)),
            (.apollo, at(lm.ringMCP, up: -0.1, thumbward: 0)),
            (.mercury, at(lm.littleMCP, up: -0.1, thumbward: 0)),
            (.venus, lm.thumbCMC.lerp(to: lm.wrist, 0.45)),
            (.moon, at(lm.wrist, up: 0.25, thumbward: -0.4)),
            (.mars, at(lm.palmCenter, up: -0.05, thumbward: -0.1))
        ]
    }
}

/// Palm diagram where tapping a line or mount selects it
public struct PalmMapView: View {
    @Binding public var selection: PalmMapItem
    private let model = PalmMapModel.shared

    public init(selection: Binding<PalmMapItem>) {
        self._selection = selection
    }

    public var body: some View {
        GeometryReader { proxy in
            let fit = min(proxy.size.width / model.size.width, proxy.size.height / model.size.height)
            let origin = CGPoint(x: (proxy.size.width - model.size.width * fit) / 2,
                                 y: (proxy.size.height - model.size.height * fit) / 2)
            let toView = { (p: CGPoint) in CGPoint(x: origin.x + p.x * fit, y: origin.y + p.y * fit) }

            ZStack {
                Image(uiImage: model.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: model.size.width * fit, height: model.size.height * fit)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Canvas { context, _ in
                    for (type, points) in model.lines {
                        let isSelected = selection == .line(type)
                        var path = Path()
                        path.addLines(points.map(toView))
                        let dash: [CGFloat] = (type == .sun || type == .mercury) ? [6, 5] : []
                        if isSelected {
                            context.stroke(path, with: .color(type.accentColor.opacity(0.5)), style: StrokeStyle(lineWidth: 12, lineCap: .round))
                        }
                        context.stroke(path, with: .color(type.accentColor.opacity(isSelected ? 1 : 0.6)),
                                       style: StrokeStyle(lineWidth: isSelected ? 5 : 3, lineCap: .round, dash: dash))
                    }
                    for (mount, point) in model.mounts {
                        let isSelected = selection == .mount(mount)
                        let center = toView(point)
                        let radius: CGFloat = isSelected ? 13 : 10
                        let circle = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                        context.fill(circle, with: .color(isSelected ? CosmicTheme.mysticGold : CosmicTheme.celestialPurple.opacity(0.75)))
                        context.stroke(circle, with: .color(.white.opacity(0.9)), lineWidth: 1.5)
                    }
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                if let item = item(at: location, toView: toView) {
                    HapticManager.shared.selectionChanged()
                    withAnimation(.easeInOut(duration: 0.2)) { selection = item }
                }
            }
        }
        .background(CosmicTheme.surfaceDark.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(CosmicTheme.surfaceBorder, lineWidth: 1))
        // A diagram of a hand: never mirror it in right-to-left languages
        .environment(\.layoutDirection, .leftToRight)
    }

    /// Mounts win within 28pt; otherwise the nearest line within 24pt
    private func item(at location: CGPoint, toView: (CGPoint) -> CGPoint) -> PalmMapItem? {
        let nearestMount = model.mounts
            .map { ($0.0, toView($0.1).distance(to: location)) }
            .min { $0.1 < $1.1 }
        if let nearestMount, nearestMount.1 < 28 { return .mount(nearestMount.0) }

        let nearestLine = model.lines
            .map { type, points in (type, points.map { toView($0).distance(to: location) }.min() ?? .infinity) }
            .min { $0.1 < $1.1 }
        if let nearestLine, nearestLine.1 < 24 { return .line(nearestLine.0) }
        return nil
    }
}
