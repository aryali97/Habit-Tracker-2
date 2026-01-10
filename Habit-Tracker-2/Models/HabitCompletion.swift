//
//  HabitCompletion.swift
//  Habit-Tracker-2
//

import Foundation
import SwiftData

@Model
final class HabitCompletion {
    var id: UUID
    var date: Date
    var count: Int

    var habit: Habit?

    init(date: Date, count: Int = 1) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.count = max(0, count)
    }
}
