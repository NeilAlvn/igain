//
//  DemoSeeder.swift
//  Igain
//

#if DEBUG
import Foundation
import SwiftData

/// Populates realistic sample data when launched with "-demo"
/// (used for README screenshots and previews). Debug builds only.
enum DemoSeeder {
    static var isEnabled: Bool {
        CommandLine.arguments.contains("-demo")
    }

    /// Initial tab passed as "-tab <diary|scan|foods|settings>".
    static var initialTab: String? {
        guard let index = CommandLine.arguments.firstIndex(of: "-tab"),
              CommandLine.arguments.indices.contains(index + 1) else { return nil }
        return CommandLine.arguments[index + 1]
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        guard isEnabled else { return }
        guard (try? context.fetchCount(FetchDescriptor<UserProfile>())) == 0 else { return }

        context.insert(UserProfile(
            age: 24, sex: .male, heightCm: 172, weightKg: 63,
            activityLevel: .moderate, goal: .gain
        ))

        let today = Calendar.current.startOfDay(for: .now)
        func at(_ hour: Int) -> Date {
            Calendar.current.date(byAdding: .hour, value: hour, to: today)!
        }

        let meals: [(String, String?, MealType, Int, String, Double, Double, Double, Double, FoodSource)] = [
            ("Oatmeal with Banana", nil, .breakfast, 8, "1 bowl", 310, 9, 58, 6, .ai),
            ("Scrambled Eggs", nil, .breakfast, 8, "2 large", 182, 12, 2, 13, .ai),
            ("Chicken Breast", nil, .lunch, 12, "150 g", 248, 47, 0, 5, .search),
            ("Steamed Rice", nil, .lunch, 12, "200 g", 260, 5, 57, 1, .search),
            ("Greek Yogurt", "Chobani", .snacks, 15, "1 cup", 140, 14, 9, 4, .barcode),
            ("Grilled Salmon", nil, .dinner, 19, "180 g", 367, 39, 0, 22, .ai),
            ("Roasted Vegetables", nil, .dinner, 19, "1 plate", 120, 4, 18, 4, .ai)
        ]

        for (name, brand, meal, hour, serving, kcal, p, c, f, source) in meals {
            context.insert(FoodEntry(
                name: name, brand: brand, mealType: meal, date: at(hour),
                servingDescription: serving, calories: Double(kcal),
                protein: p, carbs: c, fat: f, source: source
            ))
        }

        context.insert(WaterDay(date: .now, cups: 5))
    }
}
#endif
