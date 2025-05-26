//
//  GymPlanSyncManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 7/5/2025.
//

import CoreData
import UIKit
import Network

final class GymPlanSyncManager {

    static let shared = GymPlanSyncManager()
    private init() { startReachability() }

    private var container: NSPersistentContainer {
        (UIApplication.shared.delegate as! AppDelegate).persistentContainer
    }

    // MARK: - Sync Trigger
    func kick() {
        DispatchQueue.global(qos: .background).async { self.run() }
    }

    private func run() {
        guard KeychainManager.shared.loadToken() != nil else { return }

        let ctx = container.newBackgroundContext()
        let rq = NSFetchRequest<GymPlanEntity>(entityName: "GymPlanEntity")
        rq.predicate = NSPredicate(format: "isDirty == YES")
        rq.fetchLimit = 1

        guard let plan = try? ctx.fetch(rq).first else { return }

        sync(plan, ctx: ctx)
    }

    private func sync(_ plan: GymPlanEntity, ctx: NSManagedObjectContext) {
        guard let payload = GymPlanUploader.json(from: plan) else { return }

        ExerunServerAPIManager.shared.uploadGymPlan(payload) { result in
            switch result {
            case .success:
                ctx.performAndWait {
                    plan.isDirty = false
                    try? ctx.save()
                }
                self.broadcast()

            case .failure(let err):
                print("❌ Gym plan sync failed:", err)
            }
        }
    }

    // MARK: - Pull
    func pull() {
        ExerunServerAPIManager.shared.fetchGymPlans { result in
            switch result {
            case .success(let remotePlans):
                let ctx = self.container.newBackgroundContext()
                ctx.perform {
                    for remote in remotePlans {
                        let fetch = NSFetchRequest<GymPlanEntity>(entityName: "GymPlanEntity")
                        fetch.predicate = NSPredicate(format: "localUUID == %@", remote.plan_id)

                        let local = (try? ctx.fetch(fetch))?.first

                        if local == nil {
                            let new = GymPlanEntity(context: ctx)
                            new.localUUID = remote.plan_id
                            new.name = remote.name
                            new.updatedAt = remote.updated_at
                            new.isDirty = false

                            for day in remote.days {
                                let dayEntity = PlanDayEntity(context: ctx)
                                dayEntity.dayIndex = Int16(day.index)
                                dayEntity.plan = new

                                for ex in day.exercises {
                                    let exEntity = PlanExerciseEntity(context: ctx)
                                    exEntity.name = ex.name
                                    exEntity.sets = Int16(ex.sets)
                                    exEntity.reps = Int16(ex.reps)
                                    exEntity.day = dayEntity
                                }
                            }
                        }
                    }

                    // ✅ Save and mark pull complete
                    try? ctx.save()
                    UserDefaults.standard.set(true, forKey: "gymplans.pull.done")
                    self.broadcast()
                }

            case .failure(let err):
                print("❌ Failed to pull gym plans:", err)
            }
        }
    }

    // MARK: - Reachability
    private let monitor = NWPathMonitor()

    private func startReachability() {
        monitor.pathUpdateHandler = { [weak self] path in
            if path.status == .satisfied {
                self?.kick()
            }
        }
        monitor.start(queue: .init(label: "net.exerun.gymplan.reachability"))
    }

    // MARK: - Broadcast
    private func broadcast() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .syncStateChanged, object: nil)
        }
    }
}

// MARK: - JSON Uploader
enum GymPlanUploader {

    struct UploadableGymPlan: Codable {
        let plan_id: String
        let name: String?
        let days: [UploadableDay]
        let updated_at: Date
    }

    struct UploadableDay: Codable {
        let index: Int
        let exercises: [UploadableExercise]
    }

    struct UploadableExercise: Codable {
        let name: String
        let sets: Int
        let reps: Int
    }

    static func json(from plan: GymPlanEntity) -> UploadableGymPlan? {
        guard let uuid = plan.localUUID,
              let daysSet = plan.days as? Set<PlanDayEntity> else { return nil }

        let dayList = daysSet.map { day in
            UploadableDay(
                index: Int(day.dayIndex),
                exercises: (day.exercises as? Set<PlanExerciseEntity>)?.map {
                    UploadableExercise(
                        name: $0.name ?? "",
                        sets: Int($0.sets),
                        reps: Int($0.reps)
                    )
                } ?? []
            )
        }

        return UploadableGymPlan(
            plan_id: uuid,
            name: plan.name,
            days: dayList,
            updated_at: plan.updatedAt ?? Date()
        )
    }
}

// MARK: - Sync Status Helpers
extension GymPlanSyncManager {

    var hasUnsyncedGymPlans: Bool {
        let ctx = container.viewContext
        let rq = NSFetchRequest<NSFetchRequestResult>(entityName: "GymPlanEntity")
        rq.predicate = NSPredicate(format: "isDirty == YES")
        rq.fetchLimit = 1

        do {
            return try ctx.count(for: rq) > 0
        } catch {
            print("⚠️ Failed to check unsynced gym plans:", error)
            return false
        }
    }

    var isPullComplete: Bool {
        UserDefaults.standard.bool(forKey: "gymplans.pull.done")
    }

    func resetPullState() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: "gymplans.pull.done")
    }
}
