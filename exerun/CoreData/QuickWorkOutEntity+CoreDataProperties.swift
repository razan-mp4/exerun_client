//
//  QuickWorkOutEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 1/5/2025.
//
//

import Foundation
import CoreData


extension QuickWorkOutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<QuickWorkOutEntity> {
        return NSFetchRequest<QuickWorkOutEntity>(entityName: "QuickWorkOutEntity")
    }

    @NSManaged public var quantity: Int32
    @NSManaged public var restTime: Int32
    @NSManaged public var workTime: Int32

}


extension QuickWorkOutEntity : HasImageData {}
