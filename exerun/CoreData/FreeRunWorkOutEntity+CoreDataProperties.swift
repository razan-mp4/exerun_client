//
//  FreeRunWorkOutEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 1/5/2025.
//
//

import Foundation
import CoreData


extension FreeRunWorkOutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FreeRunWorkOutEntity> {
        return NSFetchRequest<FreeRunWorkOutEntity>(entityName: "FreeRunWorkOutEntity")
    }

    @NSManaged public var avarageHeartRate: Int32
    @NSManaged public var avgPace: String?
    @NSManaged public var avgSpeed: Double
    @NSManaged public var distance: Double
    @NSManaged public var elevationGain: Int32
    @NSManaged public var maxHeartRate: Int32
    @NSManaged public var maxSpeed: Double
    @NSManaged public var segments: Data?

}

extension FreeRunWorkOutEntity : HasSegments, HasImageData {}
