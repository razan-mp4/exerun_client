//
//  UserStorage.swift
//  exerun
//
//  Created by Nazar Odemchuk on 21/4/2025.
//

import Foundation
import UIKit
import CoreData

final class UserStorage {
    static let shared = UserStorage()
    private init() {}
    
    /// Case 1 ▸ server-authoritative copy  ➜ isDirty = false
    func save(_ user: User) {
        DispatchQueue.main.async {
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext

            let entity = UserEntity(context: context)
            entity.id = user.id
            entity.email = user.email
            entity.name = user.name
            entity.surname = user.surname
            entity.createdAt = user.created_at
            entity.profileId = user.profile_id
            entity.isDirty = false
            do {
                try context.save()
                print("✅ User saved")
            } catch {
                print("❌ Save error:", error)
            }
        }
    }

    /// Case 2 ▸ local modification ➜ isDirty = true + start sync
        func save(entity: UserEntity) {
            guard let ctx = context else { return }
            entity.isDirty = true                     // ⬅︎ dirty
            commit(ctx)
            AccountSyncManager.shared.kick()          // fire-and-forget
        }

        // MARK: – Private helpers
        private var context: NSManagedObjectContext? {
            (UIApplication.shared.delegate as? AppDelegate)?
                .persistentContainer.viewContext
        }

        private func commit(_ ctx: NSManagedObjectContext) {
            do {
                try ctx.save()
                print("✅ User entity stored (dirty: \((ctx.insertedObjects.first as? UserEntity)?.isDirty ?? false))")
            } catch {
                print("❌ Core-Data save error:", error)
            }
        }
    
    func getUser() -> UserEntity? {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let context = appDelegate.persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()

        do {
            let users = try context.fetch(fetchRequest)
            return users.first
        } catch {
            print("❌ Fetch error:", error)
            return nil
        }
    }

}
