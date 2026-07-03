//
//  SettingsView.swift
//  Igain
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var profiles: [UserProfile]
    @State private var apiKey: String = KeychainHelper.read(account: KeychainHelper.geminiKeyAccount) ?? ""
    @State private var keySaved = false

    var body: some View {
        NavigationStack {
            Form {
                if let profile = profiles.first {
                    ProfileSection(profile: profile)
                    TargetsSection(profile: profile)
                }

                Section {
                    SecureField("Paste your Gemini API key", text: $apiKey)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        KeychainHelper.save(apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
                                            account: KeychainHelper.geminiKeyAccount)
                        keySaved = true
                    } label: {
                        if keySaved {
                            Label("Saved", systemImage: "checkmark")
                                .foregroundStyle(Theme.positive)
                        } else {
                            Text("Save Key")
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("Gemini API Key")
                } footer: {
                    Text("Powers the AI food scanner. Get a free key at aistudio.google.com → Get API key. Stored securely in the Keychain.")
                }
                .onChange(of: apiKey) { keySaved = false }

                Section("About") {
                    LabeledContent("App", value: "Igain")
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Food database", value: "OpenFoodFacts")
                    LabeledContent("AI model", value: "Gemini 2.5 Flash")
                }
            }
            .navigationTitle("Settings")
            .tint(Theme.accent)
        }
    }
}

/// Editable body stats; any change recomputes daily targets.
private struct ProfileSection: View {
    @Bindable var profile: UserProfile

    var body: some View {
        Section("Profile") {
            Picker("Sex", selection: $profile.sex) {
                ForEach(BiologicalSex.allCases) { Text($0.displayName).tag($0) }
            }
            Stepper("Age: \(profile.age)", value: $profile.age, in: 13...100)
            Stepper("Height: \(Int(profile.heightCm)) cm", value: $profile.heightCm, in: 120...220, step: 1)
            Stepper("Weight: \(profile.weightKg, specifier: "%.1f") kg", value: $profile.weightKg, in: 35...200, step: 0.5)
            Picker("Activity", selection: $profile.activityLevel) {
                ForEach(ActivityLevel.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("Goal", selection: $profile.goal) {
                ForEach(WeightGoal.allCases) { Text($0.displayName).tag($0) }
            }
        }
        .onChange(of: profile.age) { profile.recalculateTargets() }
        .onChange(of: profile.sexRaw) { profile.recalculateTargets() }
        .onChange(of: profile.heightCm) { profile.recalculateTargets() }
        .onChange(of: profile.weightKg) { profile.recalculateTargets() }
        .onChange(of: profile.activityLevelRaw) { profile.recalculateTargets() }
        .onChange(of: profile.goalRaw) { profile.recalculateTargets() }
    }
}

private struct TargetsSection: View {
    let profile: UserProfile

    var body: some View {
        Section("Daily Targets") {
            LabeledContent("Calories", value: "\(Int(profile.calorieTarget)) kcal")
            LabeledContent("Protein", value: "\(Int(profile.proteinTarget)) g")
            LabeledContent("Carbs", value: "\(Int(profile.carbsTarget)) g")
            LabeledContent("Fat", value: "\(Int(profile.fatTarget)) g")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
