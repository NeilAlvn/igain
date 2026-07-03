//
//  NutritionCalculator.swift
//  Igain
//

import Foundation

struct NutritionTargets {
    let calories: Double
    let protein: Double
    let carbs: Double
    let fat: Double
}

enum NutritionCalculator {
    /// Mifflin-St Jeor basal metabolic rate in kcal/day.
    static func bmr(age: Int, sex: BiologicalSex, heightCm: Double, weightKg: Double) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age)
        return sex == .male ? base + 5 : base - 161
    }

    /// Total daily energy expenditure.
    static func tdee(age: Int, sex: BiologicalSex, heightCm: Double, weightKg: Double, activityLevel: ActivityLevel) -> Double {
        bmr(age: age, sex: sex, heightCm: heightCm, weightKg: weightKg) * activityLevel.multiplier
    }

    /// Daily calorie + macro targets. Macro split: 30% protein, 40% carbs, 30% fat.
    /// Calories are floored at 1200 to avoid recommending unsafe targets.
    static func targets(
        age: Int,
        sex: BiologicalSex,
        heightCm: Double,
        weightKg: Double,
        activityLevel: ActivityLevel,
        goal: WeightGoal
    ) -> NutritionTargets {
        let expenditure = tdee(age: age, sex: sex, heightCm: heightCm, weightKg: weightKg, activityLevel: activityLevel)
        let calories = max(1200, (expenditure + goal.calorieAdjustment).rounded())
        return NutritionTargets(
            calories: calories,
            protein: (calories * 0.30 / 4).rounded(),
            carbs: (calories * 0.40 / 4).rounded(),
            fat: (calories * 0.30 / 9).rounded()
        )
    }
}
