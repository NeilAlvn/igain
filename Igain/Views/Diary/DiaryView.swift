//
//  DiaryView.swift
//  Igain
//

import SwiftUI
import SwiftData

struct DiaryView: View {
    @State private var selectedDate: Date = .now
    @State private var showCalendar = false

    var body: some View {
        NavigationStack {
            DiaryContentView(date: selectedDate)
                .navigationTitle("Diary")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        DateNavigator(selectedDate: $selectedDate)
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCalendar = true
                        } label: {
                            Image(systemName: "calendar")
                        }
                        .tint(Theme.accent)
                    }
                }
                .sheet(isPresented: $showCalendar) {
                    CalendarHistorySheet(selectedDate: $selectedDate)
                }
        }
    }
}

/// Arrow-based day switcher shown in the nav bar.
struct DateNavigator: View {
    @Binding var selectedDate: Date

    private var label: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        return selectedDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        HStack(spacing: 20) {
            Button {
                shift(by: -1)
            } label: {
                Image(systemName: "chevron.left")
            }

            Text(label)
                .font(.headline)
                .frame(minWidth: 110)

            Button {
                shift(by: 1)
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
        }
        .tint(Theme.accent)
    }

    private func shift(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
        }
    }
}

/// Queries and renders one day of the diary.
struct DiaryContentView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [FoodEntry]
    @Query private var profiles: [UserProfile]

    init(date: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        _entries = Query(
            filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end },
            sort: \FoodEntry.date
        )
    }

    private var profile: UserProfile? { profiles.first }

    private var totalCalories: Double { entries.reduce(0) { $0 + $1.calories } }
    private var totalProtein: Double { entries.reduce(0) { $0 + $1.protein } }
    private var totalCarbs: Double { entries.reduce(0) { $0 + $1.carbs } }
    private var totalFat: Double { entries.reduce(0) { $0 + $1.fat } }

    var body: some View {
        List {
            Section {
                summaryCard
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            ForEach(MealType.allCases) { meal in
                MealSectionView(
                    mealType: meal,
                    entries: entries.filter { $0.mealType == meal },
                    onDelete: { context.delete($0) }
                )
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.background)
    }

    private var summaryCard: some View {
        HStack(spacing: 20) {
            CalorieRingView(
                consumed: totalCalories,
                target: profile?.calorieTarget ?? 2000
            )
            .frame(width: 140, height: 140)

            VStack(spacing: 14) {
                MacroBarView(
                    label: "Protein",
                    consumed: totalProtein,
                    target: profile?.proteinTarget ?? 150,
                    color: Theme.protein
                )
                MacroBarView(
                    label: "Carbs",
                    consumed: totalCarbs,
                    target: profile?.carbsTarget ?? 200,
                    color: Theme.carbs
                )
                MacroBarView(
                    label: "Fat",
                    consumed: totalFat,
                    target: profile?.fatTarget ?? 65,
                    color: Theme.fat
                )
            }
        }
        .cardStyle()
    }
}

#Preview {
    DiaryView()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
