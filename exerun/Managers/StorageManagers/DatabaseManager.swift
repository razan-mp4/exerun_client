//
//  DatabaseManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 29/4/2025.
//

import CoreData
import UIKit

final class DatabaseManager {
    static let shared = DatabaseManager()
    private init() {}

    /// Clears all entities from Core Data
    func clearAllData() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext

        let persistentStoreCoordinator = context.persistentStoreCoordinator
        guard let entities = persistentStoreCoordinator?.managedObjectModel.entities else { return }

        do {
            for entity in entities {
                guard let name = entity.name else { continue }
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: name)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(batchDeleteRequest)
            }
            try context.save()
            print("🗑️ Cleared all CoreData entities successfully")
        } catch {
            print("❌ Failed to clear CoreData:", error)
        }
    }
}
