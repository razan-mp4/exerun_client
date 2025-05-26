//
//  RouteBuilderManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 21/11/2024.
//

import CoreLocation
import MapKit

class RouteBuilderManager {
    func generateRoute(
        startingPoint: CLLocationCoordinate2D,
        finishingPoint: CLLocationCoordinate2D,
        distance: Int,
        completion: @escaping ([CLLocationCoordinate2D]?, Double?) -> Void
    ) {
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: startingPoint)
        let destinationPlacemark = MKPlacemark(coordinate: finishingPoint)
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .walking // Use .automobile if needed

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }

            guard let route = response?.routes.first else {
                print("No routes found.")
                completion(nil, nil)
                return
            }

            let routeDistance = route.distance // in meters
            let desiredDistance = Double(distance) * 1000.0 // km to meters

            print("Initial route distance: \(routeDistance) meters")
            print("Desired distance: \(desiredDistance) meters")

            if routeDistance >= desiredDistance {
                print("Generated route is long enough, returning route.")
                let routeCoordinates = route.polyline.coordinates
                completion(routeCoordinates, routeDistance)
            } else {
                // Need to add waypoints and recalculate the route
                let extraDistanceNeeded = desiredDistance - routeDistance
                let extraDistancePerWaypoint = extraDistanceNeeded / 9.0

                print("Route is shorter than desired.")
                print("Extra distance needed: \(extraDistanceNeeded) meters")
                print("Extra distance per waypoint: \(extraDistancePerWaypoint) meters")

                // Compute the bearing from starting point to finishing point
                let bearing = self.bearingBetweenLocations(
                    startingPoint, finishingPoint)
                print("Bearing from starting point to finishing point: \(bearing) degrees")

                // Compute the midpoint between starting and finishing points
                let midpoint = CLLocationCoordinate2D(
                    latitude: (startingPoint.latitude + finishingPoint.latitude) / 2.0,
                    longitude: (startingPoint.longitude + finishingPoint.longitude) / 2.0
                )

                // Define angle offsets to spread waypoints around the midpoint
                let angleOffsets = [45.0, -45.0, 135.0, -135.0]
                var waypoints = [CLLocationCoordinate2D]()

                for offset in angleOffsets {
                    let adjustedBearing = fmod(bearing + offset + 360.0, 360.0)
                    let waypoint = self.coordinate(
                        from: midpoint,
                        distanceMeters: extraDistancePerWaypoint,
                        bearingDegrees: adjustedBearing)
                    waypoints.append(waypoint)
                    print("Waypoint at bearing \(adjustedBearing): \(waypoint.latitude), \(waypoint.longitude)")
                }

                // Now, compute routes between segments and combine them
                self.calculateSegmentedRoute(
                    startingPoint: startingPoint,
                    waypoints: waypoints,
                    finishingPoint: finishingPoint,
                    transportType: request.transportType
                ) { combinedCoordinates, totalDistance in
                    completion(combinedCoordinates, totalDistance)
                }
            }
        }
    }

    // Method to calculate the segmented route
    private func calculateSegmentedRoute(
        startingPoint: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        finishingPoint: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType,
        completion: @escaping ([CLLocationCoordinate2D]?, Double?) -> Void
    ) {
        var allCoordinates = [CLLocationCoordinate2D]()
        var totalDistance: Double = 0.0

        var previousPoint = startingPoint
        var remainingWaypoints = waypoints

        func calculateNextSegment() {
            if remainingWaypoints.isEmpty {
                // Final segment to the finishing point
                calculateRouteSegment(
                    from: previousPoint,
                    to: finishingPoint,
                    transportType: transportType
                ) { segmentCoordinates, segmentDistance in
                    if let coords = segmentCoordinates, let distance = segmentDistance {
                        allCoordinates.append(contentsOf: coords.dropFirst())
                        totalDistance += distance
                        print("Final segment distance: \(distance) meters")
                        print("Total combined route distance: \(totalDistance) meters")
                        completion(allCoordinates, totalDistance)
                    } else {
                        completion(nil, nil)
                    }
                }
            } else {
                let nextWaypoint = remainingWaypoints.removeFirst()
                calculateRouteSegment(
                    from: previousPoint,
                    to: nextWaypoint,
                    transportType: transportType
                ) { segmentCoordinates, segmentDistance in
                    if let coords = segmentCoordinates, let distance = segmentDistance {
                        allCoordinates.append(contentsOf: coords.dropFirst())
                        totalDistance += distance
                        print("Segment distance: \(distance) meters")
                        previousPoint = nextWaypoint
                        calculateNextSegment()
                    } else {
                        completion(nil, nil)
                    }
                }
            }
        }

        // Start with the first segment
        if let firstWaypoint = remainingWaypoints.first {
            calculateRouteSegment(
                from: startingPoint,
                to: firstWaypoint,
                transportType: transportType
            ) { segmentCoordinates, segmentDistance in
                if let coords = segmentCoordinates, let distance = segmentDistance {
                    allCoordinates.append(contentsOf: coords)
                    totalDistance += distance
                    print("First segment distance: \(distance) meters")
                    previousPoint = firstWaypoint
                    remainingWaypoints.removeFirst()
                    calculateNextSegment()
                } else {
                    completion(nil, nil)
                }
            }
        } else {
            // No waypoints, go directly to finishing point
            calculateRouteSegment(
                from: startingPoint,
                to: finishingPoint,
                transportType: transportType
            ) { segmentCoordinates, segmentDistance in
                if let coords = segmentCoordinates, let distance = segmentDistance {
                    allCoordinates.append(contentsOf: coords)
                    totalDistance += distance
                    print("Route distance: \(distance) meters")
                    completion(allCoordinates, totalDistance)
                } else {
                    completion(nil, nil)
                }
            }
        }
    }

    private func calculateRouteSegment(
        from: CLLocationCoordinate2D,
        to: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType,
        completion: @escaping ([CLLocationCoordinate2D]?, Double?) -> Void
    ) {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: from))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: to))
        request.transportType = transportType

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating segment: \(error.localizedDescription)")
                completion(nil, nil)
                return
            }

            guard let route = response?.routes.first else {
                print("No route found for segment.")
                completion(nil, nil)
                return
            }

            completion(route.polyline.coordinates, route.distance)
        }
    }

    // Helper method to calculate the bearing between two coordinates
    private func bearingBetweenLocations(
        _ coordinate1: CLLocationCoordinate2D,
        _ coordinate2: CLLocationCoordinate2D
    ) -> Double {
        let lat1 = coordinate1.latitude.toRadians()
        let lon1 = coordinate1.longitude.toRadians()

        let lat2 = coordinate2.latitude.toRadians()
        let lon2 = coordinate2.longitude.toRadians()

        let deltaLon = lon2 - lon1

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) -
            sin(lat1) * cos(lat2) * cos(deltaLon)
        let initialBearing = atan2(y, x).toDegrees()
        return (initialBearing + 360.0)
            .truncatingRemainder(dividingBy: 360.0)
    }

    // Helper method to calculate a coordinate given a starting point, distance, and bearing
    private func coordinate(
        from coordinate: CLLocationCoordinate2D,
        distanceMeters: Double,
        bearingDegrees: Double
    ) -> CLLocationCoordinate2D {
        let distanceRadians = distanceMeters / 6371000.0 // Earth's radius in meters
        let bearingRadians = bearingDegrees.toRadians()

        let lat1 = coordinate.latitude.toRadians()
        let lon1 = coordinate.longitude.toRadians()

        let lat2 = asin(sin(lat1) * cos(distanceRadians) +
            cos(lat1) * sin(distanceRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(
            sin(bearingRadians) * sin(distanceRadians) * cos(lat1),
            cos(distanceRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(
            latitude: lat2.toDegrees(),
            longitude: lon2.toDegrees())
    }
}

