//
//  RunSessionModel.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/8/2024.
//

import Foundation
import CoreLocation

class RunSessionModel {
    // Raw data properties for calculations and storage
    private(set) var elapsedTimeInSeconds: Int = 0
    private(set) var maxSpeedValue: Double = 0.0 // in km/h
    private(set) var totalElevationGainInMeters: Double = 0.0
    private(set) var avgSpeedInKmh: Double = 0.0
    private(set) var currentSpeedInKmh: Double = 0.0
    private(set) var totalDistanceInKm: Double = 0.0
    private(set) var heartRateSum: Int = 0
    private(set) var heartRateCount: Int = 0
    private(set) var maxHeartRateValue: Int = 0
    private(set) var latestHeartRateValue: Int = 0 // Store the most recent heart rate value
    private(set) var avgHeartRateValue: Int = 0
    
    var hasChanged = false

    // Computed properties for formatted display strings
    var time: String {
        return String(format: "%02d:%02d:%02d", elapsedTimeInSeconds / 3600, (elapsedTimeInSeconds % 3600) / 60, elapsedTimeInSeconds % 60)
    }
    
    var maxSpeed: String {
        return String(format: "%.1f km/h", maxSpeedValue)
    }
    
    var avgSpeed: String {
        return String(format: "%.1f km/h", avgSpeedInKmh)
    }
    
    var speed: String {
        return String(format: "%.1f km/h", currentSpeedInKmh)
    }
    
    var distance: String {
        return String(format: "%.2f km", totalDistanceInKm)
    }
    
    var totalElevationGain: String {
        return String(format: "%.0f m", totalElevationGainInMeters)
    }
    
    var heartRate: String {
        return latestHeartRateValue > 0 ? "\(latestHeartRateValue) bpm" : "- bpm"
    }

    var maxHeartRate: String {
        return maxHeartRateValue > 0 ? "\(maxHeartRateValue) bpm" : "- bpm"
    }

    var averageHeartRate: String {
        guard heartRateCount > 0 else { return "- bpm" }
        let avgHeartRate = heartRateSum / heartRateCount
        return "\(avgHeartRate) bpm"
    }
    
    var avgPace: String {
        guard totalDistanceInKm > 0 else { return "0'00''/km" }
        let paceInSecondsPerKm = Double(elapsedTimeInSeconds) / totalDistanceInKm
        let minutes = Int(paceInSecondsPerKm) / 60
        let seconds = Int(paceInSecondsPerKm) % 60
        return String(format: "%d'%02d''/km", minutes, seconds)
    }

    // MARK: - Update Functions

    func updateTime(hours: Int, minutes: Int, seconds: Int) {
        self.elapsedTimeInSeconds = (hours * 3600) + (minutes * 60) + seconds
        updateAverageSpeed()
        hasChanged = true
    }
    
    func updateHeartRate(_ heartRate: Int) {
        latestHeartRateValue = heartRate // Update the most recent heart rate
        heartRateSum += heartRate
        heartRateCount += 1
        if heartRate > maxHeartRateValue {
            maxHeartRateValue = heartRate
        }
        hasChanged = true
        avgHeartRateValue = heartRateSum / heartRateCount
    }
    
    func updateLocation(location: CLLocation, lastLocation: CLLocation?) {
        guard let last = lastLocation else { return }
        
        let distance = last.distance(from: location) / 1000 // Convert to km
        self.totalDistanceInKm += distance
        
        if location.speed >= 0 {
            self.currentSpeedInKmh = location.speed * 3.6
            if self.currentSpeedInKmh > self.maxSpeedValue {
                self.maxSpeedValue = self.currentSpeedInKmh
            }
        }
        
        updateAveragePace()
        hasChanged = true
    }
    
    func updateElevationGain(_ elevationGain: Double) {
        self.totalElevationGainInMeters = elevationGain
        hasChanged = true
    }

    // MARK: - Private Helper Functions

    private func updateAverageSpeed() {
        guard elapsedTimeInSeconds > 0 else { return }
        avgSpeedInKmh = totalDistanceInKm / (Double(elapsedTimeInSeconds) / 3600)
    }
    
    private func updateAveragePace() {
        // Average pace calculation is handled by the avgPace computed property
    }
    
    // MARK: - Reset Functions

    func resetChangeFlag() {
        hasChanged = false
    }
    
    func reset() {
        elapsedTimeInSeconds = 0
        maxSpeedValue = 0.0
        totalElevationGainInMeters = 0.0
        avgSpeedInKmh = 0.0
        currentSpeedInKmh = 0.0
        totalDistanceInKm = 0.0
        heartRateSum = 0
        heartRateCount = 0
        maxHeartRateValue = 0
        latestHeartRateValue = 0
        hasChanged = false
    }
}

// MARK: – Free run ---------------------------------------------------------
extension RunSessionModel: WorkoutSessionConvertible {
    typealias Entity = FreeRunWorkOutEntity
    func fill(_ e: FreeRunWorkOutEntity) {
        e.avgPace          = avgPace
        e.avgSpeed         = avgSpeedInKmh
        e.distance         = totalDistanceInKm
        e.elevationGain    = Int32(totalElevationGainInMeters)
        e.avarageHeartRate = Int32(avgHeartRateValue)
        e.maxHeartRate     = Int32(maxHeartRateValue)
        e.maxSpeed         = maxSpeedValue
    }
}

/// Combines “running metrics” + “interval info” for Sets-Run screens
struct SetsRunCombined: WorkoutSessionConvertible {

    typealias Entity = SetsRunWorkOutEntity

    let run   : RunSessionModel
    let quick : QuickWorkoutModel

    func fill(_ e: SetsRunWorkOutEntity) {

        // ---- from RunSessionModel ----
        e.avgPace          = run.avgPace
        e.avgSpeed         = run.avgSpeedInKmh
        e.distance         = run.totalDistanceInKm
        e.elevationGain    = Int32(run.totalElevationGainInMeters)
        e.avarageHeartRate = Int32(run.avgHeartRateValue)
        e.maxHeartRate     = Int32(run.maxHeartRateValue)
        e.maxSpeed         = run.maxSpeedValue

        // ---- from QuickWorkoutModel ----
        e.workTime = Int32(quick.workMinutes*60 + quick.workSeconds)
        e.restTime = Int32(quick.restMinutes*60 + quick.restSeconds)
        e.quantity = Int32(quick.totalSets)
    }
}
