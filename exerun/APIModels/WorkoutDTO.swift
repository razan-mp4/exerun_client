//
//  WorkoutDTO.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import Foundation
import CoreLocation

struct LatLon: Codable {
    let lat: Double
    let lon: Double
}

struct WorkoutUpload: Codable {
    let localUUID   : String
    let type        : String
    let name        : String
    let date        : Date
    let duration_s  : Int
    let distance_km : Double
    let stats       : [String:CodableValue]?
    let segments : [[LatLon]]?          // optional
    
    enum CodingKeys: String, CodingKey {
        case localUUID   = "local_uuid"   // <- JSON snake_case
        case type, name, date
        case duration_s, distance_km, stats, segments
    }
}



/// Mirrors the JSON your `/workouts/me` route returns
/// Client-side mirror of WorkoutOut (server)
struct WorkoutResponse: Decodable {
    let remoteID   : String
    let localUUID   : String
    let type       : String
    let name       : String
    let date       : Date              // ⬅︎ make it Date
    let durationS  : Int
    let distanceKm : Double
    let stats      : [String:CodableValue]?
    let segments   : [[LatLon]]?     // or whatever you defined
    let imageURL   : String?
    let updatedAt  : Date

    enum CodingKeys: String, CodingKey {
        case remoteID   = "remote_id"
        case localUUID  = "local_uuid"
        case type, name, date
        case durationS  = "duration_s"
        case distanceKm = "distance_km"
        case stats, segments
        case imageURL   = "image_url"
        case updatedAt  = "updated_at"
    }
}

struct WorkoutCreateResponse: Decodable {
    let remote_id  : String
    let local_uuid : String
}


/// because stats is heterogenous
enum CodableValue: Codable {
    case int(Int), dbl(Double), str(String)

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self)      { self = .int(i)
        } else if let d = try? c.decode(Double.self) { self = .dbl(d)
        } else { self = .str(try c.decode(String.self)) }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .int(let v): try c.encode(v)
        case .dbl(let v): try c.encode(v)
        case .str(let v): try c.encode(v)
        }
    }
}
