//
//  GymPlanModels.swift
//  exerun
//
//  Created by Nazar Odemchuk on 6/5/2025.
//

struct GymPlanRequest: Encodable {
    let height: Int
    let weight: Int
    let age: Int
    let gender: String     // "male", "female"
    let goal: String       // "gain_weight", "loose_weight", "keep_form"
    let working_days: Int
}

struct Exercise: Decodable {
    let name: String
    let sets: Int
    let reps: Int
}

struct WorkoutPlan: Decodable {
    let working_days: Int
    let days: [String: [Exercise]]
}

struct GymPlanResponse: Decodable {
    let workout_plan: WorkoutPlan
}
