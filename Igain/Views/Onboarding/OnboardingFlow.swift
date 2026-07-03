//
//  OnboardingFlow.swift
//  Igain
//

import SwiftUI
import SwiftData

/// First-launch flow: welcome → body stats → activity → goal → computed targets.
struct OnboardingFlow: View {
    @Environment(\.modelContext) private var context

    @State private var step = 0
    @State private var age = 25
    @State private var sex: BiologicalSex = .male
    @State private var heightCm: Double = 170
    @State private var weightKg: Double = 70
    @State private var activityLevel: ActivityLevel = .light
    @State private var goal: WeightGoal = .maintain

    private var targets: NutritionTargets {
        NutritionCalculator.targets(
            age: age, sex: sex, heightCm: heightCm, weightKg: weightKg,
            activityLevel: activityLevel, goal: goal
        )
    }

    var body: some View {
        VStack {
            if step > 0 {
                ProgressView(value: Double(step), total: 4)
                    .tint(Theme.accent)
                    .padding(.horizontal)
            }

            TabView(selection: $step) {
                welcomeStep.tag(0)
                statsStep.tag(1)
                activityStep.tag(2)
                goalStep.tag(3)
                targetsStep.tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: step)

            Button {
                if step < 4 {
                    step += 1
                } else {
                    finish()
                }
            } label: {
                Text(step == 0 ? "Get Started" : step == 4 ? "Start Tracking" : "Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(Theme.accent)
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
        .background(Theme.background)
    }

    private func finish() {
        let profile = UserProfile(
            age: age, sex: sex, heightCm: heightCm, weightKg: weightKg,
            activityLevel: activityLevel, goal: goal
        )
        context.insert(profile)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "flame.fill")
                .font(.system(size: 64))
                .foregroundStyle(Theme.accent)
            Text("Welcome to Igain")
                .font(.largeTitle.bold())
            Text("Track calories and macros effortlessly.\nSnap a photo of your meal and let AI do the counting.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var statsStep: some View {
        Form {
            Section("About You") {
                Picker("Sex", selection: $sex) {
                    ForEach(BiologicalSex.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)

                Stepper("Age: \(age)", value: $age, in: 13...100)

                VStack(alignment: .leading) {
                    Text("Height: \(Int(heightCm)) cm")
                    Slider(value: $heightCm, in: 120...220, step: 1)
                        .tint(Theme.accent)
                }

                VStack(alignment: .leading) {
                    Text("Weight: \(weightKg, specifier: "%.1f") kg")
                    Slider(value: $weightKg, in: 35...200, step: 0.5)
                        .tint(Theme.accent)
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var activityStep: some View {
        Form {
            Section("Activity Level") {
                ForEach(ActivityLevel.allCases) { level in
                    Button {
                        activityLevel = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(level.displayName)
                                    .foregroundStyle(.primary)
                                Text(level.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var goalStep: some View {
        Form {
            Section("Your Goal") {
                ForEach(WeightGoal.allCases) { g in
                    Button {
                        goal = g
                    } label: {
                        HStack {
                            Image(systemName: g.systemImage)
                                .foregroundStyle(Theme.accent)
                            Text(g.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if goal == g {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.accent)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private var targetsStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Your Daily Targets")
                .font(.title.bold())

            VStack(spacing: 16) {
                HStack {
                    Label("Calories", systemImage: "flame.fill")
                        .foregroundStyle(Theme.accent)
                    Spacer()
                    Text("\(Int(targets.calories)) kcal")
                        .font(.headline)
                }
                Divider()
                targetRow("Protein", grams: targets.protein, color: Theme.protein)
                targetRow("Carbs", grams: targets.carbs, color: Theme.carbs)
                targetRow("Fat", grams: targets.fat, color: Theme.fat)
            }
            .cardStyle()
            .padding(.horizontal)

            Text("You can adjust these anytime in Settings.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func targetRow(_ label: String, grams: Double, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
            Spacer()
            Text("\(Int(grams)) g")
                .font(.headline)
        }
    }
}

#Preview {
    OnboardingFlow()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
