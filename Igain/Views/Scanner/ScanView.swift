//
//  ScanView.swift
//  Igain
//

import SwiftUI
import PhotosUI

/// AI food scanner: photo in → Gemini nutrition estimate out.
struct ScanView: View {
    @State private var viewModel = ScannerViewModel()
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let image = viewModel.selectedImage {
                    imagePreview(image)
                } else {
                    placeholder
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(Theme.negative)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                pickerButtons

                if viewModel.selectedImage != nil {
                    analyzeButton
                }

                Spacer()
            }
            .padding(.top)
            .background(Theme.background)
            .navigationTitle("AI Scanner")
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    viewModel.selectedImage = image
                }
                .ignoresSafeArea()
            }
            .sheet(isPresented: $viewModel.showResults) {
                ScanResultSheet(items: viewModel.results) {
                    viewModel.reset()
                }
            }
            .onChange(of: photoItem) {
                Task {
                    if let data = try? await photoItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectedImage = image
                        viewModel.errorMessage = nil
                    }
                    photoItem = nil
                }
            }
        }
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(Theme.accent)
            Text("Scan Your Meal")
                .font(.title2.bold())
            Text("Take a photo or pick one from your library.\nAI will identify the food and estimate calories & macros.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
        .cardStyle()
        .padding(.horizontal)
    }

    private func imagePreview(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button {
                    viewModel.reset()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .black.opacity(0.5))
                }
                .padding(10)
            }
            .padding(.horizontal)
    }

    private var pickerButtons: some View {
        HStack(spacing: 12) {
            if CameraPicker.isAvailable {
                Button {
                    showCamera = true
                } label: {
                    Label("Camera", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Photo Library", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .tint(Theme.accent)
        .padding(.horizontal)
    }

    private var analyzeButton: some View {
        Button {
            Task { await viewModel.analyze() }
        } label: {
            HStack {
                if viewModel.isAnalyzing {
                    ProgressView()
                        .tint(.white)
                    Text("Analyzing…")
                } else {
                    Image(systemName: "sparkles")
                    Text("Analyze with AI")
                }
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(Theme.accent)
        .disabled(viewModel.isAnalyzing)
        .padding(.horizontal)
    }
}

#Preview {
    ScanView()
        .modelContainer(for: [FoodEntry.self, UserProfile.self], inMemory: true)
}
