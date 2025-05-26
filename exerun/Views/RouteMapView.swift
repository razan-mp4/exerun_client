//
//  RouteMapView.swift
//  exerun
//
//  Created by Nazar Odemchuk on 14/11/2024.
//

import UIKit
import MapKit

class RouteMapView: UIView, MKMapViewDelegate {

    private var mapView: MKMapView!

    var segments: [[CLLocationCoordinate2D]]? {
        didSet {
            drawRoute()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupMapView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupMapView()
    }

    private func setupMapView() {
        mapView = MKMapView()
        mapView.delegate = self
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 20
        mapView.clipsToBounds = true
        addSubview(mapView)

        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mapView.topAnchor.constraint(equalTo: topAnchor),
            mapView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    // Method to draw the route on the map and center the view on it
    private func drawRoute() {
        guard let segments = segments else { return }
        
        // Remove existing overlays
        mapView.removeOverlays(mapView.overlays)

        // Create an array to hold all coordinates
        var allCoordinates: [CLLocationCoordinate2D] = []

        // Add each segment as an overlay and collect all coordinates
        for segment in segments {
            let polyline = MKPolyline(coordinates: segment, count: segment.count)
            mapView.addOverlay(polyline)
            allCoordinates.append(contentsOf: segment)
        }

        // Calculate the region that includes all coordinates
        if !allCoordinates.isEmpty {
            let boundingRegion = MKCoordinateRegion(coordinates: allCoordinates)
            mapView.setRegion(boundingRegion, animated: true)
        }
    }

    // MKMapViewDelegate method to render overlays
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .systemOrange
            renderer.lineWidth = 5
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

// Extension to calculate the bounding region for an array of coordinates
extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        let latitudes = coordinates.map { $0.latitude }
        let longitudes = coordinates.map { $0.longitude }

        let minLat = latitudes.min() ?? 0
        let maxLat = latitudes.max() ?? 0
        let minLon = longitudes.min() ?? 0
        let maxLon = longitudes.max() ?? 0

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2,
                                            longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.2,
                                    longitudeDelta: (maxLon - minLon) * 1.2) // Add padding to the span

        self.init(center: center, span: span)
    }
}
