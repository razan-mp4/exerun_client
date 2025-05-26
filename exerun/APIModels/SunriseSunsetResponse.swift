//
//  SunriseSunsetResponse.swift
//  exerun
//
//  Created by Nazar Odemchuk on 20/11/2024.
//

import Foundation


struct SunriseSunsetResponse: Codable {
    struct Results: Codable {
        let sunrise: String
        let sunset: String
    }
    let results: Results
    let status: String
}
