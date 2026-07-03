//
//  MealSectionView.swift
//  Igain
//

import SwiftUI
import SwiftData

/// One meal group (Breakfast, Lunch, ...) in the diary list.
/// Tapping an entry reveals edit (pencil) and delete (trash) actions.
struct MealSectionView: View {
    let mealType: MealType
    let entries: [FoodEntry]
    let onDelete: (FoodEntry) -> Void

    @State private var expandedID: PersistentIdentifier?
    @State private var editingEntry: FoodEntry?

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
                    FoodEntryRow(
                        entry: entry,
                        isExpanded: expandedID == entry.persistentModelID,
                        onEdit: { editingEntry = entry },
                        onDelete: {
                            expandedID = nil
                            onDelete(entry)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.snappy) {
                            expandedID = expandedID == entry.persistentModelID
                                ? nil
                                : entry.persistentModelID
                        }
                    }
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
        .sheet(item: $editingEntry) { entry in
            EditFoodEntrySheet(entry: entry)
        }
    }
}

struct FoodEntryRow: View {
    let entry: FoodEntry
    var isExpanded = false
    var onEdit: () -> Void = {}
    var onDelete: () -> Void = {}

    var body: some View {
        VStack(spacing: 10) {
            content
            if isExpanded {
                actions
            }
        }
        .padding(.vertical, 2)
    }

    private var content: some View {
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
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                onEdit()
            } label: {
                Label("Edit", systemImage: "pencil")
                    .frame(maxWidth: .infinity)
            }
            .tint(Theme.accent)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
        }
        .font(.subheadline.weight(.medium))
        .buttonStyle(.bordered)
    }

    private func macroText(_ grams: Double, _ letter: String, _ color: Color) -> some View {
        Text("\(Int(grams))\(letter)")
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .monospacedDigit()
    }
}
