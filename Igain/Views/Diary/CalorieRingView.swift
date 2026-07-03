//
//  CalorieRingView.swift
//  Igain
//

import SwiftUI

/// Cronometer-style "calories remaining" ring.
struct CalorieRingView: View {
    let consumed: Double
    let target: Double

    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(consumed / target, 1.0)
    }

    private var remaining: Double { target - consumed }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.calorieRing.opacity(0.15), lineWidth: 14)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    remaining >= 0 ? Theme.calorieRing : Theme.negative,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: progress)

            VStack(spacing: 2) {
                Text("\(Int(abs(remaining)))")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())
                Text(remaining >= 0 ? "kcal left" : "kcal over")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    CalorieRingView(consumed: 1450, target: 2200)
        .frame(width: 160, height: 160)
        .padding()
}
