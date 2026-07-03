//
//  FoodEntry.swift
//  Igain
//

import Foundation
import SwiftData

enum FoodSource: String, Codable {
    case ai
    case search
    case barcode
    case manual
}

@Model
final class FoodEntry {
    var name: String
    var brand: String?
    var mealTypeRaw: String
    var date: Date
    var servingDescription: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double?
    var sugar: Double?
    var sourceRaw: String

    init(
        name: String,
        brand: String? = nil,
        mealType: MealType,
        date: Date = .now,
        servingDescription: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double? = nil,
        sugar: Double? = nil,
        source: FoodSource
    ) {
        self.name = name
        self.brand = brand
        self.mealTypeRaw = mealType.rawValue
        self.date = date
        self.servingDescription = servingDescription
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sourceRaw = source.rawValue
    }

    var mealType: MealType {
        get { MealType(rawValue: mealTypeRaw) ?? .snacks }
        set { mealTypeRaw = newValue.rawValue }
    }

    var source: FoodSource {
        get { FoodSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}
