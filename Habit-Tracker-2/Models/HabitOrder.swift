//
//  HabitOrder.swift
//  Habit-Tracker-2
//

import Foundation
import SwiftData

@Model
final class HabitOrder: Identifiable {
    var id: UUID
    var orderIndex: Int

    var habit: Habit

    init(habit: Habit, orderIndex: Int) {
        self.id = UUID()
        self.habit = habit
        self.orderIndex = orderIndex
    }
}
