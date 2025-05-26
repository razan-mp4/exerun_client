//
//  Timer.swift
//  exerun
//
//  Created by Nazar Odemchuk on 11/1/2024.
//

import Foundation

struct QuickWorkoutModel {
    var isRunWorkout: Bool!
    
    var restMinutes: Int!
    var restSeconds: Int!
    
    var workMinutes: Int!
    var workSeconds: Int!
    
    var totalSets: Int!
    
    
    // Additional properties for tracking sets and current interval
    var currentSet: Int = 0
    var isWorkTime: Bool = true
    
    // Computed property to get total time for current interval in seconds
    var currentIntervalTime: TimeInterval! {
        return isWorkTime ? TimeInterval(workMinutes * 60 + workSeconds) : TimeInterval(restMinutes * 60 + restSeconds)
    }
    
}

// MARK: – Quick workout (rope-jump, Tabata, etc.) --------------------------
extension QuickWorkoutModel: WorkoutSessionConvertible {
    typealias Entity = QuickWorkOutEntity
    func fill(_ e: QuickWorkOutEntity) {
        e.workTime = Int32(workMinutes*60 + workSeconds)
        e.restTime = Int32(restMinutes*60 + restSeconds)
        e.quantity = Int32(totalSets)
    }
}
