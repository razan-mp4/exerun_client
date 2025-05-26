//
//  RouteModels.swift
//  exerun
//
//  Created by Nazar Odemchuk on 14/4/2025.
//

import Foundation
import CoreLocation

struct Coordinate: Codable {
    let latitude: Double
    let longitude: Double
}

struct RouteRequest: Codable {
    let startingPoint: Coordinate
    let finishingPoint: Coordinate
    let distance: Int
}

struct RouteResponse: Codable {
    let route: [Coordinate]
    let distance_m: Double
}
