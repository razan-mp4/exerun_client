//
//  CyclingLocationManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import CoreLocation
import CoreMotion

protocol CyclingLocationManagerDelegate: AnyObject {
    func locationManager(_ manager: CyclingLocationManager, didUpdateLocation location: CLLocation)
    func locationManager(_ manager: CyclingLocationManager, didUpdateElevationGain elevationGain: Double)
    func locationManager(_ manager: CyclingLocationManager, didFailWithError error: Error)
}

class CyclingLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter()
    private var lastRelativeAltitude: Double = 0.0
    private var totalElevationGain: Double = 0.0
    private var isAltimeterAvailable: Bool = false
    private var lastTrackedLocation: CLLocation?
    private let movementThreshold: Double = 3.0

    private var isStationary: Bool = false
    private var stationaryCheckTimer: Timer?

    weak var delegate: CyclingLocationManagerDelegate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2.0
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()
        
        startAltimeterTracking()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
        startAltimeterTracking()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        stopAltimeterTracking()
    }

    // MARK: - Altimeter Tracking
    private func startAltimeterTracking() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            isAltimeterAvailable = true
            altimeter.startRelativeAltitudeUpdates(to: .main) { [weak self] data, error in
                guard let self = self else { return }
                if let error = error {
                    print("Altimeter error: \(error.localizedDescription)")
                    return
                }

                if let altitudeData = data {
                    let altitudeChange = altitudeData.relativeAltitude.doubleValue
                    self.handleAltitudeChange(altitudeChange)
                }
            }
        } else {
            print("Altimeter not available.")
            isAltimeterAvailable = false
        }
    }

    private func stopAltimeterTracking() {
        if isAltimeterAvailable {
            altimeter.stopRelativeAltitudeUpdates()
        }
    }

    private func handleAltitudeChange(_ altitudeChange: Double) {
        let elevationGain = altitudeChange - lastRelativeAltitude
        if elevationGain > 1.0 {
            totalElevationGain += elevationGain
            delegate?.locationManager(self, didUpdateElevationGain: totalElevationGain)
        }
        lastRelativeAltitude = altitudeChange
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        // Detect stationary
        if latestLocation.speed >= 0 && latestLocation.speed < 0.5 {
            handleStationaryState()
            return
        }

        if let last = lastTrackedLocation {
            let distance = latestLocation.distance(from: last)
            if distance < movementThreshold {
                handleStationaryState()
                return
            }
        }

        resetStationaryState()
        lastTrackedLocation = latestLocation

        delegate?.locationManager(self, didUpdateLocation: latestLocation)

        if !isAltimeterAvailable {
            let elevationChange = latestLocation.altitude - (lastTrackedLocation?.altitude ?? latestLocation.altitude)
            if elevationChange > 1.0 {
                totalElevationGain += elevationChange
                delegate?.locationManager(self, didUpdateElevationGain: totalElevationGain)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }

    // MARK: - Stationary Handling
    private func handleStationaryState() {
        if isStationary { return }
        isStationary = true

        if let lastLocation = lastTrackedLocation {
            let stationaryLocation = CLLocation(
                coordinate: lastLocation.coordinate,
                altitude: lastLocation.altitude,
                horizontalAccuracy: lastLocation.horizontalAccuracy,
                verticalAccuracy: lastLocation.verticalAccuracy,
                course: lastLocation.course,
                speed: 0,
                timestamp: Date()
            )
            delegate?.locationManager(self, didUpdateLocation: stationaryLocation)
        }

        stationaryCheckTimer?.invalidate()
        stationaryCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, let lastLocation = self.lastTrackedLocation else { return }
            let stationaryLocation = CLLocation(
                coordinate: lastLocation.coordinate,
                altitude: lastLocation.altitude,
                horizontalAccuracy: lastLocation.horizontalAccuracy,
                verticalAccuracy: lastLocation.verticalAccuracy,
                course: lastLocation.course,
                speed: 0,
                timestamp: Date()
            )
            self.delegate?.locationManager(self, didUpdateLocation: stationaryLocation)
        }
    }

    private func resetStationaryState() {
        isStationary = false
        stationaryCheckTimer?.invalidate()
        stationaryCheckTimer = nil
    }
}
