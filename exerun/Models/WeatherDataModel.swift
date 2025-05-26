//
//  WeatherDataModel.swift
//  exerun
//
//  Created by Nazar Odemchuk on 20/11/2024.
//

import Foundation


struct WeatherDataModel {
    let temperature: Double?
    let humidity: Int?
    let visibility: Double?
    let windSpeed: Double?
    let pressure: Double?
    let precipitation: Double?
    let weatherCode: Int?
    let isDayTime: Bool
    let sunSet: String?
    let sunRise: String?
}
