//
//  GeminiService.swift
//  Igain
//

import Foundation

/// One food item detected in a meal photo.
struct ScannedFoodItem: Codable, Identifiable {
    let id = UUID()
    var name: String
    var portion: String
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double

    enum CodingKeys: String, CodingKey {
        case name, portion, calories, protein, carbs, fat
    }
}

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case rateLimited
    case noFoodFound
    case badResponse(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "No Gemini API key set. Add one in Settings (free at aistudio.google.com)."
        case .invalidAPIKey:
            "Gemini rejected the API key. Check it in Settings."
        case .rateLimited:
            "Gemini free-tier limit reached. Try again in a minute."
        case .noFoodFound:
            "No food detected in the photo. Try a clearer shot of the meal."
        case .badResponse(let detail):
            "AI analysis failed: \(detail)"
        }
    }
}

/// Calls the Gemini API (free tier) to estimate nutrition from a meal photo.
/// Plain REST — no SDK dependency.
struct GeminiService {
    private static let endpoint =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"

    static let prompt = """
        You are a nutrition expert. Analyze this photo of food. Identify each distinct \
        food item visible and estimate its portion size and nutrition. Be realistic with \
        portion estimates based on what is visible. Return every item as JSON with: name \
        (short food name), portion (human-readable estimate like "1 cup" or "150 g"), \
        calories (kcal), protein (g), carbs (g), fat (g). If the image contains no food, \
        return an empty array.
        """

    func analyze(imageData: Data) async throws -> [ScannedFoodItem] {
        guard let apiKey = KeychainHelper.read(account: KeychainHelper.geminiKeyAccount),
              !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }

        var request = URLRequest(url: URL(string: Self.endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 60
        request.httpBody = try JSONEncoder().encode(GenerateRequest(imageData: imageData))

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        switch status {
        case 200:
            break
        case 400, 401, 403:
            throw GeminiError.invalidAPIKey
        case 429:
            throw GeminiError.rateLimited
        default:
            throw GeminiError.badResponse("HTTP \(status)")
        }

        let decoded = try JSONDecoder().decode(GenerateResponse.self, from: data)
        guard let text = decoded.candidates?.first?.content?.parts?.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw GeminiError.badResponse("empty response")
        }

        let items: [ScannedFoodItem]
        do {
            items = try JSONDecoder().decode([ScannedFoodItem].self, from: jsonData)
        } catch {
            throw GeminiError.badResponse("unreadable result")
        }

        guard !items.isEmpty else { throw GeminiError.noFoodFound }
        return items
    }
}

// MARK: - Request/response payloads

private struct GenerateRequest: Encodable {
    struct InlineData: Encodable {
        let mimeType: String
        let data: String

        enum CodingKeys: String, CodingKey {
            case mimeType = "mime_type"
            case data
        }
    }

    struct Part: Encodable {
        var text: String? = nil
        var inlineData: InlineData? = nil

        enum CodingKeys: String, CodingKey {
            case text
            case inlineData = "inline_data"
        }
    }

    struct Content: Encodable {
        let parts: [Part]
    }

    struct GenerationConfig: Encodable {
        let responseMimeType: String
        let responseSchema: JSONSchema

        enum CodingKeys: String, CodingKey {
            case responseMimeType = "response_mime_type"
            case responseSchema = "response_schema"
        }
    }

    struct JSONSchema: Encodable {
        // Gemini's OpenAPI-style schema for an array of food items.
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: DynamicKey.self)
            try container.encode("ARRAY", forKey: .init("type"))
            var items = container.nestedContainer(keyedBy: DynamicKey.self, forKey: .init("items"))
            try items.encode("OBJECT", forKey: .init("type"))
            try items.encode(["name", "portion", "calories", "protein", "carbs", "fat"], forKey: .init("required"))
            var props = items.nestedContainer(keyedBy: DynamicKey.self, forKey: .init("properties"))
            for (field, type) in [
                ("name", "STRING"), ("portion", "STRING"),
                ("calories", "NUMBER"), ("protein", "NUMBER"),
                ("carbs", "NUMBER"), ("fat", "NUMBER"),
            ] {
                var prop = props.nestedContainer(keyedBy: DynamicKey.self, forKey: .init(field))
                try prop.encode(type, forKey: .init("type"))
            }
        }
    }

    struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(_ string: String) { stringValue = string }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    let contents: [Content]
    let generationConfig: GenerationConfig

    enum CodingKeys: String, CodingKey {
        case contents
        case generationConfig = "generation_config"
    }

    init(imageData: Data) {
        contents = [Content(parts: [
            Part(inlineData: InlineData(mimeType: "image/jpeg", data: imageData.base64EncodedString())),
            Part(text: GeminiService.prompt.trimmingCharacters(in: .whitespacesAndNewlines)),
        ])]
        generationConfig = GenerationConfig(
            responseMimeType: "application/json",
            responseSchema: JSONSchema()
        )
    }
}

private struct GenerateResponse: Decodable {
    struct Candidate: Decodable {
        let content: Content?
    }
    struct Content: Decodable {
        let parts: [Part]?
    }
    struct Part: Decodable {
        let text: String?
    }
    let candidates: [Candidate]?
}
