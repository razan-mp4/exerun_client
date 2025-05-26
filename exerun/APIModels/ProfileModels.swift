//
//  ProfileModels.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//


import Foundation

struct WeightEntry: Codable {
    let date: String  // "yyyy-MM-dd"
    let value: Double
}

struct ProfileUpdateRequest: Encodable {
    let height: Int?
    let weight: [WeightEntry]?
    let birthday: String?
    let gender: String?
    let profile_picture_url: String?
}

struct ProfileResponse: Decodable {
    let id: String
    let user_id: String
    let height: Int?
    let weight: [WeightEntry]?
    let birthday: String?
    let gender: String?
    let updated_at: String?
    let profile_picture_url: String?
}
