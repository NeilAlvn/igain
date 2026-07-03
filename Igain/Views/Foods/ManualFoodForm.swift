//
//  ManualFoodForm.swift
//  Igain
//

import SwiftUI
import SwiftData

/// Type-it-yourself custom food entry.
struct ManualFoodForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var brand = ""
    @State private var servingDescription = "1 serving"
    @State private var mealType: MealType = .current()
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(calories) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name (required)", text: $name)
                    TextField("Brand (optional)", text: $brand)
                    TextField("Serving description", text: $servingDescription)
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                Section("Nutrition") {
                    numberField("Calories (kcal, required)", text: $calories)
                    numberField("Protein (g)", text: $protein)
                    numberField("Carbs (g)", text: $carbs)
                    numberField("Fat (g)", text: $fat)
                }
            }
            .navigationTitle("Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { log() }
                        .fontWeight(.semibold)
                        .tint(Theme.accent)
                        .disabled(!isValid)
                }
            }
        }
    }

    private func numberField(_ label: String, text: Binding<String>) -> some View {
        TextField(label, text: text)
            .keyboardType(.decimalPad)
    }

    private func log() {
        let entry = FoodEntry(
            name: name.trimmingCharacters(in: .whitespaces),
            brand: brand.isEmpty ? nil : brand,
            mealType: mealType,
            date: .now,
            servingDescription: servingDescription,
            calories: Double(calories) ?? 0,
            protein: Double(protein) ?? 0,
            carbs: Double(carbs) ?? 0,
            fat: Double(fat) ?? 0,
            source: .manual
        )
        context.insert(entry)
        dismiss()
    }
}
