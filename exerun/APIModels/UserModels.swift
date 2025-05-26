//
//  UserModels.swift
//  exerun
//
//  Created by Nazar Odemchuk on 21/4/2025.
//

import Foundation

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let surname: String
    let created_at: Date
    let profile_id: String?
}
