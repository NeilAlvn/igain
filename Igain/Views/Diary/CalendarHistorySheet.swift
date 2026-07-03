//
//  CalendarHistorySheet.swift
//  Igain
//

import SwiftUI
import SwiftData

/// Calendar for jumping to any past day and previewing its macro totals.
struct CalendarHistorySheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \FoodEntry.date) private var allEntries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    private var dayEntries: [FoodEntry] {
        allEntries.filter { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    private var totalCalories: Double { dayEntries.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { dayEntries.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { dayEntries.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { dayEntries.reduce(0) { $0 + $1.fat } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date.now,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(Theme.accent)
                }

                Section {
                    if dayEntries.isEmpty {
                        Text("Nothing logged on this day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        HStack {
                            Label("\(dayEntries.count) item\(dayEntries.count == 1 ? "" : "s")", systemImage: "fork.knife")
                            Spacer()
                            Text("\(Int(totalCalories)) / \(Int(profile?.calorieTarget ?? 2000)) kcal")
                                .fontWeight(.semibold)
                                .foregroundStyle(Theme.accent)
                                .monospacedDigit()
                        }
                        macroRow("Protein", totalProtein, target: profile?.proteinTarget ?? 150, color: Theme.protein)
                        macroRow("Carbs", totalCarbs, target: profile?.carbsTarget ?? 200, color: Theme.carbs)
                        macroRow("Fat", totalFat, target: profile?.fatTarget ?? 65, color: Theme.fat)
                    }
                } header: {
                    Text(selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .textCase(nil)
                }

                Section {
                    Button {
                        dismiss()
                    } label: {
                        Label("Show in Diary", systemImage: "book.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func macroRow(_ label: String, _ consumed: Double, target: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text("\(Int(consumed)) / \(Int(target)) g")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            ProgressView(value: min(consumed / max(target, 1), 1))
                .tint(color)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    CalendarHistorySheet(selectedDate: .constant(.now))
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
