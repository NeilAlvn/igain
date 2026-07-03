//
//  EditFoodEntrySheet.swift
//  Igain
//

import SwiftUI
import SwiftData

/// Edits a logged food entry. Changes are applied only on Save,
/// so Cancel leaves the entry untouched.
struct EditFoodEntrySheet: View {
    let entry: FoodEntry

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var brand: String
    @State private var servingDescription: String
    @State private var mealType: MealType
    @State private var calories: Double
    @State private var protein: Double
    @State private var carbs: Double
    @State private var fat: Double

    init(entry: FoodEntry) {
        self.entry = entry
        _name = State(initialValue: entry.name)
        _brand = State(initialValue: entry.brand ?? "")
        _servingDescription = State(initialValue: entry.servingDescription)
        _mealType = State(initialValue: entry.mealType)
        _calories = State(initialValue: entry.calories)
        _protein = State(initialValue: entry.protein)
        _carbs = State(initialValue: entry.carbs)
        _fat = State(initialValue: entry.fat)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Food") {
                    TextField("Name", text: $name)
                    TextField("Brand (optional)", text: $brand)
                    TextField("Serving (e.g. 100 g)", text: $servingDescription)
                    Picker("Meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                Section("Nutrition") {
                    macroEditor("Calories (kcal)", value: $calories, color: Theme.accent)
                    macroEditor("Protein (g)", value: $protein, color: Theme.protein)
                    macroEditor("Carbs (g)", value: $carbs, color: Theme.carbs)
                    macroEditor("Fat (g)", value: $fat, color: Theme.fat)
                }
            }
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .tint(Theme.accent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func macroEditor(_ label: String, value: Binding<Double>, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.subheadline)
            Spacer()
            TextField("0", value: value, format: .number.precision(.fractionLength(0)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 70)
                .monospacedDigit()
        }
    }

    private func save() {
        entry.name = name.trimmingCharacters(in: .whitespaces)
        let trimmedBrand = brand.trimmingCharacters(in: .whitespaces)
        entry.brand = trimmedBrand.isEmpty ? nil : trimmedBrand
        entry.servingDescription = servingDescription
        entry.mealType = mealType
        entry.calories = calories
        entry.protein = protein
        entry.carbs = carbs
        entry.fat = fat
        dismiss()
    }
}
