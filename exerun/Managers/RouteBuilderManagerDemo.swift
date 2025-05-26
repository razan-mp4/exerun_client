//
//  RouteBuilderManagerTest.swift
//  exerun
//
//  Created by Nazar Odemchuk on 26/11/2024.
//

import CoreLocation
import MapKit

class RouteBuilderManagerDemo {
    func generateRoute(startingPoint: CLLocationCoordinate2D, finishingPoint: CLLocationCoordinate2D, distance: Int, completion: @escaping ([CLLocationCoordinate2D]?, Double?) -> Void) {
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: startingPoint)
        let destinationPlacemark = MKPlacemark(coordinate: finishingPoint)
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .walking 

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
            let desiredDistance = Double(distance) * 1000.0 // Convert km to meters

            print("Initial route distance: \(routeDistance) meters")
            print("Desired distance: \(desiredDistance) meters")

            if routeDistance >= desiredDistance {
                print("Generated route is long enough, returning route.")
                let routeCoordinates = route.polyline.coordinates
                completion(routeCoordinates, routeDistance)
            } else {
                // Need to add waypoints and recalculate the route
                let extraDistanceNeeded = desiredDistance - routeDistance
                let extraDistancePerWaypoint = (extraDistanceNeeded / 2.0) / 1.4

                print("Route is shorter than desired.")
                print("Extra distance needed: \(extraDistanceNeeded) meters")
                print("Extra distance per waypoint: \(extraDistancePerWaypoint) meters")

                // Compute the bearing from starting point to finishing point
                let bearing = self.bearingBetweenLocations(startingPoint, finishingPoint)
                print("Bearing from starting point to finishing point: \(bearing) degrees")

                // Compute perpendicular bearing (90 degrees offset)
                let perpendicularBearing = fmod(bearing + 90.0, 360.0)
                print("Perpendicular bearing: \(perpendicularBearing) degrees")

                // Calculate waypoints
                let nearStartingWayPoint = self.coordinate(from: startingPoint, distanceMeters: extraDistancePerWaypoint, bearingDegrees: perpendicularBearing)
                let nearFinishingWayPoint = self.coordinate(from: finishingPoint, distanceMeters: extraDistancePerWaypoint, bearingDegrees: perpendicularBearing)
                print("Near starting waypoint: \(nearStartingWayPoint.latitude), \(nearStartingWayPoint.longitude)")
                print("Near finishing waypoint: \(nearFinishingWayPoint.latitude), \(nearFinishingWayPoint.longitude)")

                // Now, compute routes between segments and combine them
                self.calculateSegmentedRoute(startingPoint: startingPoint, nearStartingWayPoint: nearStartingWayPoint, nearFinishingWayPoint: nearFinishingWayPoint, finishingPoint: finishingPoint, transportType: request.transportType) { combinedCoordinates, totalDistance in
                    completion(combinedCoordinates, totalDistance)
                }
            }
        }
    }

    // Method to calculate the segmented route
    private func calculateSegmentedRoute(startingPoint: CLLocationCoordinate2D, nearStartingWayPoint: CLLocationCoordinate2D, nearFinishingWayPoint: CLLocationCoordinate2D, finishingPoint: CLLocationCoordinate2D, transportType: MKDirectionsTransportType, completion: @escaping ([CLLocationCoordinate2D]?, Double?) -> Void) {
        // First segment: Starting Point -> nearStartingWayPoint
        let request1 = MKDirections.Request()
        request1.source = MKMapItem(placemark: MKPlacemark(coordinate: startingPoint))
        request1.destination = MKMapItem(placemark: MKPlacemark(coordinate: nearStartingWayPoint))
        request1.transportType = transportType

        let directions1 = MKDirections(request: request1)
        directions1.calculate { response1, error1 in
            if let error1 = error1 {
                print("Error calculating first segment: \(error1.localizedDescription)")
                completion(nil, nil)
                return
            }

            guard let route1 = response1?.routes.first else {
                print("No route found for first segment.")
                completion(nil, nil)
                return
            }

            print("First segment distance: \(route1.distance) meters")

            // Second segment: nearStartingWayPoint -> nearFinishingWayPoint
            let request2 = MKDirections.Request()
            request2.source = MKMapItem(placemark: MKPlacemark(coordinate: nearStartingWayPoint))
            request2.destination = MKMapItem(placemark: MKPlacemark(coordinate: nearFinishingWayPoint))
            request2.transportType = transportType

            let directions2 = MKDirections(request: request2)
            directions2.calculate { response2, error2 in
                if let error2 = error2 {
                    print("Error calculating second segment: \(error2.localizedDescription)")
                    completion(nil, nil)
                    return
                }

                guard let route2 = response2?.routes.first else {
                    print("No route found for second segment.")
                    completion(nil, nil)
                    return
                }

                print("Second segment distance: \(route2.distance) meters")

                // Third segment: nearFinishingWayPoint -> Finishing Point
                let request3 = MKDirections.Request()
                request3.source = MKMapItem(placemark: MKPlacemark(coordinate: nearFinishingWayPoint))
                request3.destination = MKMapItem(placemark: MKPlacemark(coordinate: finishingPoint))
                request3.transportType = transportType

                let directions3 = MKDirections(request: request3)
                directions3.calculate { response3, error3 in
                    if let error3 = error3 {
                        print("Error calculating third segment: \(error3.localizedDescription)")
                        completion(nil, nil)
                        return
                    }

                    guard let route3 = response3?.routes.first else {
                        print("No route found for third segment.")
                        completion(nil, nil)
                        return
                    }

                    print("Third segment distance: \(route3.distance) meters")

                    // Combine coordinates
                    var combinedCoordinates = [CLLocationCoordinate2D]()
                    combinedCoordinates.append(contentsOf: route1.polyline.coordinates)
                    combinedCoordinates.append(contentsOf: route2.polyline.coordinates.dropFirst())
                    combinedCoordinates.append(contentsOf: route3.polyline.coordinates.dropFirst())

                    // Calculate total distance
                    let totalDistance = route1.distance + route2.distance + route3.distance
                    print("Total combined route distance: \(totalDistance) meters")

                    completion(combinedCoordinates, totalDistance)
                }
            }
        }
    }

    // Helper method to calculate the bearing between two coordinates
    private func bearingBetweenLocations(_ coordinate1: CLLocationCoordinate2D, _ coordinate2: CLLocationCoordinate2D) -> Double {
        let lat1 = coordinate1.latitude.toRadians()
        let lon1 = coordinate1.longitude.toRadians()

        let lat2 = coordinate2.latitude.toRadians()
        let lon2 = coordinate2.longitude.toRadians()

        let deltaLon = lon2 - lon1

        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        let initialBearing = atan2(y, x).toDegrees()
        return (initialBearing + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    // Helper method to calculate a coordinate given a starting point, distance, and bearing
    private func coordinate(from coordinate: CLLocationCoordinate2D, distanceMeters: Double, bearingDegrees: Double) -> CLLocationCoordinate2D {
        let distanceRadians = distanceMeters / 6371000.0 // Earth's radius in meters
        let bearingRadians = bearingDegrees.toRadians()

        let lat1 = coordinate.latitude.toRadians()
        let lon1 = coordinate.longitude.toRadians()

        let lat2 = asin(sin(lat1) * cos(distanceRadians) + cos(lat1) * sin(distanceRadians) * cos(bearingRadians))
        let lon2 = lon1 + atan2(sin(bearingRadians) * sin(distanceRadians) * cos(lat1), cos(distanceRadians) - sin(lat1) * sin(lat2))

        return CLLocationCoordinate2D(latitude: lat2.toDegrees(), longitude: lon2.toDegrees())
    }
}

// Extensions for degree-radian conversions
extension Double {
    func toRadians() -> Double {
        return self * .pi / 180.0
    }

    func toDegrees() -> Double {
        return self * 180.0 / .pi
    }
}

// Extension to extract coordinates from MKPolyline
extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: self.pointCount)
        self.getCoordinates(&coords, range: NSRange(location: 0, length: self.pointCount))
        return coords
    }
}
