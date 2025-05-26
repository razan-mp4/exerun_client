//
//  MapTrackingView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 30/8/2024.
//

import UIKit
import MapKit

class MapTrackingView: UIView, MKMapViewDelegate {

    private var mapView: MKMapView!
    private var segments: [[CLLocationCoordinate2D]] = []
    private var centerLocationButton: UIButton!
    private var mapTypeButton: UIButton!
    private var recenterTimer: Timer?
    private var routeSimplificationManager: RouteSimplificationManager!

    private var staticRouteOverlay: MKPolyline?
    
    // Expose mapView via a public computed property
    public var exposedMapView: MKMapView {
        return mapView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMapView()
        setupCenterLocationButton()
        setupMapTypeButton()
        setupRouteSimplificationManager()
        startNewSegment() // Start the first segment
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMapView()
        setupCenterLocationButton()
        setupMapTypeButton()
        setupRouteSimplificationManager()
        startNewSegment() // Start the first segment
    }
    
    private func setupRouteSimplificationManager() {
        // Initialize the manager with desired epsilon
        routeSimplificationManager = RouteSimplificationManager(epsilon: 0.5) // Adjust epsilon as needed
    }
    
    private func setupMapView() {
        mapView = MKMapView()
        mapView.mapType = traitCollection.userInterfaceStyle == .dark ? .mutedStandard : .standard
        mapView.setUserTrackingMode(.follow, animated: true)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.isScrollEnabled = true
        mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    private func setupCenterLocationButton() {
        centerLocationButton = UIButton(type: .system)
        centerLocationButton.translatesAutoresizingMaskIntoConstraints = false
        centerLocationButton.setImage(UIImage(systemName: "location.fill"), for: .normal)
        centerLocationButton.tintColor = .systemOrange
        updateButtonBackgroundColor(button: centerLocationButton)
        centerLocationButton.layer.cornerRadius = 10
        centerLocationButton.addTarget(self, action: #selector(centerLocationButtonTapped), for: .touchUpInside)
        addSubview(centerLocationButton)

        NSLayoutConstraint.activate([
            centerLocationButton.widthAnchor.constraint(equalToConstant: 50),
            centerLocationButton.heightAnchor.constraint(equalToConstant: 50),
            centerLocationButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            centerLocationButton.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -30) // Center vertically with an offset
        ])
    }

    private func setupMapTypeButton() {
        mapTypeButton = UIButton(type: .system)
        mapTypeButton.translatesAutoresizingMaskIntoConstraints = false
        mapTypeButton.setImage(UIImage(systemName: "map.fill"), for: .normal)
        mapTypeButton.tintColor = .systemOrange
        updateButtonBackgroundColor(button: mapTypeButton)
        mapTypeButton.layer.cornerRadius = 10
        mapTypeButton.addTarget(self, action: #selector(mapTypeButtonTapped), for: .touchUpInside)
        addSubview(mapTypeButton)

        NSLayoutConstraint.activate([
            mapTypeButton.widthAnchor.constraint(equalToConstant: 50),
            mapTypeButton.heightAnchor.constraint(equalToConstant: 50),
            mapTypeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            mapTypeButton.topAnchor.constraint(equalTo: centerLocationButton.bottomAnchor, constant: 10) // Below the centerLocationButton
        ])
    }



    private func resetRecenterTimer() {
        recenterTimer?.invalidate()
        recenterTimer = Timer.scheduledTimer(timeInterval: 15.0, target: self, selector: #selector(recenterMapAndFollow), userInfo: nil, repeats: false)
    }

    @objc private func centerLocationButtonTapped() {
        mapView.setUserTrackingMode(.followWithHeading, animated: true)
        configure3DMapView(at: mapView.userLocation.coordinate)
    }

    @objc private func mapTypeButtonTapped() {
        switch mapView.mapType {
        case .standard:
            mapView.pointOfInterestFilter = MKPointOfInterestFilter.includingAll
            mapView.mapType = .mutedStandard
        case .mutedStandard:
            mapView.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
            mapView.mapType = .satellite
        case .satellite:
            mapView.mapType = .standard
        default:
            mapView.mapType = .standard
        }
    }

    @objc private func recenterMapAndFollow() {
        if let userLocation = mapView.userLocation.location?.coordinate {
            centerMapOnLocation(coordinate: userLocation)
            mapView.setUserTrackingMode(.follow, animated: true)
        }
    }

    func centerMapOnLocation(coordinate: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
        mapView.setRegion(region, animated: true)
    }
    
    private func configure3DMapView(at location: CLLocationCoordinate2D) {
        let heading = mapView.camera.heading // Use the current heading of the camera
        let camera = MKMapCamera(lookingAtCenter: location, fromDistance: 1000, pitch: 60, heading: heading)
        mapView.setCamera(camera, animated: true)
    }
    
    // Method to start a new segment
    func startNewSegment() {
        segments.append([])
    }
    
    // Method to update the user's location on the map
    func updateLocation(coordinate: CLLocationCoordinate2D) {
        DispatchQueue.main.async {
            // Ensure we have at least one segment
            if self.segments.isEmpty {
                self.startNewSegment()
            }
            
            // Append the coordinate to the last segment
            var currentSegment = self.segments[self.segments.count - 1]
            currentSegment.append(coordinate)
            
            // Simplify the segment in place
            self.routeSimplificationManager.simplifySegmentInPlace(&currentSegment)
            self.segments[self.segments.count - 1] = currentSegment
            
            self.drawRoute()
        }
    }
    
    func setStaticRoute(_ route: [CLLocationCoordinate2D]) {
        // Remove any existing static route
        if let staticOverlay = staticRouteOverlay {
            mapView.removeOverlay(staticOverlay)
        }
        
        // Add the new static route
        if route.count > 1 {
            let polyline = MKPolyline(coordinates: route, count: route.count)
            staticRouteOverlay = polyline
            mapView.addOverlay(polyline)
        }
    }

    private func drawRoute() {
        // Remove all dynamic overlays (segments) without touching the static overlay
        let dynamicOverlays = mapView.overlays.filter { $0 !== staticRouteOverlay }
        mapView.removeOverlays(dynamicOverlays)
        
        // Add new polylines for each simplified segment
        for segment in segments {
            if segment.count > 1 {
                let polyline = MKPolyline(coordinates: segment, count: segment.count)
                mapView.addOverlay(polyline)
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            if overlay === staticRouteOverlay {
                // Static Route Styling
                renderer.strokeColor = UIColor.systemOrange
                renderer.lineWidth = 6 // Wider than dynamic
                renderer.lineDashPattern = [8, 4] // Dashed line pattern
                renderer.alpha = 0.3 // Slight transparency
            } else {
                // Dynamic Route Styling
                renderer.strokeColor = UIColor.systemOrange
                renderer.lineWidth = 5
                renderer.alpha = 1.0
            }
            return renderer
        }
        return MKOverlayRenderer()
    }




    // MKMapViewDelegate method to detect user interaction with the map
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        resetRecenterTimer()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateButtonBackgroundColor(button: centerLocationButton)
        updateButtonBackgroundColor(button: mapTypeButton)
    }

    private func updateButtonBackgroundColor(button: UIButton) {
        button.backgroundColor = traitCollection.userInterfaceStyle == .dark ? .black : .white
    }
    // Public getter to access segments
    public func getSegments() -> [[CLLocationCoordinate2D]] {
        return segments
    }
}
