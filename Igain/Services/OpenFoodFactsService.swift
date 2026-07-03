//
//  OpenFoodFactsService.swift
//  Igain
//

import Foundation

/// A food product from OpenFoodFacts, normalized to per-100g values.
struct FoodProduct: Identifiable, Hashable {
    let id: String            // barcode
    let name: String
    let brand: String?
    let servingSize: String?  // e.g. "30 g"
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatPer100g: Double
    let fiberPer100g: Double?
    let sugarPer100g: Double?
}

enum OpenFoodFactsError: LocalizedError {
    case notFound
    case badResponse

    var errorDescription: String? {
        switch self {
        case .notFound: "Product not found."
        case .badResponse: "Couldn't reach the food database. Check your connection."
        }
    }
}

/// Free, keyless food database. https://world.openfoodfacts.org
struct OpenFoodFactsService {
    private static let userAgent = "Igain - iOS - Version 1.0"

    func search(query: String) async throws -> [FoodProduct] {
        var components = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "25"),
            URLQueryItem(name: "fields", value: "code,product_name,brands,serving_size,nutriments"),
        ]

        let data = try await fetch(url: components.url!)
        let response = try JSONDecoder().decode(SearchResponse.self, from: data)
        return response.products.compactMap { FoodProduct(raw: $0) }
    }

    func product(barcode: String) async throws -> FoodProduct {
        let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(barcode).json")!
        let data = try await fetch(url: url)
        let response = try JSONDecoder().decode(ProductResponse.self, from: data)
        guard response.status == 1, let raw = response.product,
              let product = FoodProduct(raw: raw) else {
            throw OpenFoodFactsError.notFound
        }
        return product
    }

    private func fetch(url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw OpenFoodFactsError.badResponse
        }
        return data
    }
}

// MARK: - Raw API decoding

private struct SearchResponse: Decodable {
    let products: [RawProduct]
}

private struct ProductResponse: Decodable {
    let status: Int
    let product: RawProduct?
}

private struct RawProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let servingSize: String?
    let nutriments: Nutriments?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case servingSize = "serving_size"
        case nutriments
    }
}

private struct Nutriments: Decodable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let carbohydrates100g: Double?
    let fat100g: Double?
    let fiber100g: Double?
    let sugars100g: Double?

    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case carbohydrates100g = "carbohydrates_100g"
        case fat100g = "fat_100g"
        case fiber100g = "fiber_100g"
        case sugars100g = "sugars_100g"
    }

    // OFF sometimes returns these as strings; decode either.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        energyKcal100g = Self.number(container, .energyKcal100g)
        proteins100g = Self.number(container, .proteins100g)
        carbohydrates100g = Self.number(container, .carbohydrates100g)
        fat100g = Self.number(container, .fat100g)
        fiber100g = Self.number(container, .fiber100g)
        sugars100g = Self.number(container, .sugars100g)
    }

    private static func number(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Double? {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let string = try? container.decode(String.self, forKey: key) { return Double(string) }
        return nil
    }
}

private extension FoodProduct {
    /// Returns nil for products without a name or calorie data — not useful for logging.
    init?(raw: RawProduct) {
        guard let name = raw.productName, !name.isEmpty,
              let calories = raw.nutriments?.energyKcal100g else { return nil }
        self.init(
            id: raw.code ?? UUID().uuidString,
            name: name,
            brand: raw.brands?.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces),
            servingSize: raw.servingSize,
            caloriesPer100g: calories,
            proteinPer100g: raw.nutriments?.proteins100g ?? 0,
            carbsPer100g: raw.nutriments?.carbohydrates100g ?? 0,
            fatPer100g: raw.nutriments?.fat100g ?? 0,
            fiberPer100g: raw.nutriments?.fiber100g,
            sugarPer100g: raw.nutriments?.sugars100g
        )
    }
}
