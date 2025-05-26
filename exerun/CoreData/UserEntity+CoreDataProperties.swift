//
//  UserEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 1/5/2025.
//
//

import Foundation
import CoreData


extension UserEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserEntity> {
        return NSFetchRequest<UserEntity>(entityName: "UserEntity")
    }

    @NSManaged public var createdAt: Date
    @NSManaged public var email: String
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var profileId: String?
    @NSManaged public var surname: String
    @NSManaged public var isDirty: Bool
}
