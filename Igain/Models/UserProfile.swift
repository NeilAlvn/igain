//
//  UserProfile.swift
//  Igain
//

import Foundation
import SwiftData

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male
    case female

    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary
    case light
    case moderate
    case active
    case veryActive

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sedentary: "Sedentary"
        case .light: "Lightly Active"
        case .moderate: "Moderately Active"
        case .active: "Very Active"
        case .veryActive: "Extremely Active"
        }
    }

    var detail: String {
        switch self {
        case .sedentary: "Little or no exercise, desk job"
        case .light: "Exercise 1–3 days a week"
        case .moderate: "Exercise 3–5 days a week"
        case .active: "Exercise 6–7 days a week"
        case .veryActive: "Hard training or physical job"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .active: 1.725
        case .veryActive: 1.9
        }
    }
}

enum WeightGoal: String, Codable, CaseIterable, Identifiable {
    case lose
    case maintain
    case gain

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .lose: "Lose Weight"
        case .maintain: "Maintain Weight"
        case .gain: "Gain Weight"
        }
    }

    var systemImage: String {
        switch self {
        case .lose: "arrow.down.circle.fill"
        case .maintain: "equal.circle.fill"
        case .gain: "arrow.up.circle.fill"
        }
    }

    /// Daily calorie adjustment applied to TDEE (roughly ±0.5 kg per week).
    var calorieAdjustment: Double {
        switch self {
        case .lose: -500
        case .maintain: 0
        case .gain: 500
        }
    }
}

@Model
final class UserProfile {
    var age: Int
    var sexRaw: String
    var heightCm: Double
    var weightKg: Double
    var activityLevelRaw: String
    var goalRaw: String
    var createdAt: Date

    /// Daily targets, computed at onboarding/settings time and stored.
    var calorieTarget: Double
    var proteinTarget: Double
    var carbsTarget: Double
    var fatTarget: Double

    init(
        age: Int,
        sex: BiologicalSex,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel,
        goal: WeightGoal
    ) {
        self.age = age
        self.sexRaw = sex.rawValue
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.activityLevelRaw = activityLevel.rawValue
        self.goalRaw = goal.rawValue
        self.createdAt = .now

        let targets = NutritionCalculator.targets(
            age: age, sex: sex, heightCm: heightCm, weightKg: weightKg,
            activityLevel: activityLevel, goal: goal
        )
        self.calorieTarget = targets.calories
        self.proteinTarget = targets.protein
        self.carbsTarget = targets.carbs
        self.fatTarget = targets.fat
    }

    var sex: BiologicalSex {
        get { BiologicalSex(rawValue: sexRaw) ?? .male }
        set { sexRaw = newValue.rawValue }
    }

    var activityLevel: ActivityLevel {
        get { ActivityLevel(rawValue: activityLevelRaw) ?? .sedentary }
        set { activityLevelRaw = newValue.rawValue }
    }

    var goal: WeightGoal {
        get { WeightGoal(rawValue: goalRaw) ?? .maintain }
        set { goalRaw = newValue.rawValue }
    }

    /// Recompute and store daily targets from the current stats.
    func recalculateTargets() {
        let targets = NutritionCalculator.targets(
            age: age, sex: sex, heightCm: heightCm, weightKg: weightKg,
            activityLevel: activityLevel, goal: goal
        )
        calorieTarget = targets.calories
        proteinTarget = targets.protein
        carbsTarget = targets.carbs
        fatTarget = targets.fat
    }
}
