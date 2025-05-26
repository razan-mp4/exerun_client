//
//  BaseWorkOutEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 5/5/2025.
//
//

import Foundation
import CoreData


extension BaseWorkOutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BaseWorkOutEntity> {
        return NSFetchRequest<BaseWorkOutEntity>(entityName: "BaseWorkOutEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var imageData: Data?
    @NSManaged public var imageURL: String?
    @NSManaged public var isDirty: Bool
    @NSManaged public var name: String?
    @NSManaged public var remoteID: String?
    @NSManaged public var type: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var localUUID: String

}
