//
//  FoodDetailSheet.swift
//  Igain
//

import SwiftUI
import SwiftData

/// Serving-size picker + nutrition preview for a searched/scanned product.
struct FoodDetailSheet: View {
    let product: FoodProduct

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var grams: Double = 100
    @State private var mealType: MealType = .current()
    @State private var hasLogged = false

    private var factor: Double { grams / 100 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.headline)
                        if let brand = product.brand {
                            Text(brand)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        if let serving = product.servingSize {
                            Text("Serving size: \(serving)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Amount") {
                    HStack {
                        Text("\(Int(grams)) g")
                            .font(.title3.weight(.semibold))
                            .monospacedDigit()
                            .frame(width: 90, alignment: .leading)
                        Slider(value: $grams, in: 5...500, step: 5)
                            .tint(Theme.accent)
                    }
                    HStack {
                        ForEach([50.0, 100.0, 150.0, 200.0], id: \.self) { preset in
                            Button("\(Int(preset))g") { grams = preset }
                                .buttonStyle(.bordered)
                                .tint(grams == preset ? Theme.accent : .secondary)
                                .font(.caption)
                        }
                    }

                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                Section("Nutrition") {
                    nutritionRow("Calories", product.caloriesPer100g * factor, unit: "kcal", color: Theme.accent)
                    nutritionRow("Protein", product.proteinPer100g * factor, unit: "g", color: Theme.protein)
                    nutritionRow("Carbs", product.carbsPer100g * factor, unit: "g", color: Theme.carbs)
                    nutritionRow("Fat", product.fatPer100g * factor, unit: "g", color: Theme.fat)
                    if let fiber = product.fiberPer100g {
                        nutritionRow("Fiber", fiber * factor, unit: "g", color: .secondary)
                    }
                    if let sugar = product.sugarPer100g {
                        nutritionRow("Sugar", sugar * factor, unit: "g", color: .secondary)
                    }
                }
            }
            .navigationTitle("Add Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { log() }
                        .fontWeight(.semibold)
                        .tint(Theme.accent)
                        .disabled(hasLogged)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func nutritionRow(_ label: String, _ value: Double, unit: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
            Spacer()
            Text("\(value, specifier: "%.0f") \(unit)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    private func log() {
        guard !hasLogged else { return }
        hasLogged = true
        let entry = FoodEntry(
            name: product.name,
            brand: product.brand,
            mealType: mealType,
            date: .now,
            servingDescription: "\(Int(grams)) g",
            calories: product.caloriesPer100g * factor,
            protein: product.proteinPer100g * factor,
            carbs: product.carbsPer100g * factor,
            fat: product.fatPer100g * factor,
            fiber: product.fiberPer100g.map { $0 * factor },
            sugar: product.sugarPer100g.map { $0 * factor },
            source: .search
        )
        context.insert(entry)
        dismiss()
    }
}
