//
//  ContentView.swift
//  Igain
//
//  Created by Neil Alvin Medallon on 7/3/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Diary", systemImage: "book.fill") {
                DiaryView()
            }
            Tab("Scan", systemImage: "camera.viewfinder") {
                ScanView()
            }
            Tab("Foods", systemImage: "magnifyingglass") {
                FoodsView()
            }
            Tab("Settings", systemImage: "gearshape.fill") {
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
