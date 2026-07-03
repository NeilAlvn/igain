//
//  IgainApp.swift
//  Igain
//
//  Created by Neil Alvin Medallon on 7/3/26.
//

import SwiftUI
import SwiftData

@main
struct IgainApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [FoodEntry.self, UserProfile.self, WaterDay.self])
    }
}

/// Shows onboarding until a profile exists, then the main tab UI.
struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.isEmpty {
            OnboardingFlow()
        } else {
            ContentView()
        }
    }
}
