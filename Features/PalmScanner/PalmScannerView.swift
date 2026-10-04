//
//  PalmScannerView.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import AVFoundation
import PhotosUI

public struct PalmScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppEnvironment.self) private var env
    
    @State private var viewModel: PalmScannerViewModel
    @State private var photoItem: PhotosPickerItem?
    
    public init(handType: HandType, env: AppEnvironment = .shared) {
        _viewModel = State(initialValue: PalmScannerViewModel(handType: handType, env: env))
    }
    
    public var body: some View {
        ZStack {
            CosmicTheme.backgroundDark.ignoresSafeArea()
            
            // Camera Preview layer
            CameraPreviewView(session: viewModel.captureSession, isSimulator: viewModel.isSimulatorMode)
                .ignoresSafeArea()
            
            // Subtle dark vignette to emphasize hand guide
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.65)],
                center: .center,
                startRadius: 180,
                endRadius: 450
            )
            .ignoresSafeArea()
            
            if viewModel.cameraAccess == .granted {
                // Hand Silhouette & Real-time Landmark Skeleton Overlay
                HandOverlayGuideView(
                    landmarks: viewModel.landmarks,
                    quality: viewModel.quality,
                    handType: viewModel.handType
                )
                .ignoresSafeArea()
            }
            
            // Top Controls Bar
            VStack {
                topBar
                Spacer()
                switch viewModel.cameraAccess {
                case .granted:
                    // Bottom Guidance and Shutter Controls
                    bottomControls
                case .unavailable:
                    cameraUnavailableCard
                    Spacer()
                case .checking:
                    EmptyView()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Cosmic Scanning Progress Animation overlay during analysis
            if viewModel.isAnalyzing {
                PalmAnalysisProgressView()
                    .transition(.opacity)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onChange(of: photoItem) {
            guard let item = photoItem else { return }
            photoItem = nil
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                    viewModel.analyzeImportedPhoto(image)
                } else {
                    viewModel.errorMessageKey = "error.noHand"
                }
            }
        }
        .alert(
            L("error.title"),
            isPresented: Binding(
                get: { viewModel.errorMessageKey != nil },
                set: { if !$0 { viewModel.errorMessageKey = nil } }
            )
        ) {
            Button(L("common.ok"), role: .cancel) {}
        } message: {
            Text(L(viewModel.errorMessageKey ?? ""))
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.analysisResult != nil },
            set: { if !$0 { viewModel.analysisResult = nil } }
        )) {
            if let result = viewModel.analysisResult, let image = viewModel.capturedImage {
                PalmResultView(
                    readingInterpretation: result,
                    lines: viewModel.extractedLines,
                    palmImage: image,
                    handType: viewModel.handType
                )
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button {
                HapticManager.shared.lightImpact()
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.white.opacity(0.85))
            }
            
            Spacer()
            
            // Hand selector pill
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 13))
                Text(viewModel.handType.localizedName)
                    .font(.system(size: 13, weight: .bold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(CosmicTheme.surfaceGlass)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CosmicTheme.surfaceBorder, lineWidth: 1))
            .foregroundStyle(CosmicTheme.mysticGold)
        }
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        VStack(spacing: 20) {
            // Quality status pill
            HStack(spacing: 8) {
                Circle()
                    .fill(viewModel.quality.isGoodQuality ? CosmicTheme.lifeLineColor : CosmicTheme.mysticGold)
                    .frame(width: 8, height: 8)
                Text(L(viewModel.quality.guidanceMessage))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(CosmicTheme.surfaceDark.opacity(0.85))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(
                    viewModel.quality.isGoodQuality ? CosmicTheme.lifeLineColor.opacity(0.6) : CosmicTheme.surfaceBorder,
                    lineWidth: 1
                )
            )
            .mysticGlow(color: viewModel.quality.isGoodQuality ? CosmicTheme.lifeLineColor : Color.clear, radius: 8)
            .animation(.easeInOut(duration: 0.25), value: viewModel.quality.guidanceMessage)
            
            HStack {
                photoLibraryButton
                    .frame(width: 70)
                Spacer()
                shutterButton
                Spacer()
                Color.clear.frame(width: 70, height: 1)
            }
            .padding(.bottom, 16)
        }
    }
    
    private var photoLibraryButton: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            VStack(spacing: 4) {
                Image(systemName: "photo.on.rectangle")
                    .font(.system(size: 22))
                Text(L("scanner.photos"))
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(Color.white.opacity(0.9))
        }
        .disabled(viewModel.isAnalyzing)
        .accessibilityLabel(L("scanner.choosePhoto"))
    }
    
    private var cameraUnavailableCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.fill")
                .font(.system(size: 34))
                .foregroundStyle(CosmicTheme.mysticGold)
            Text(L("camera.denied.title"))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
            Text(L("camera.denied.body"))
                .font(.system(size: 13))
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
            
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label(L("scanner.choosePhoto"), systemImage: "photo.on.rectangle")
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(CosmicTheme.mysticGold)
                    .foregroundStyle(CosmicTheme.backgroundDark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            
            Button(L("camera.openSettings")) {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(CosmicTheme.mysticGold)
        }
        .cosmicGlassCard()
    }
    
    private var shutterButton: some View {
            // Shutter Button with Auto-Capture Countdown Ring
            ZStack {
                // Background outer ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 4)
                    .frame(width: 82, height: 82)
                
                // Progress countdown fill
                Circle()
                    .trim(from: 0, to: viewModel.countdownProgress)
                    .stroke(CosmicTheme.lifeLineColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 82, height: 82)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: viewModel.countdownProgress)
                
                // Trigger button
                Button {
                    viewModel.triggerManualCapture()
                } label: {
                    Circle()
                        .fill(viewModel.quality.isGoodQuality ? CosmicTheme.mysticGold : Color.white)
                        .frame(width: 66, height: 66)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(CosmicTheme.backgroundDark)
                        )
                }
            }
    }
}

// MARK: - Camera Preview Layer Representable
public struct CameraPreviewView: UIViewRepresentable {
    public let session: AVCaptureSession
    public var isSimulator: Bool = false
    
    public func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        if !isSimulator {
            view.videoPreviewLayer.session = session
            view.videoPreviewLayer.videoGravity = .resizeAspectFill
        }
        return view
    }
    
    public func updateUIView(_ uiView: PreviewUIView, context: Context) {}
}

public class PreviewUIView: UIView {
    public override class var layerClass: AnyClass {
        AVCaptureVideoPreviewLayer.self
    }
    
    public var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        layer as! AVCaptureVideoPreviewLayer
    }
}
