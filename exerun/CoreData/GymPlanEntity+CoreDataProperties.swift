//
//  GymPlanEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 6/5/2025.
//
//

import Foundation
import CoreData


extension GymPlanEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<GymPlanEntity> {
        return NSFetchRequest<GymPlanEntity>(entityName: "GymPlanEntity")
    }

    @NSManaged public var localUUID: String?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var isDirty: Bool
    @NSManaged public var days: NSSet?

}

// MARK: Generated accessors for days
extension GymPlanEntity {

    @objc(addDaysObject:)
    @NSManaged public func addToDays(_ value: PlanDayEntity)

    @objc(removeDaysObject:)
    @NSManaged public func removeFromDays(_ value: PlanDayEntity)

    @objc(addDays:)
    @NSManaged public func addToDays(_ values: NSSet)

    @objc(removeDays:)
    @NSManaged public func removeFromDays(_ values: NSSet)

}
