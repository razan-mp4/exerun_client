//
//  RouteSimplificationManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 31/8/2024.
//

import Foundation
import CoreLocation

class RouteSimplificationManager {
    // The epsilon value determines the level of simplification (in meters)
    var epsilon: Double

    init(epsilon: Double = 5.0) {
        self.epsilon = epsilon
    }

    // Simplify the segment in place
    func simplifySegmentInPlace(_ segment: inout [CLLocationCoordinate2D]) {
        segment = simplifyRoute(segment)
    }

    private func simplifyRoute(_ points: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        return douglasPeucker(points, epsilon: epsilon)
    }

    private func douglasPeucker(_ points: [CLLocationCoordinate2D], epsilon: Double) -> [CLLocationCoordinate2D] {
        guard points.count > 2 else { return points }
        
        // Find the point with the maximum distance
        var maxDistance: Double = 0.0
        var index: Int = 0
        let end = points.count - 1
        
        for i in 1..<end {
            let distance = perpendicularDistance(point: points[i], lineStart: points[0], lineEnd: points[end])
            if distance > maxDistance {
                index = i
                maxDistance = distance
            }
        }
        
        // If max distance is greater than epsilon, recursively simplify
        if maxDistance > epsilon {
            let recResults1 = douglasPeucker(Array(points[0...index]), epsilon: epsilon)
            let recResults2 = douglasPeucker(Array(points[index...end]), epsilon: epsilon)
            
            // Build the result list
            var result = recResults1
            result.removeLast() // Avoid duplicate point
            result.append(contentsOf: recResults2)
            return result
        } else {
            // Simplify by returning the endpoints
            return [points[0], points[end]]
        }
    }

    private func perpendicularDistance(point: CLLocationCoordinate2D, lineStart: CLLocationCoordinate2D, lineEnd: CLLocationCoordinate2D) -> Double {
        // Convert coordinates to CGPoints for easier calculations
        let x0 = point.longitude
        let y0 = point.latitude
        let x1 = lineStart.longitude
        let y1 = lineStart.latitude
        let x2 = lineEnd.longitude
        let y2 = lineEnd.latitude
        
        let numerator = abs((y2 - y1) * x0 - (x2 - x1) * y0 + x2 * y1 - y2 * x1)
        let denominator = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2))
        let distanceInDegrees = numerator / denominator
        
        // Convert degrees to meters using a rough estimation
        let metersPerDegreeLatitude = 111_000.0
        let metersPerDegreeLongitude = 111_320.0 * cos(y0 * Double.pi / 180)
        let avgMetersPerDegree = (metersPerDegreeLatitude + metersPerDegreeLongitude) / 2.0
        
        return distanceInDegrees * avgMetersPerDegree
    }
}
