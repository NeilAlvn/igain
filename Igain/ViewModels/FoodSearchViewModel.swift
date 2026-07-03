//
//  FoodSearchViewModel.swift
//  Igain
//

import Foundation
import Observation

@Observable
@MainActor
final class FoodSearchViewModel {
    var query = ""
    var results: [FoodProduct] = []
    var isSearching = false
    var errorMessage: String?

    private let service = OpenFoodFactsService()
    private var searchTask: Task<Void, Never>?

    func search() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        searchTask?.cancel()
        guard trimmed.count >= 2 else {
            results = []
            return
        }

        searchTask = Task {
            isSearching = true
            errorMessage = nil
            defer { isSearching = false }
            do {
                let found = try await service.search(query: trimmed)
                guard !Task.isCancelled else { return }
                results = found
            } catch is CancellationError {
            } catch {
                guard !Task.isCancelled else { return }
                errorMessage = error.localizedDescription
                results = []
            }
        }
    }

    func lookupBarcode(_ code: String) async throws -> FoodProduct {
        try await service.product(barcode: code)
    }
}
