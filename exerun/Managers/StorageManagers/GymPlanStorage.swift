//
//  GymPlanStorage.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

import Foundation
import CoreData
import UIKit


final class GymPlanStorage {
    static let shared = GymPlanStorage()
    private init() {}

    // MARK: - Save structured plan with child entities
    func saveStructured(planName: String, response: GymPlanResponse) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        let ctx = app.persistentContainer.viewContext

        let planEntity = GymPlanEntity(context: ctx)
        planEntity.localUUID = UUID().uuidString
        planEntity.name = planName
        planEntity.createdAt = Date()
        planEntity.updatedAt = Date()
        planEntity.isDirty = true

        for (dayKey, exercises) in response.workout_plan.days {
            guard !exercises.isEmpty, exercises.first?.name != "rest_day" else { continue }

            let dayIndex = Int16(dayKey.components(separatedBy: "_").last.flatMap(Int.init) ?? 0)
            let dayEntity = PlanDayEntity(context: ctx)
            dayEntity.dayIndex = dayIndex
            dayEntity.plan = planEntity

            for ex in exercises {
                let exEntity = PlanExerciseEntity(context: ctx)
                exEntity.name = ex.name
                exEntity.sets = Int16(ex.sets)
                exEntity.reps = Int16(ex.reps)
                exEntity.day = dayEntity
            }
        }

        do {
            try ctx.save()
            print("✅ Structured gym plan saved with \(planEntity.days?.count ?? 0) day(s)")
        } catch {
            print("❌ Failed to save gym plan:", error)
        }
    }

    // MARK: - Fetch all plans
    func fetchAllPlans() -> [GymPlanEntity] {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return [] }
        let ctx = app.persistentContainer.viewContext

        let req: NSFetchRequest<GymPlanEntity> = GymPlanEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try ctx.fetch(req)
        } catch {
            print("❌ Fetch failed:", error)
            return []
        }
    }

    // MARK: - Delete plan
    func deletePlan(_ plan: GymPlanEntity) {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return }
        let ctx = app.persistentContainer.viewContext

        ctx.delete(plan)
        do {
            try ctx.save()
            print("🗑️ Plan deleted: \(plan.name ?? "Unnamed")")
        } catch {
            print("❌ Failed to delete plan:", error)
        }
    }

    // MARK: - Fetch plan by ID
    func fetch(by id: String) -> GymPlanEntity? {
        guard let app = UIApplication.shared.delegate as? AppDelegate else { return nil }
        let ctx = app.persistentContainer.viewContext

        let req: NSFetchRequest<GymPlanEntity> = GymPlanEntity.fetchRequest()
        req.predicate = NSPredicate(format: "localUUID == %@", id)
        req.fetchLimit = 1

        return try? ctx.fetch(req).first
    }

    // MARK: - Debug: Decode plan into console
    func printPlanStructure(_ entity: GymPlanEntity) {
        print("🏋️ Plan: \(entity.name ?? "Unnamed")")
        if let days = entity.days as? Set<PlanDayEntity> {
            for day in days.sorted(by: { $0.dayIndex < $1.dayIndex }) {
                print("  📅 Day \(day.dayIndex)")
                if let exercises = day.exercises as? Set<PlanExerciseEntity> {
                    for ex in exercises.sorted(by: { $0.name ?? "" < $1.name ?? "" }) {
                        print("     – \(ex.name ?? "unknown"): \(ex.sets) × \(ex.reps)")
                    }
                }
            }
        }
    }
}
