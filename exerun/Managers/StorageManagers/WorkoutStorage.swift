//
//  WorkoutStorage.swift
//  exerun
//
//  Created by Nazar Odemchuk on 1/5/2025.
//


import UIKit
import CoreData
import MapKit

// ──────────────────────────────────────────────────────────────
// MARK: –  Optional capabilities (class-bound protocols)
// ──────────────────────────────────────────────────────────────

/// Adopt if the entity owns the *segments* BLOB (route poly-line).
@objc protocol HasSegments : AnyObject {
    var segments: Data? { get set }
}

/// Adopt if the entity can store a picture.
@objc protocol HasImageData : AnyObject {
    var imageData: Data? { get set }
}

// ──────────────────────────────────────────────────────────────
// MARK: –  Session-model → entity bridge
// ──────────────────────────────────────────────────────────────

/// Every “SessionModel” that can be persisted implements this.
protocol WorkoutSessionConvertible {
    associatedtype Entity : BaseWorkOutEntity          // concrete CD class
    func fill(_ entity: Entity)                        // copy sport-specific stats
}

// ──────────────────────────────────────────────────────────────
// MARK: –  Storage manager
// ──────────────────────────────────────────────────────────────

final class WorkoutStorage {

    static let shared = WorkoutStorage()
    private init() {}

    private var container: NSPersistentContainer {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    /// Persist a finished workout **synchronously** on a private queue.
    /// - Returns: `true` when the save succeeded.
    /// Persist a finished workout.
    /// - Parameters:
    ///   - kind:     "run","cycling","hike",…  (written to `type`)
    @discardableResult
    func save<S: WorkoutSessionConvertible>(
        workoutKind:     String,
        name:     String?,
        session:  S,
        segments: [[CLLocationCoordinate2D]]? = nil,
        picture:  UIImage?                     = nil
    ) -> Bool {

        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        var ok = false

        ctx.performAndWait {

            // --------------------------------------------------------------
            // 1. Dynamically create the concrete managed object
            //    (cannot call `S.Entity(context:)` directly on a generic).
            // --------------------------------------------------------------
            guard
                let entityName = S.Entity.entity().name,
                let workout = NSEntityDescription.insertNewObject(
                                forEntityName: entityName, into: ctx) as? S.Entity
            else {
                print("❌ Could not create instance of \(S.Entity.self)")
                return
            }

            // --------------------------------------------------------------
            // 2. Generic columns (defined in BaseWorkOutEntity)
            // --------------------------------------------------------------
            workout.name      = name?.isEmpty == false ? name! : "Workout"
            workout.date      = Date()
            workout.updatedAt = Date()
            workout.isDirty   = true           // mark for later upload
            workout.type      = workoutKind
            workout.localUUID = UUID().uuidString
            // --------------------------------------------------------------
            // 3. Sport-specific statistics
            // --------------------------------------------------------------
            session.fill(workout)

            // --------------------------------------------------------------
            // 4. Optional extras – only if the entity actually owns them
            // --------------------------------------------------------------
            if let segs = segments, let w = workout as? HasSegments {
                w.segments = Self.encodeSegments(segs)
            }
            if let img  = picture , let w = workout as? HasImageData {
                w.imageData = img.jpegData(compressionQuality: 0.8)
            }

            // --------------------------------------------------------------
            // 5. Persist
            // --------------------------------------------------------------
            do {
                try ctx.save()
                ok = true
                print("✅ Saved \(entityName)")
                // NEW — tell the world that a new workout exists
                NotificationCenter.default.post(name: .workoutDidSave, object: workout)

                // NEW — start/continue background upload
                if ok {
                    WorkoutSyncManager.shared.kick()  // ✅ now called after save exits
                }
            } catch {
                ctx.rollback()
                print("❌ Core-Data save error:", error)
            }
        }
        return ok
    }

    // Helper: archive an array of poly-lines
    private static func encodeSegments(
        _ segs: [[CLLocationCoordinate2D]]
    ) -> Data? {
        let arr = segs.map { $0.map { ["latitude": $0.latitude,
                                       "longitude": $0.longitude] } }
        return try? NSKeyedArchiver.archivedData(withRootObject: arr,
                                                 requiringSecureCoding: false)
    }
}

extension Notification.Name {
    static let workoutDidSave = Notification.Name("workoutDidSave")
}
