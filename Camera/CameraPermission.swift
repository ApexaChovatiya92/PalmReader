//
//  CameraPermission.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import AVFoundation
import SwiftUI

@Observable
public final class CameraPermission {
    public enum Status {
        case notDetermined
        case authorized
        case denied
        case restricted
    }
    
    public var status: Status = .notDetermined
    
    public init() {
        checkStatus()
    }
    
    public func checkStatus() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            status = .authorized
        case .notDetermined:
            status = .notDetermined
        case .denied:
            status = .denied
        case .restricted:
            status = .restricted
        @unknown default:
            status = .denied
        }
    }
    
    public func requestPermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            self.status = granted ? .authorized : .denied
        }
        return granted
    }
}
