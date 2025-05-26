//
//  SkiingLocationManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 30/1/2025.
//

import CoreLocation
import CoreMotion

protocol SkiingLocationManagerDelegate: AnyObject {
    func locationManager(_ manager: SkiingLocationManager, didUpdateLocation location: CLLocation)
    func locationManager(_ manager: SkiingLocationManager, didUpdateElevationGain elevationGain: Double)
    func locationManager(_ manager: SkiingLocationManager, didFailWithError error: Error)
}

class SkiingLocationManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let altimeter = CMAltimeter() // Barometer for elevation gain tracking
    private var lastBarometerAltitude: Double = 0.0
    private var totalElevationGain: Double = 0.0
    private var isAltimeterAvailable: Bool = false
    private var lastTrackedLocation: CLLocation?
    private let movementThreshold: Double = 5.0 // Minimum movement distance in meters to consider a valid location update
    private let speedThreshold: Double = 0.5 // Minimum speed to avoid treating as stationary

    private var isStationary: Bool = false // Track stationary state
    private var stationaryCheckTimer: Timer? // Timer for periodic updates when stationary

    weak var delegate: SkiingLocationManagerDelegate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 2.0
        locationManager.allowsBackgroundLocationUpdates = true // Enable background updates
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization()

        startBarometerTracking() // Start tracking barometric altitude for elevation gain
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
        startBarometerTracking()
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        stopBarometerTracking()
    }

    // MARK: - Barometer (Altimeter) Tracking for Elevation Gain
    private func startBarometerTracking() {
        if CMAltimeter.isRelativeAltitudeAvailable() {
            isAltimeterAvailable = true
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { [weak self] data, error in
                if let error = error {
                    print("Barometer error: \(error)")
                    return
                }

                guard let altitudeData = data else { return }

                // Calculate and update elevation gain
                let currentBarometerAltitude = altitudeData.relativeAltitude.doubleValue
                let elevationGain = currentBarometerAltitude - (self?.lastBarometerAltitude ?? currentBarometerAltitude)

                if elevationGain > 1.0 { // Avoid noise
                    self?.totalElevationGain += elevationGain
                    self?.delegate?.locationManager(self!, didUpdateElevationGain: self?.totalElevationGain ?? 0.0)
                }

                // Update the last barometer altitude
                self?.lastBarometerAltitude = currentBarometerAltitude
            }
        } else {
            isAltimeterAvailable = false
            print("Barometer not available on this device.")
        }
    }

    private func stopBarometerTracking() {
        if isAltimeterAvailable {
            altimeter.stopRelativeAltitudeUpdates()
        }
    }

    // MARK: - CLLocationManagerDelegate Methods
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        // Ignore updates with low speed (likely GPS noise)
        if latestLocation.speed < speedThreshold {
            handleStationaryState()
            return
        }

        // Ignore updates below the movement threshold
        if let lastLocation = lastTrackedLocation {
            let distance = latestLocation.distance(from: lastLocation)
            if distance < movementThreshold {
                print("Movement below threshold (\(distance) meters). Ignoring update.")
                return
            }
        }

        // Reset stationary state after valid movement
        resetStationaryState()

        // Update the last tracked location
        lastTrackedLocation = latestLocation

        // Forward valid location updates to the delegate
        delegate?.locationManager(self, didUpdateLocation: latestLocation)
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
