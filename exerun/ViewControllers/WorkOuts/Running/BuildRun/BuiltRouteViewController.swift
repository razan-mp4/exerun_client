//
//  BuiltRunViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 21/11/2024.
//

import UIKit
import MapKit

class BuiltRouteViewController: UIViewController, MKMapViewDelegate {
    
    var route: [CLLocationCoordinate2D] = [] // Route passed from NewBuildRunViewController
    var totalDistance: Double?
    
    private var mapView = MKMapView()
    private let startButton = UIButton(type: .system)
    private let mapTypeButton = UIButton(type: .system)
    private let centerLocationButton = UIButton(type: .system)
    private let swipeDownLabel = UILabel() // Swipe down label
    private let totalDistanceLabel = UILabel()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupStartButton()
        setupButtons()
        setupSwipeAreaForDismissal()
        setupSwipeDownLabel()
        setupTotalDistanceLabel()
        drawRoute()
        
        // Request location permissions
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        // Center the map initially
        // Add a small delay to ensure the map is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.focusMap()
        }
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
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupStartButton() {
        startButton.setTitle("Start", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = .systemOrange
        startButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        startButton.layer.cornerRadius = 20
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startWorkoutTapped), for: .touchUpInside)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.widthAnchor.constraint(equalToConstant: 100),
            startButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupButtons() {
        // Configure the map type button
        mapTypeButton.setImage(UIImage(systemName: "map.fill"), for: .normal)
        mapTypeButton.tintColor = .systemOrange
        mapTypeButton.layer.cornerRadius = 10
        mapTypeButton.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        mapTypeButton.translatesAutoresizingMaskIntoConstraints = false
        mapTypeButton.addTarget(self, action: #selector(mapTypeTapped), for: .touchUpInside)
        view.addSubview(mapTypeButton)

        // Configure the center location button
        centerLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        centerLocationButton.tintColor = .systemOrange
        centerLocationButton.layer.cornerRadius = 10
        centerLocationButton.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        centerLocationButton.translatesAutoresizingMaskIntoConstraints = false
        centerLocationButton.addTarget(self, action: #selector(centerLocationTapped), for: .touchUpInside)
        view.addSubview(centerLocationButton)

        // Add constraints
        NSLayoutConstraint.activate([
            // Center the buttons vertically on the screen
            centerLocationButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            centerLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            centerLocationButton.widthAnchor.constraint(equalToConstant: 50),
            centerLocationButton.heightAnchor.constraint(equalToConstant: 50),

            // Place the map type button below the center location button
            mapTypeButton.topAnchor.constraint(equalTo: centerLocationButton.bottomAnchor, constant: 10),
            mapTypeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 50),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }


    private func updateButtonBackgroundColors() {
        let backgroundColor = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        centerLocationButton.backgroundColor = backgroundColor
        mapTypeButton.backgroundColor = backgroundColor
        totalDistanceLabel.backgroundColor = backgroundColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateButtonBackgroundColors()
            
        }
    }

    private func drawRoute() {
        let polyline = MKPolyline(coordinates: route, count: route.count)
        mapView.addOverlay(polyline)
        mapView.setVisibleMapRect(polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50), animated: true)
    }

    private func setupSwipeAreaForDismissal() {
        let swipeAreaView = UIView()
        swipeAreaView.translatesAutoresizingMaskIntoConstraints = false
        swipeAreaView.backgroundColor = .clear
        view.addSubview(swipeAreaView)

        NSLayoutConstraint.activate([
            swipeAreaView.topAnchor.constraint(equalTo: view.topAnchor),
            swipeAreaView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swipeAreaView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swipeAreaView.heightAnchor.constraint(equalToConstant: 100)
        ])

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeGesture.direction = .down
        swipeAreaView.addGestureRecognizer(swipeGesture)
    }

    private func setupSwipeDownLabel() {
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
    
    private func setupTotalDistanceLabel() {
        totalDistanceLabel.text = totalDistance != nil
            ? "\(String(format: "%.0f", totalDistance!)) m  "
            : "  Route Distance: Not available  "
        totalDistanceLabel.font = UIFont(name: "Avenir", size: 16)
        totalDistanceLabel.textColor = .systemOrange
        totalDistanceLabel.textAlignment = .center
        totalDistanceLabel.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
        totalDistanceLabel.layer.cornerRadius = 15
        totalDistanceLabel.clipsToBounds = true
        totalDistanceLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(totalDistanceLabel)

        NSLayoutConstraint.activate([
            totalDistanceLabel.topAnchor.constraint(equalTo: swipeDownLabel.bottomAnchor, constant: 30),
            totalDistanceLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            totalDistanceLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }




    @objc private func handleSwipeDown() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func startWorkoutTapped() {
        performSegue(withIdentifier: "StartBuildRunSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartBuildRunSegue",
           let destinationVC = segue.destination as? BuildRunViewController {
            destinationVC.route = self.route // Pass the route data
        }
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

    @objc private func centerLocationTapped() {
        focusMap()
    }

    private func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    private func focusMap() {
        if !route.isEmpty {
            // Focus on the route's bounding map rect
            let polyline = MKPolyline(coordinates: route, count: route.count)
            let boundingRect = polyline.boundingMapRect
            mapView.setVisibleMapRect(
                boundingRect,
                edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 100, right: 50),
                animated: true
            )
        } else if let userLocation = mapView.userLocation.location?.coordinate {
            // Fallback to center on the user's current location
            centerMapOnLocation(coordinate: userLocation)
        } else {
            print("No route or user location available to center on.")
        }
    }
    
}

// Map overlay rendering
extension BuiltRouteViewController {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemOrange
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer()
    }
}
