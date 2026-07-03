//
//  MealSectionView.swift
//  Igain
//

import SwiftUI
import SwiftData

/// One meal group (Breakfast, Lunch, ...) in the diary list.
struct MealSectionView: View {
    let mealType: MealType
    let entries: [FoodEntry]
    let onDelete: (FoodEntry) -> Void

    private var mealCalories: Double {
        entries.reduce(0) { $0 + $1.calories }
    }

    var body: some View {
        Section {
            if entries.isEmpty {
                Text("Nothing logged yet")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
            } else {
                ForEach(entries) { entry in
                    FoodEntryRow(entry: entry)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                onDelete(entry)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        } header: {
            HStack {
                Label(mealType.displayName, systemImage: mealType.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                Spacer()
                if mealCalories > 0 {
                    Text("\(Int(mealCalories)) kcal")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
            .textCase(nil)
        }
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if let brand = entry.brand, !brand.isEmpty {
                        Text(brand)
                    }
                    Text(entry.servingDescription)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(entry.calories)) kcal")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                HStack(spacing: 6) {
                    macroText(entry.protein, "P", Theme.protein)
                    macroText(entry.carbs, "C", Theme.carbs)
                    macroText(entry.fat, "F", Theme.fat)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private func macroText(_ grams: Double, _ letter: String, _ color: Color) -> some View {
        Text("\(Int(grams))\(letter)")
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .monospacedDigit()
    }
}
