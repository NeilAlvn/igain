//
//  ContentView.swift
//  Igain
//
//  Created by Neil Alvin Medallon on 7/3/26.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab: String = {
        #if DEBUG
        DemoSeeder.initialTab ?? "diary"
        #else
        "diary"
        #endif
    }()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Diary", systemImage: "book.fill", value: "diary") {
                DiaryView()
            }
            Tab("Scan", systemImage: "camera.viewfinder", value: "scan") {
                ScanView()
            }
            Tab("Foods", systemImage: "magnifyingglass", value: "foods") {
                FoodsView()
            }
            Tab("Settings", systemImage: "gearshape.fill", value: "settings") {
                SettingsView()
            }
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
