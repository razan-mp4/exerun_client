//
//  PlanDayEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 6/5/2025.
//
//

import Foundation
import CoreData


extension PlanDayEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlanDayEntity> {
        return NSFetchRequest<PlanDayEntity>(entityName: "PlanDayEntity")
    }

    @NSManaged public var dayIndex: Int16
    @NSManaged public var exercises: NSSet?
    @NSManaged public var plan: GymPlanEntity?

}

// MARK: Generated accessors for exercises
extension PlanDayEntity {

    @objc(addExercisesObject:)
    @NSManaged public func addToExercises(_ value: PlanExerciseEntity)

    @objc(removeExercisesObject:)
    @NSManaged public func removeFromExercises(_ value: PlanExerciseEntity)

    @objc(addExercises:)
    @NSManaged public func addToExercises(_ values: NSSet)

    @objc(removeExercises:)
    @NSManaged public func removeFromExercises(_ values: NSSet)

}
