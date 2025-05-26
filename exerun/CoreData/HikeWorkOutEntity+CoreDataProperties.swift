//
//  HikeWorkOutEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 1/5/2025.
//
//

import Foundation
import CoreData


extension HikeWorkOutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<HikeWorkOutEntity> {
        return NSFetchRequest<HikeWorkOutEntity>(entityName: "HikeWorkOutEntity")
    }

    @NSManaged public var avarageHeartRate: Int32
    @NSManaged public var avgPace: String?
    @NSManaged public var avgSpeed: Double
    @NSManaged public var distance: Double
    @NSManaged public var elevationGain: Int32
    @NSManaged public var maxElevation: Double
    @NSManaged public var maxHeartRate: Int32
    @NSManaged public var maxSpeed: Double
    @NSManaged public var minElevation: Double
    @NSManaged public var segments: Data?

}

extension HikeWorkOutEntity : HasSegments, HasImageData {}
