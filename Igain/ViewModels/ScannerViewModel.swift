//
//  ScannerViewModel.swift
//  Igain
//

import SwiftUI
import Observation

@Observable
@MainActor
final class ScannerViewModel {
    var selectedImage: UIImage?
    var isAnalyzing = false
    var results: [ScannedFoodItem] = []
    var errorMessage: String?
    var showResults = false

    private let service = GeminiService()

    func analyze() async {
        guard let image = selectedImage,
              let jpeg = compressed(image) else { return }

        isAnalyzing = true
        errorMessage = nil
        defer { isAnalyzing = false }

        do {
            results = try await service.analyze(imageData: jpeg)
            showResults = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reset() {
        selectedImage = nil
        results = []
        errorMessage = nil
        showResults = false
    }

    /// Downscale + JPEG-compress so the request stays well under Gemini's inline limit.
    private func compressed(_ image: UIImage, maxDimension: CGFloat = 1024) -> Data? {
        let size = image.size
        let scale = min(1, maxDimension / max(size.width, size.height))
        let target = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: target)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return resized.jpegData(compressionQuality: 0.7)
    }
}
