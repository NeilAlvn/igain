//
//  WaterTrackerCard.swift
//  Igain
//

import SwiftUI
import SwiftData

/// Cronometer-style water tracker: a row of 8 cups, tap to fill.
/// Tapping the last filled cup empties it again (undo).
struct WaterTrackerCard: View {
    static let targetCups = 8
    static let mlPerCup = 250

    @Environment(\.modelContext) private var context
    @Query private var days: [WaterDay]

    private let day: Date

    init(date: Date) {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        day = start
        _days = Query(filter: #Predicate<WaterDay> { $0.date >= start && $0.date < end })
    }

    private var cups: Int { days.first?.cups ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Water", systemImage: "drop.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.water)
                Spacer()
                Text("\(cups) of \(Self.targetCups) cups · \(cups * Self.mlPerCup) ml")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            HStack(spacing: 8) {
                ForEach(0..<Self.targetCups, id: \.self) { index in
                    CupView(
                        filled: index < cups,
                        isNext: index == cups
                    )
                    .onTapGesture { tapCup(at: index) }
                }
            }
            .frame(height: 46)
        }
        .cardStyle()
    }

    private func tapCup(at index: Int) {
        // Tapping the last filled cup undoes it; any other cup fills up to it.
        let newCount = (index + 1 == cups) ? index : index + 1
        withAnimation(.snappy) {
            if let record = days.first {
                record.cups = newCount
            } else {
                context.insert(WaterDay(date: day, cups: newCount))
            }
        }
    }
}

/// A single tappable water cup (rounded trapezoid glass).
private struct CupView: View {
    let filled: Bool
    let isNext: Bool

    var body: some View {
        ZStack {
            CupShape()
                .fill(
                    filled
                        ? AnyShapeStyle(
                            LinearGradient(
                                colors: [Theme.water.opacity(0.75), Theme.water],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        : AnyShapeStyle(Theme.water.opacity(0.08))
                )
            CupShape()
                .stroke(Theme.water.opacity(filled ? 0.9 : 0.35), lineWidth: 1.5)

            if filled {
                Image(systemName: "drop.fill")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.85))
            } else if isNext {
                Image(systemName: "plus")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.water.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityLabel(filled ? "Filled cup" : "Empty cup")
    }
}

/// Water-glass silhouette: slightly tapered with a rounded base.
private struct CupShape: Shape {
    func path(in rect: CGRect) -> Path {
        let taper = rect.width * 0.16
        let base = rect.maxY - rect.height * 0.08
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - taper, y: base))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + taper, y: base),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.06)
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    WaterTrackerCard(date: .now)
        .padding()
        .modelContainer(for: [WaterDay.self], inMemory: true)
}
