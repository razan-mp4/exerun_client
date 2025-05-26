//
//  MapSelectionViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 21/11/2024.
//

import UIKit
import MapKit

protocol MapSelectionDelegate: AnyObject {
    func didSelectLocation(for type: SelectionType, location: CLLocationCoordinate2D, address: String?)
}

class MapSelectionViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    private var mapView = MKMapView()
    private let selectButton = UIButton(type: .system)
    private let centerPinView = UIImageView() // Center pin view
    private let centerLocationButton = UIButton(type: .system) // Button to center location
    private let mapTypeButton = UIButton(type: .system) // Button to change map type
    private let locationManager = CLLocationManager() // Location manager to track user location

    weak var delegate: MapSelectionDelegate?
    var selectionType: SelectionType?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLocationManager() // Request location permissions and setup manager
        setupCenterPinView() // Add the center pin view
        setupSelectLocationButton()
        setupButtons() // Add the mapType and centerLocation buttons
        setupSwipeDownLabel()
        setupSwipeAreaForDismissal()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update background colors after the view hierarchy is fully loaded
        updateButtonBackgroundColors()
    }

    private func setupMapView() {
        mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        mapView.showsUserLocation = true // Show user's location on the map
        mapView.mapType = .mutedStandard
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() // Request location permissions
        locationManager.startUpdatingLocation() // Start updating location
    }

    private func setupCenterPinView() {
        centerPinView.image = UIImage(systemName: "mappin") // Use "mappin" for a simple pin
        centerPinView.tintColor = .systemOrange // Change the pin color to orange
        centerPinView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(centerPinView)

        NSLayoutConstraint.activate([
            centerPinView.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            // Offset the centerYAnchor slightly upwards so the "point" aligns with the map center
            centerPinView.centerYAnchor.constraint(equalTo: mapView.centerYAnchor, constant: -30),
            centerPinView.widthAnchor.constraint(equalToConstant: 30),
            centerPinView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }


    private func setupSelectLocationButton() {
        selectButton.setTitle("Select", for: .normal)
        selectButton.setTitleColor(.white, for: .normal)
        selectButton.backgroundColor = .systemOrange
        selectButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        selectButton.layer.cornerRadius = 20
        selectButton.translatesAutoresizingMaskIntoConstraints = false
        selectButton.addTarget(self, action: #selector(selectLocationTapped), for: .touchUpInside)
        view.addSubview(selectButton)

        NSLayoutConstraint.activate([
            selectButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            selectButton.widthAnchor.constraint(equalToConstant: 100),
            selectButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupButtons() {
        // Configure center location button
        centerLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        centerLocationButton.tintColor = .systemOrange
        centerLocationButton.layer.cornerRadius = 10
        centerLocationButton.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        centerLocationButton.translatesAutoresizingMaskIntoConstraints = false
        centerLocationButton.addTarget(self, action: #selector(centerLocationTapped), for: .touchUpInside)

        // Configure map type button
        mapTypeButton.setImage(UIImage(systemName: "map.fill"), for: .normal)
        mapTypeButton.tintColor = .systemOrange
        mapTypeButton.layer.cornerRadius = 10
        mapTypeButton.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        mapTypeButton.translatesAutoresizingMaskIntoConstraints = false
        mapTypeButton.addTarget(self, action: #selector(mapTypeTapped), for: .touchUpInside)

        // Add buttons to the view
        view.addSubview(centerLocationButton)
        view.addSubview(mapTypeButton)

        // Set constraints for buttons
        NSLayoutConstraint.activate([
            // Center location button constraints
            centerLocationButton.widthAnchor.constraint(equalToConstant: 50),
            centerLocationButton.heightAnchor.constraint(equalToConstant: 50),
            centerLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            centerLocationButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),

            // Map type button constraints (below center location button)
            mapTypeButton.widthAnchor.constraint(equalToConstant: 50),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 50),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            mapTypeButton.topAnchor.constraint(equalTo: centerLocationButton.bottomAnchor, constant: 10)
        ])
    }

    private func updateButtonBackgroundColors() {
        let backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        centerLocationButton.backgroundColor = backgroundColor
        mapTypeButton.backgroundColor = backgroundColor
    }

    // Update button backgrounds when the trait collection changes (e.g., light/dark mode switch)
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // Check if the interface style changed
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateButtonBackgroundColors()
        }
    }

    private func setupSwipeDownLabel() {
        let swipeDownLabel = UILabel()
        swipeDownLabel.text = "Swipe down to close"
        swipeDownLabel.font = UIFont(name: "Avenir", size: 16)
        swipeDownLabel.textColor = .systemGray
        swipeDownLabel.textAlignment = .center
        swipeDownLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(swipeDownLabel)

        NSLayoutConstraint.activate([
            swipeDownLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            swipeDownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc private func centerLocationTapped() {
        if let userLocation = mapView.userLocation.location?.coordinate {
            centerMapOnLocation(coordinate: userLocation)
        }
    }

    private func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }

    @objc private func mapTypeTapped() {
        switch mapView.mapType {
        case .standard:
            mapView.mapType = .mutedStandard
        case .mutedStandard:
            mapView.mapType = .satellite
        case .satellite:
            mapView.mapType = .standard
        default:
            mapView.mapType = .standard
        }
    }

    @objc private func selectLocationTapped() {
        let centerCoordinate = mapView.centerCoordinate
        
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: centerCoordinate.latitude, longitude: centerCoordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }
            let address = placemarks?.first.flatMap { placemark in
                [
                    placemark.subThoroughfare,
                    placemark.thoroughfare,
                    placemark.locality
                ].compactMap { $0 }.joined(separator: ", ")
            }

            // Notify the delegate with the selection type
            if let type = self.selectionType {
                self.delegate?.didSelectLocation(for: type, location: centerCoordinate, address: address)
            }
            self.dismiss(animated: true, completion: nil)
        }
    }

    private func setupSwipeAreaForDismissal() {
        // Create a transparent view at the top of the screen
        let swipeAreaView = UIView()
        swipeAreaView.translatesAutoresizingMaskIntoConstraints = false
        swipeAreaView.backgroundColor = UIColor.clear
        view.addSubview(swipeAreaView)

        // Add constraints to place it at the top and make it larger than the swipe label
        NSLayoutConstraint.activate([
            swipeAreaView.topAnchor.constraint(equalTo: view.topAnchor),
            swipeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swipeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swipeAreaView.heightAnchor.constraint(equalToConstant: 100) // Adjust height as needed
        ])

        // Add a swipe-down gesture recognizer to this view
        let swipeDownGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeDownGesture.direction = .down
        swipeAreaView.addGestureRecognizer(swipeDownGesture)
    }

    @objc private func handleSwipeDown() {
        dismiss(animated: true, completion: nil)
    }

    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            centerMapOnLocation(coordinate: location.coordinate)
            locationManager.stopUpdatingLocation() // Stop updating to conserve battery
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}
