//
//  ProfileStorage.swift
//  exerun
//
//  Created by Nazar Odemchuk on 22/4/2025.
//

import Foundation
import UIKit
import CoreData

final class ProfileStorage {
    static let shared = ProfileStorage()
    private init() {}

    
    func save(_ profile: ProfileResponse) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let entity = ProfileEntity(context: context)
        entity.id = profile.id
        entity.userId = profile.user_id
        entity.height = Double(profile.height ?? 0)
        entity.gender = profile.gender
        if let birthdayStr = profile.birthday {
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = TimeZone(secondsFromGMT: 0)
            entity.birthday = df.date(from: birthdayStr)
        }

        entity.updatedAt = ISO8601DateFormatter().date(from: profile.updated_at ?? "")
        entity.isDirty   = false
        
        // 👇 This line gets the most recent weight entry if any
        if let latestWeight = profile.weight?.last?.value {
            entity.weight = latestWeight
        }

        do {
            try context.save()
            print("✅ Profile saved")
        } catch {
            print("❌ Profile save error:", error)
        }
    }
    
    func save(entity: ProfileEntity) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        do {
            try context.save()
            print("✅ Updated existing ProfileEntity saved")
        } catch {
            print("❌ Failed saving updated ProfileEntity:", error)
        }
    }

    
    func getProfile() -> ProfileEntity? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest = NSFetchRequest<ProfileEntity>(entityName: "ProfileEntity")
        fetchRequest.fetchLimit = 1

        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("❌ Failed to fetch profile:", error)
            return nil
        }
    }

    
    func saveProfileImage(_ imageData: Data) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()

        do {
            if let profile = try context.fetch(fetchRequest).first {
                profile.imageData = imageData
                profile.isDirty   = true
                try context.save()
                AccountSyncManager.shared.kick()
                print("✅ Saved profile image locally")
            }
        } catch {
            print("❌ Failed saving profile image:", error)
        }
    }

    func updateProfilePictureURL(_ url: String) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()

        do {
            if let profile = try context.fetch(fetchRequest).first {
                profile.profilePictureURL = url
                profile.isDirty   = true
                try context.save()
                AccountSyncManager.shared.kick()
                print("✅ Updated profile picture URL")
            }
        } catch {
            print("❌ Failed updating profile URL:", error)
        }
    }

}


struct ProfileInput {
    var height: Int?
    var weight: Int?
    var birthday: Date?
    var gender: String?

    var isComplete: Bool {
        height != nil && weight != nil && birthday != nil && gender != nil
    }
}


extension ProfileStorage {

    func updateProfile(with input: ProfileInput) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<ProfileEntity> = ProfileEntity.fetchRequest()

        do {
            let entity = try context.fetch(fetchRequest).first ?? ProfileEntity(context: context)
            if let height = input.height { entity.height = Double(height) }
            if let weight = input.weight { entity.weight = Double(weight) }
            entity.gender = input.gender
            entity.birthday = input.birthday
            entity.isDirty = true

            try context.save()
            AccountSyncManager.shared.kick()
            print("✅ Profile updated")
        } catch {
            print("❌ Failed to update profile:", error)
        }
    }
}
