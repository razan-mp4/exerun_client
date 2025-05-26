//
//  LocationManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/8/2024.
//

import CoreLocation
import CoreMotion

protocol LocationManagerDelegate: AnyObject {
    func locationManager(_ manager: RunningLocationManager, didUpdateLocation location: CLLocation)
    func locationManager(_ manager: RunningLocationManager, didUpdateElevationGain elevationGain: Double)
    func locationManager(_ manager: RunningLocationManager, didFailWithError error: Error)
}

class RunningLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter() // Barometer for more accurate elevation tracking
    private var lastRelativeAltitude: Double = 0.0
    private var totalElevationGain: Double = 0.0
    private var isAltimeterAvailable: Bool = false
    private var lastTrackedLocation: CLLocation?
    private let movementThreshold: Double = 3.0 // Minimum movement distance in meters

    private var isStationary: Bool = false // Track stationary state
    private var stationaryCheckTimer: Timer? // Timer for periodic updates when stationary

    weak var delegate: LocationManagerDelegate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2.0
        locationManager.allowsBackgroundLocationUpdates = true // If needed
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()

        startAltimeterTracking() // Start tracking barometric altitude if available
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
        startAltimeterTracking()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        stopAltimeterTracking()
    }

    // MARK: - Altimeter (Barometer) Tracking
    private func startAltimeterTracking() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            isAltimeterAvailable = true
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] data, error in
                if let error = error {
                    print("Altimeter error: \(error)")
                    return
                }

                guard let altitudeData = data else { return }

                let altitudeChange = altitudeData.relativeAltitude.doubleValue
                self?.handleAltitudeChange(altitudeChange)
            }
        } else {
            isAltimeterAvailable = false
            print("Barometer not available on this device.")
        }
    }

    private func stopAltimeterTracking() {
        if isAltimeterAvailable {
            altimeter.stopRelativeAltitudeUpdates()
        }
    }

    private func handleAltitudeChange(_ altitudeChange: Double) {
        let elevationGain = altitudeChange - lastRelativeAltitude
        if elevationGain > 1.0 { // Filter minor changes
            totalElevationGain += elevationGain
            delegate?.locationManager(self, didUpdateElevationGain: totalElevationGain)
        }
        lastRelativeAltitude = altitudeChange
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        // Check speed
        if latestLocation.speed >= 0 && latestLocation.speed < 0.5 {
            print("Low speed detected: \(latestLocation.speed). Treating as stationary.")
            handleStationaryState()
            return
        }

        // Check distance
        if let lastLocation = lastTrackedLocation {
            let distance = latestLocation.distance(from: lastLocation)
            if distance < movementThreshold {
                print("Movement below threshold (\(distance) meters). Treating as stationary.")
                handleStationaryState()
                return
            }
        }

        // If valid location update, reset stationary state and stop stationary timer
        resetStationaryState()

        // Update the last tracked location
        lastTrackedLocation = latestLocation

        // Forward valid location updates to the delegate
        delegate?.locationManager(self, didUpdateLocation: latestLocation)

        // Fallback to GPS for elevation tracking if altimeter is not available
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

    // MARK: - Stationary State Handling
    private func handleStationaryState() {
        // Prevent duplicate updates if already stationary
        if isStationary { return }
        isStationary = true

        // Notify the delegate with a zero-speed update
        if let lastTrackedLocation = lastTrackedLocation {
            let stationaryLocation = CLLocation(
                coordinate: lastTrackedLocation.coordinate,
                altitude: lastTrackedLocation.altitude,
                horizontalAccuracy: lastTrackedLocation.horizontalAccuracy,
                verticalAccuracy: lastTrackedLocation.verticalAccuracy,
                course: lastTrackedLocation.course,
                speed: 0, // Explicitly set speed to zero
                timestamp: Date()
            )
            delegate?.locationManager(self, didUpdateLocation: stationaryLocation)
        }

        // Start a timer to periodically notify the delegate while stationary
        stationaryCheckTimer?.invalidate()
        stationaryCheckTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            guard let self = self, let lastTrackedLocation = self.lastTrackedLocation else { return }
            let stationaryLocation = CLLocation(
                coordinate: lastTrackedLocation.coordinate,
                altitude: lastTrackedLocation.altitude,
                horizontalAccuracy: lastTrackedLocation.horizontalAccuracy,
                verticalAccuracy: lastTrackedLocation.verticalAccuracy,
                course: lastTrackedLocation.course,
                speed: 0, // Explicitly set speed to zero
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

