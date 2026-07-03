//
//  ScanResultSheet.swift
//  Igain
//

import SwiftUI
import SwiftData

/// Editable confirmation of AI-detected foods before logging.
struct ScanResultSheet: View {
    @State private var items: [ScannedFoodItem]
    let onLogged: () -> Void

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var mealType: MealType = .current()
    @State private var hasLogged = false

    init(items: [ScannedFoodItem], onLogged: @escaping () -> Void) {
        _items = State(initialValue: items)
        self.onLogged = onLogged
    }

    private var totalCalories: Double {
        items.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Label("Detected", systemImage: "sparkles")
                            .foregroundStyle(Theme.accent)
                        Spacer()
                        Text("\(items.count) item\(items.count == 1 ? "" : "s") · \(Int(totalCalories)) kcal")
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                    }

                    Picker("Log to meal", selection: $mealType) {
                        ForEach(MealType.allCases) { Text($0.displayName).tag($0) }
                    }
                }

                ForEach($items) { $item in
                    Section {
                        TextField("Name", text: $item.name)
                            .font(.headline)
                        TextField("Portion", text: $item.portion)
                            .font(.subheadline)
                        macroEditor("Calories (kcal)", value: $item.calories, color: Theme.accent)
                        macroEditor("Protein (g)", value: $item.protein, color: Theme.protein)
                        macroEditor("Carbs (g)", value: $item.carbs, color: Theme.carbs)
                        macroEditor("Fat (g)", value: $item.fat, color: Theme.fat)
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            items.removeAll { $0.id == item.id }
                        } label: {
                            Label("Remove", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Scan Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log All") { logAll() }
                        .fontWeight(.semibold)
                        .tint(Theme.accent)
                        .disabled(items.isEmpty || hasLogged)
                }
            }
        }
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

    private func logAll() {
        guard !hasLogged else { return }
        hasLogged = true
        for item in items {
            let entry = FoodEntry(
                name: item.name,
                mealType: mealType,
                date: .now,
                servingDescription: item.portion,
                calories: item.calories,
                protein: item.protein,
                carbs: item.carbs,
                fat: item.fat,
                source: .ai
            )
            context.insert(entry)
        }
        dismiss()
        onLogged()
    }
}
