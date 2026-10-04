//
//  AppEnvironment.swift
//  PalmistryApp
//
//  Created for Offline Palmistry App.
//

import SwiftUI
import SwiftData

@Observable
public final class AppEnvironment {
    public static let shared = AppEnvironment()

    public let cameraManager: CameraManager
    public let handDetector: HandPoseDetector
    public let palmRegionDetector: PalmRegionDetector
    public let qualityAnalyzer: ImageQualityAnalyzer
    public let imageProcessor: PalmImageProcessor
    public let lineDetector: LineDetector
    public let classifier: PalmLineClassifier
    public let palmistryEngine: PalmistryEngine
    public let analysisPipeline: PalmAnalysisPipeline
    public let database: PalmistryDatabase
    
    public init(database: PalmistryDatabase = .shared) {
        self.cameraManager = CameraManager()
        self.handDetector = HandPoseDetector()
        self.palmRegionDetector = PalmRegionDetector()
        self.qualityAnalyzer = ImageQualityAnalyzer()
        self.imageProcessor = PalmImageProcessor()
        self.lineDetector = LineDetector()
        self.classifier = PalmLineClassifier()
        self.palmistryEngine = PalmistryEngine()
        self.analysisPipeline = PalmAnalysisPipeline(lineDetector: lineDetector, classifier: classifier, engine: palmistryEngine)
        self.database = database
    }
}
