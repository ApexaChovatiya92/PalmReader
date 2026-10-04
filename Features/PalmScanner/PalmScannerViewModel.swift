//
//  PalmScannerViewModel.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import CoreMedia
import AVFoundation
import UIKit

@Observable
public final class PalmScannerViewModel: NSObject, CameraManagerDelegate {
    public enum CameraAccess {
        case checking
        case granted
        /// Denied or restricted; the user can still import a photo
        case unavailable
    }

    public var handType: HandType
    public var landmarks: HandLandmarks?
    public var quality: QualityAssessment
    public var cameraAccess: CameraAccess = .checking
    public var isAnalyzing = false
    public var capturedImage: UIImage?
    public var analysisResult: FullReadingInterpretation?
    public var extractedLines: [PalmLine] = []
    /// Localization key of an analysis error to show, if any
    public var errorMessageKey: String?

    public var captureSession: AVCaptureSession {
        cameraManager.captureSession
    }
    public var isSimulatorMode: Bool {
        cameraManager.isSimulatorMode
    }

    // Auto-capture countdown
    public var countdownProgress: Double = 0.0
    private var steadyFramesCount = 0
    private let requiredSteadyFrames = 25
    #if targetEnvironment(simulator)
    private var simulatorTimer: Timer?
    #endif

    private let cameraManager: CameraManager
    private let handDetector: HandPoseDetector
    private let qualityAnalyzer: ImageQualityAnalyzer
    private let pipeline: PalmAnalysisPipeline
    private let permission = CameraPermission()

    public init(
        handType: HandType,
        env: AppEnvironment
    ) {
        self.handType = handType
        self.cameraManager = env.cameraManager
        self.handDetector = env.handDetector
        self.qualityAnalyzer = env.qualityAnalyzer
        self.pipeline = env.analysisPipeline

        self.quality = QualityAssessment(
            isGoodQuality: false,
            guidanceMessage: "guidance.placeHandGeneric",
            lightingScore: 0.8,
            handCoverageScore: 0.0,
            stabilityScore: 0.0
        )
        super.init()
        self.cameraManager.delegate = self
    }

    public func startScanning() {
        if cameraManager.isSimulatorMode {
            cameraAccess = .granted
            beginCamera()
            return
        }

        permission.checkStatus()
        switch permission.status {
        case .authorized:
            cameraAccess = .granted
            beginCamera()
        case .notDetermined:
            Task { @MainActor in
                let granted = await permission.requestPermission()
                cameraAccess = granted ? .granted : .unavailable
                if granted { beginCamera() }
            }
        case .denied, .restricted:
            cameraAccess = .unavailable
        }
    }

    private func beginCamera() {
        cameraManager.configureSession()
        cameraManager.startSession()

        #if targetEnvironment(simulator)
        simulatorTimer?.invalidate()
        simulatorTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self = self, !self.isAnalyzing else { return }
            if self.landmarks == nil {
                self.landmarks = HandPoseDetector.createMockLandmarks(for: self.handType)
            }
            self.quality = self.qualityAnalyzer.assessHand(landmarks: self.landmarks, expectedHand: self.handType)
            if self.quality.isGoodQuality {
                self.steadyFramesCount += 1
                self.countdownProgress = min(1.0, Double(self.steadyFramesCount) / Double(self.requiredSteadyFrames))
                if self.steadyFramesCount >= self.requiredSteadyFrames {
                    self.simulatorTimer?.invalidate()
                    self.simulatorTimer = nil
                    self.triggerCapture()
                }
            }
        }
        #endif
    }

    public func stopScanning() {
        cameraManager.stopSession()
        #if targetEnvironment(simulator)
        simulatorTimer?.invalidate()
        simulatorTimer = nil
        #endif
    }

    public func cameraManager(_ manager: CameraManager, didOutputSampleBuffer sampleBuffer: CMSampleBuffer) {
        guard !isAnalyzing else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let detectedLandmarks = handDetector.detectHand(in: pixelBuffer)
        let assessment = qualityAnalyzer.assessHand(landmarks: detectedLandmarks, expectedHand: handType)

        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.isAnalyzing else { return }
            self.landmarks = detectedLandmarks
            self.quality = assessment

            if assessment.isGoodQuality {
                self.steadyFramesCount += 1
                self.countdownProgress = min(1.0, Double(self.steadyFramesCount) / Double(self.requiredSteadyFrames))

                if self.steadyFramesCount >= self.requiredSteadyFrames {
                    self.triggerCapture()
                }
            } else {
                self.resetCountdown()
            }
        }
    }

    public func triggerManualCapture() {
        guard !isAnalyzing, cameraAccess == .granted else { return }
        triggerCapture()
    }

    /// Analyzes a photo the user picked from their library
    public func analyzeImportedPhoto(_ image: UIImage) {
        guard !isAnalyzing else { return }
        isAnalyzing = true
        HapticManager.shared.mediumImpact()
        Task { @MainActor in
            #if targetEnvironment(simulator)
            let mock = HandPoseDetector.createMockLandmarks(for: handType)
            await runPalmAnalysisPipeline(on: image, presetLandmarks: mock)
            #else
            await runPalmAnalysisPipeline(on: image, presetLandmarks: nil)
            #endif
        }
    }

    private func triggerCapture() {
        isAnalyzing = true
        HapticManager.shared.mediumImpact()

        Task { @MainActor in
            if cameraManager.isSimulatorMode {
                // No camera in the simulator: analyze a generated palm with known landmarks
                let mock = HandPoseDetector.createMockLandmarks(for: handType)
                await runPalmAnalysisPipeline(on: SimulatedPalm.image(landmarks: mock), presetLandmarks: mock)
                return
            }
            do {
                let photo = try await cameraManager.captureHighResPhoto()
                await runPalmAnalysisPipeline(on: photo, presetLandmarks: nil)
            } catch {
                print("Capture error: \(error.localizedDescription)")
                finishWithError("error.noHand")
            }
        }
    }

    @MainActor
    private func runPalmAnalysisPipeline(on image: UIImage, presetLandmarks: HandLandmarks?) async {
        let hand = handType
        let pipeline = pipeline

        // Run image processing and the palmistry rule engine off the main thread
        let outcome = await Task.detached(priority: .userInitiated) { () -> Result<PalmAnalysisResult, PalmAnalysisError> in
            do {
                return .success(try pipeline.analyze(image: image, hand: hand, presetLandmarks: presetLandmarks))
            } catch let error as PalmAnalysisError {
                return .failure(error)
            } catch {
                return .failure(.noHandFound)
            }
        }.value

        // Short pause so the analysis animation can finish its sequence
        try? await Task.sleep(nanoseconds: 800_000_000)

        switch outcome {
        case .success(let result):
            capturedImage = result.image
            extractedLines = result.lines
            analysisResult = result.reading
            isAnalyzing = false
            resetCountdown()
            HapticManager.shared.notifySuccess()
        case .failure(let error):
            finishWithError(error.messageKey)
        }
    }

    private func finishWithError(_ key: String) {
        errorMessageKey = key
        isAnalyzing = false
        resetCountdown()
        HapticManager.shared.notifyError()
    }

    private func resetCountdown() {
        steadyFramesCount = 0
        countdownProgress = 0.0
    }
}
