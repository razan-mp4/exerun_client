//
//  CompassManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 27/1/2025.
//

import CoreLocation

protocol CompassManagerDelegate: AnyObject {
    func compassManager(_ manager: CompassManager, didUpdateHeading heading: CLLocationDirection)
    func compassManager(_ manager: CompassManager, didUpdateCurrentElevation elevation: Double)
    func compassManager(_ manager: CompassManager, didFailWithError error: Error)
}

class CompassManager: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()

    weak var delegate: CompassManagerDelegate?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.headingFilter = 1 // Minimum degree change to report heading
        locationManager.desiredAccuracy = kCLLocationAccuracyBest // High accuracy for elevation
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
    }

    func stopTracking() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }

    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let magneticHeading = newHeading.magneticHeading
        delegate?.compassManager(self, didUpdateHeading: magneticHeading)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }

        // Use GPS altitude directly as the current elevation
        let currentElevation = latestLocation.altitude
        delegate?.compassManager(self, didUpdateCurrentElevation: currentElevation)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.compassManager(self, didFailWithError: error)
    }
}
