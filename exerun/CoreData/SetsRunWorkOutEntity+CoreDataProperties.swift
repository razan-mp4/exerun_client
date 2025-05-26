//
//  SetsRunWorkOutEntity+CoreDataProperties.swift
//  
//
//  Created by Nazar Odemchuk on 1/5/2025.
//
//

import Foundation
import CoreData


extension SetsRunWorkOutEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SetsRunWorkOutEntity> {
        return NSFetchRequest<SetsRunWorkOutEntity>(entityName: "SetsRunWorkOutEntity")
    }

    @NSManaged public var avarageHeartRate: Int32
    @NSManaged public var avgPace: String?
    @NSManaged public var avgSpeed: Double
    @NSManaged public var distance: Double
    @NSManaged public var elevationGain: Int32
    @NSManaged public var maxHeartRate: Int32
    @NSManaged public var maxSpeed: Double
    @NSManaged public var quantity: Int32
    @NSManaged public var restTime: Int32
    @NSManaged public var segments: Data?
    @NSManaged public var workTime: Int32

}


extension SetsRunWorkOutEntity : HasSegments, HasImageData {}
