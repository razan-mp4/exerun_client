//
//  ProfileEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 1/5/2025.
//
//

import Foundation
import CoreData


extension ProfileEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ProfileEntity> {
        return NSFetchRequest<ProfileEntity>(entityName: "ProfileEntity")
    }

    @NSManaged public var birthday: Date?
    @NSManaged public var gender: String?
    @NSManaged public var height: Double
    @NSManaged public var id: String?
    @NSManaged public var imageData: Data?
    @NSManaged public var profilePictureURL: String?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var userId: String?
    @NSManaged public var weight: Double
    @NSManaged public var isDirty: Bool
}
