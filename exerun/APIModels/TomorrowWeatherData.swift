//
//  TomorrowWeatherData.swift
//  exerun
//
//  Created by Nazar Odemchuk on 20/11/2024.
//

import Foundation


struct TomorrowWeatherData: Codable {
    struct Data: Codable {
        struct Timelines: Codable {
            struct Intervals: Codable {
                struct Values: Codable {
                    let temperature: Double
                    let weatherCode: Int
                    let windSpeed: Double
                    let humidity: Int
                    let visibility: Double
                    let pressureSurfaceLevel: Double
                    let precipitationIntensity: Double
                }
                let startTime: String
                let values: Values
            }
            let timestep: String
            let endTime: String
            let startTime: String
            let intervals: [Intervals]
        }
        let timelines: [Timelines]
    }
    let data: Data
}
