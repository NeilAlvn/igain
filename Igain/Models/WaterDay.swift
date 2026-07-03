//
//  WaterDay.swift
//  Igain
//

import Foundation
import SwiftData

/// One day's water intake, counted in cups (250 ml each).
@Model
final class WaterDay {
    var date: Date
    var cups: Int

    init(date: Date = .now, cups: Int = 0) {
        self.date = Calendar.current.startOfDay(for: date)
        self.cups = cups
    }
}
