//
//  HikeSessionModel.swift
//  exerun
//
//  Created by Nazar Odemchuk on 28/1/2025.
//

import Foundation
import CoreLocation

class HikeSessionModel {
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
    private(set) var minElevationValue: Double = Double.greatestFiniteMagnitude
    private(set) var maxElevationValue: Double = Double.leastNormalMagnitude

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

    var maxElevation: String {
        if maxElevationValue < -8000 {
            return "0 m"
        }
        return String(format: "%.0f m", maxElevationValue)
    }
    var minElevation: String {
        if minElevationValue > 8000 {
            return "0 m"
        }
        return String(format: "%.0f m", minElevationValue)
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

    func updateElevation(currentElevation: Double) {
        if currentElevation < minElevationValue {
            minElevationValue = currentElevation
        }

        if currentElevation > maxElevationValue {
            maxElevationValue = currentElevation
        }

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
        minElevationValue = Double.greatestFiniteMagnitude
        maxElevationValue = Double.leastNormalMagnitude
        hasChanged = false
    }
}

// MARK: – Hiking -----------------------------------------------------------
extension HikeSessionModel: WorkoutSessionConvertible {
    typealias Entity = HikeWorkOutEntity
    func fill(_ e: HikeWorkOutEntity) {
        e.avgPace          = avgPace
        e.avgSpeed         = avgSpeedInKmh
        e.distance         = totalDistanceInKm
        e.elevationGain    = Int32(totalElevationGainInMeters)
        e.avarageHeartRate = Int32(avgHeartRateValue)
        e.maxHeartRate     = Int32(maxHeartRateValue)
        e.maxSpeed         = maxSpeedValue
        e.minElevation     = minElevationValue
        e.maxElevation     = maxElevationValue
    }
}
