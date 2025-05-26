//
//  BuiltCyclingRouteViewController.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//

import UIKit
import MapKit
import CoreLocation

final class BuiltCyclingRouteViewController: UIViewController, MKMapViewDelegate {

    // --------------------------------------------------------------------
    // MARK: - Public data (set before presenting)
    // --------------------------------------------------------------------
    var route: [CLLocationCoordinate2D] = []   // injected
    var totalDistance: Double?                // metres (optional)

    // --------------------------------------------------------------------
    // MARK: - Private UI
    // --------------------------------------------------------------------
    private var mapView              = MKMapView()
    private let startButton          = UIButton(type: .system)
    private let mapTypeButton        = UIButton(type: .system)
    private let centerLocationButton = UIButton(type: .system)
    private let swipeDownLabel       = UILabel()
    private let totalDistanceLabel   = UILabel()

    // --------------------------------------------------------------------
    // MARK: - Lifecycle
    // --------------------------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
        setupButtons()
        setupStartButton()
        setupSwipeHint()
        setupTotalDistanceLabel()
        drawPolyline()

        CLLocationManager().requestWhenInUseAuthorization()

        // wait a moment to let MKMapView lay out before focusing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.focusMap() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateControlBackgrounds()
    }

    // keep dark / light in sync
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            updateControlBackgrounds()
        }
    }

    // --------------------------------------------------------------------
    // MARK: - Setup helpers
    // --------------------------------------------------------------------
    private func setupMapView() {
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.mapType = .mutedStandard
        mapView.showsUserLocation = true
        view.addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func setupButtons() {
        func stylise(_ btn: UIButton, systemName: String) {
            btn.setImage(UIImage(systemName: systemName), for: .normal)
            btn.tintColor = .systemOrange
            btn.layer.cornerRadius = 10
            btn.backgroundColor = .systemBackground // updated later
            btn.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(btn)
        }
        stylise(mapTypeButton,        systemName: "map.fill")
        stylise(centerLocationButton, systemName: "location.fill")

        mapTypeButton.addTarget(self, action: #selector(toggleMapType),  for: .touchUpInside)
        centerLocationButton.addTarget(self, action: #selector(centerTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            centerLocationButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -30),
            centerLocationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            centerLocationButton.widthAnchor.constraint(equalToConstant: 50),
            centerLocationButton.heightAnchor.constraint(equalToConstant: 50),

            mapTypeButton.topAnchor.constraint(equalTo: centerLocationButton.bottomAnchor, constant: 10),
            mapTypeButton.trailingAnchor.constraint(equalTo: centerLocationButton.trailingAnchor),
            mapTypeButton.widthAnchor.constraint(equalToConstant: 50),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func setupStartButton() {
        startButton.setTitle("Start Ride", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = .systemOrange
        startButton.titleLabel?.font = UIFont(name: "Avenir", size: 21)
        startButton.layer.cornerRadius = 20
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(startRide), for: .touchUpInside)
        view.addSubview(startButton)

        NSLayoutConstraint.activate([
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            startButton.widthAnchor.constraint(equalToConstant: 140),
            startButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupSwipeHint() {
        let swipeArea = UIView()
        swipeArea.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swipeArea)

        NSLayoutConstraint.activate([
            swipeArea.topAnchor.constraint(equalTo: view.topAnchor),
            swipeArea.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            swipeArea.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            swipeArea.heightAnchor.constraint(equalToConstant: 100)
        ])

        let swipe     = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipe.direction = .down
        swipeArea.addGestureRecognizer(swipe)

        // label
        swipeDownLabel.text = "Swipe down to close"
        swipeDownLabel.font = UIFont(name: "Avenir", size: 16)
        swipeDownLabel.textColor = .systemGray
        swipeDownLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(swipeDownLabel)

        NSLayoutConstraint.activate([
            swipeDownLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            swipeDownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func setupTotalDistanceLabel() {
        if let dist = totalDistance {
            totalDistanceLabel.text = "\(Int(dist)) m  "
        } else {
            totalDistanceLabel.text = "  Route distance: N/A  "
        }
        totalDistanceLabel.font = UIFont(name: "Avenir", size: 16)
        totalDistanceLabel.textColor = .systemOrange
        totalDistanceLabel.textAlignment = .center
        totalDistanceLabel.backgroundColor = .systemBackground // updated later
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

    // --------------------------------------------------------------------
    // MARK: - Map helpers
    // --------------------------------------------------------------------
    private func drawPolyline() {
        let poly = MKPolyline(coordinates: route, count: route.count)
        mapView.addOverlay(poly)
        mapView.setVisibleMapRect(poly.boundingMapRect,
                                  edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 50, right: 50),
                                  animated: true)
    }

    private func focusMap() {
        if !route.isEmpty {
            let poly = MKPolyline(coordinates: route, count: route.count)
            mapView.setVisibleMapRect(poly.boundingMapRect,
                                      edgePadding: UIEdgeInsets(top: 50, left: 50, bottom: 100, right: 50),
                                      animated: true)
        } else if let loc = mapView.userLocation.location?.coordinate {
            center(on: loc)
        }
    }
    private func center(on coord: CLLocationCoordinate2D) {
        mapView.setRegion(MKCoordinateRegion(center: coord,
                                             latitudinalMeters: 500,
                                             longitudinalMeters: 500),
                          animated: true)
    }

    // MARK: MKMapViewDelegate
    func mapView(_ mapView: MKMapView,
                 rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer() }
        let r = MKPolylineRenderer(polyline: poly)
        r.strokeColor = .systemOrange
        r.lineWidth   = 5
        return r
    }

    // --------------------------------------------------------------------
    // MARK: - Actions
    // --------------------------------------------------------------------
    @objc private func handleSwipeDown() { dismiss(animated: true) }

    @objc private func startRide() {
        performSegue(withIdentifier: "StartBuildCyclingSegue", sender: self)
    }

    @objc private func toggleMapType() {
        switch mapView.mapType {
        case .standard:       mapView.mapType = .mutedStandard
        case .mutedStandard:  mapView.mapType = .satellite
        default:              mapView.mapType = .standard
        }
    }

    @objc private func centerTap() { focusMap() }

    // --------------------------------------------------------------------
    // MARK: - Navigation
    // --------------------------------------------------------------------
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "StartBuildCyclingSegue",
           let dest = segue.destination as? BuildCyclingViewController {
            dest.route = route
        }
    }

    // --------------------------------------------------------------------
    // MARK: - Theming helpers
    // --------------------------------------------------------------------
    private func updateControlBackgrounds() {
        let bg = traitCollection.userInterfaceStyle == .dark ? UIColor.black : UIColor.white
        mapTypeButton.backgroundColor        = bg
        centerLocationButton.backgroundColor = bg
        totalDistanceLabel.backgroundColor   = bg
    }
}
