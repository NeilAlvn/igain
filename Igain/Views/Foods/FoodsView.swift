//
//  FoodsView.swift
//  Igain
//

import SwiftUI
import SwiftData

struct FoodsView: View {
    @State private var viewModel = FoodSearchViewModel()
    @State private var selectedProduct: FoodProduct?
    @State private var showBarcodeScanner = false
    @State private var showManualForm = false
    @State private var barcodeError: String?

    var body: some View {
        NavigationStack {
            List {
                if viewModel.results.isEmpty && !viewModel.isSearching {
                    quickActions
                    RecentFoodsSection()
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.secondary)
                }

                ForEach(viewModel.results) { product in
                    Button {
                        selectedProduct = product
                    } label: {
                        ProductRow(product: product)
                    }
                    .buttonStyle(.plain)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.background)
            .navigationTitle("Foods")
            .searchable(text: $viewModel.query, prompt: "Search foods (e.g. banana)")
            .onSubmit(of: .search) { viewModel.search() }
            .onChange(of: viewModel.query) { viewModel.search() }
            .overlay {
                if viewModel.isSearching {
                    ProgressView()
                }
            }
            .sheet(item: $selectedProduct) { product in
                FoodDetailSheet(product: product)
            }
            .sheet(isPresented: $showBarcodeScanner) {
                BarcodeScannerView { code in
                    showBarcodeScanner = false
                    Task { await lookup(code) }
                }
            }
            .sheet(isPresented: $showManualForm) {
                ManualFoodForm()
            }
            .alert("Barcode Lookup Failed", isPresented: .init(
                get: { barcodeError != nil },
                set: { if !$0 { barcodeError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(barcodeError ?? "")
            }
        }
    }

    private var quickActions: some View {
        Section {
            Button {
                showBarcodeScanner = true
            } label: {
                Label("Scan a Barcode", systemImage: "barcode.viewfinder")
            }
            Button {
                showManualForm = true
            } label: {
                Label("Add Custom Food", systemImage: "plus.circle")
            }
        }
        .tint(Theme.accent)
    }

    private func lookup(_ code: String) async {
        do {
            selectedProduct = try await viewModel.lookupBarcode(code)
        } catch {
            barcodeError = error.localizedDescription
        }
    }
}

struct ProductRow: View {
    let product: FoodProduct

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(product.name)
                    .lineLimit(1)
                if let brand = product.brand {
                    Text(brand)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Text("\(Int(product.caloriesPer100g)) kcal / 100g")
                .font(.caption.weight(.medium))
                .foregroundStyle(Theme.accent)
                .monospacedDigit()
        }
    }
}

/// Recently logged foods — tap to re-log the same food to today's matching meal.
struct RecentFoodsSection: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodEntry.date, order: .reverse) private var recentEntries: [FoodEntry]
    @State private var reloggedName: String?

    private var recentUnique: [FoodEntry] {
        var seen = Set<String>()
        return Array(recentEntries.filter { seen.insert($0.name).inserted }.prefix(8))
    }

    var body: some View {
        if !recentUnique.isEmpty {
            Section("Recent") {
                ForEach(recentUnique) { entry in
                    Button {
                        relog(entry)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(entry.name).lineLimit(1)
                                Text(entry.servingDescription)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if reloggedName == entry.name {
                                Label("Logged", systemImage: "checkmark")
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Theme.positive)
                            } else {
                                Text("\(Int(entry.calories)) kcal")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func relog(_ entry: FoodEntry) {
        guard reloggedName != entry.name else { return }
        let copy = FoodEntry(
            name: entry.name, brand: entry.brand,
            mealType: .current(), date: .now,
            servingDescription: entry.servingDescription,
            calories: entry.calories, protein: entry.protein,
            carbs: entry.carbs, fat: entry.fat,
            fiber: entry.fiber, sugar: entry.sugar,
            source: entry.source
        )
        context.insert(copy)
        reloggedName = entry.name
        Task {
            try? await Task.sleep(for: .seconds(2))
            if reloggedName == entry.name { reloggedName = nil }
        }
    }
}

#Preview {
    FoodsView()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
