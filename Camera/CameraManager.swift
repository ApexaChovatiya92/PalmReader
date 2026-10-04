//
//  CameraManager.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import AVFoundation
import UIKit
import Combine

public protocol CameraManagerDelegate: AnyObject {
    func cameraManager(_ manager: CameraManager, didOutputSampleBuffer sampleBuffer: CMSampleBuffer)
}

public final class CameraManager: NSObject {
    public weak var delegate: CameraManagerDelegate?
    
    public let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.palmistry.camera.sessionQueue", qos: .userInitiated)
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    
    private var photoContinuation: CheckedContinuation<UIImage, Error>?
    
    public private(set) var isRunning = false
    public var isSimulatorMode = false
    
    public override init() {
        super.init()
        #if targetEnvironment(simulator)
        isSimulatorMode = true
        #endif
    }
    
    private var isConfigured = false
    
    public func configureSession() {
        guard !isSimulatorMode else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isConfigured else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .photo
            
            // Setup Camera Input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else {
                self.captureSession.commitConfiguration()
                return
            }
            self.captureSession.addInput(videoInput)
            
            // Setup Video Output for Realtime Frames
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                self.videoOutput.videoSettings = [
                    kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
                ]
                self.videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.palmistry.camera.frameQueue", qos: .userInteractive))
                self.captureSession.addOutput(self.videoOutput)
                
                if let connection = self.videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                    }
                }
            }
            
            // Setup Photo Output for High-Res Still
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.photoOutput.isHighResolutionCaptureEnabled = true
                self.captureSession.addOutput(self.photoOutput)
                
                if let photoConnection = self.photoOutput.connection(with: .video) {
                    if photoConnection.isVideoOrientationSupported {
                        photoConnection.videoOrientation = .portrait
                    }
                }
            }
            
            self.captureSession.commitConfiguration()
            self.isConfigured = true
        }
    }
    
    public func startSession() {
        guard !isSimulatorMode else {
            isRunning = true
            return
        }
        sessionQueue.async { [weak self] in
            guard let self = self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            self.isRunning = self.captureSession.isRunning
        }
    }
    
    public func stopSession() {
        guard !isSimulatorMode else {
            isRunning = false
            return
        }
        sessionQueue.async { [weak self] in
            guard let self = self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            self.isRunning = false
        }
    }
    
    public func captureHighResPhoto() async throws -> UIImage {
        if isSimulatorMode {
            // Return generated mock palm image for simulator testing
            return createSimulatorPalmImage()
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: NSError(domain: "CameraManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Camera deallocated"]))
                    return
                }
                self.photoContinuation = continuation
                let settings = AVCapturePhotoSettings()
                settings.isHighResolutionPhotoEnabled = true
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }
    
    private func createSimulatorPalmImage() -> UIImage {
        SimulatedPalm.image(landmarks: HandPoseDetector.createMockLandmarks(for: .right))
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        delegate?.cameraManager(self, didOutputSampleBuffer: sampleBuffer)
    }
}

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoContinuation?.resume(throwing: error)
            photoContinuation = nil
            return
        }
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoContinuation?.resume(throwing: NSError(domain: "CameraManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode photo"]))
            photoContinuation = nil
            return
        }
        photoContinuation?.resume(returning: image)
        photoContinuation = nil
    }
}
