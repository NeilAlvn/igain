//
//  BarcodeScannerView.swift
//  Igain
//

import SwiftUI
import VisionKit

/// Live barcode scanning on device; manual code entry fallback in the simulator
/// (which has no camera) or when scanning is unsupported.
struct BarcodeScannerView: View {
    let onScan: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var manualCode = ""
    @State private var hasReported = false

    private var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    var body: some View {
        NavigationStack {
            VStack {
                if scannerAvailable {
                    BarcodeScannerRepresentable(onScan: report)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding()
                } else {
                    ContentUnavailableView(
                        "Camera Unavailable",
                        systemImage: "camera.on.rectangle",
                        description: Text("Barcode scanning needs a real device. Enter the barcode number below instead.")
                    )
                }

                HStack {
                    TextField("Enter barcode number", text: $manualCode)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                    Button("Look Up") {
                        report(manualCode.trimmingCharacters(in: .whitespaces))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .disabled(manualCode.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
            }
            .navigationTitle("Scan Barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    /// Forwards a scanned/typed code exactly once, even if the scanner
    /// or button fires again before the sheet finishes dismissing.
    private func report(_ code: String) {
        guard !hasReported else { return }
        hasReported = true
        onScan(code)
    }
}

private struct BarcodeScannerRepresentable: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .fast,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasScanned else { return }
            for item in addedItems {
                if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                    hasScanned = true
                    dataScanner.stopScanning()
                    onScan(payload)
                    break
                }
            }
        }
    }
}
