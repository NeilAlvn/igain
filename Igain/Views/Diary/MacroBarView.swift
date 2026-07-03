//
//  MacroBarView.swift
//  Igain
//

import SwiftUI

/// Compact labeled progress bar for one macro, Cronometer-style.
struct MacroBarView: View {
    let label: String
    let consumed: Double
    let target: Double
    let color: Color

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(consumed)) / \(Int(target)) g")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.18))
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                        .animation(.easeOut(duration: 0.5), value: progress)
                }
            }
            .frame(height: 7)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        MacroBarView(label: "Protein", consumed: 92, target: 165, color: Theme.protein)
        MacroBarView(label: "Carbs", consumed: 180, target: 220, color: Theme.carbs)
        MacroBarView(label: "Fat", consumed: 51, target: 73, color: Theme.fat)
    }
    .padding()
}
