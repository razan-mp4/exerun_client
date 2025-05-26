//
//  PlanExerciseEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 6/5/2025.
//
//

import Foundation
import CoreData


extension PlanExerciseEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PlanExerciseEntity> {
        return NSFetchRequest<PlanExerciseEntity>(entityName: "PlanExerciseEntity")
    }

    @NSManaged public var name: String?
    @NSManaged public var sets: Int16
    @NSManaged public var reps: Int16
    @NSManaged public var day: PlanDayEntity?

}
