//
//  Habit.swift
//  Habit-Tracker-2
//

import Foundation
import SwiftData

enum StreakPeriod: String, Codable, CaseIterable {
    case day
    case week
}

enum StreakGoalType: String, Codable, CaseIterable {
    case dayBasis
    case valueBasis
}

@Model
final class Habit {
    var id: UUID
    var name: String
    var habitDescription: String?
    var emoji: String
    var color: String
    var completionsPerDay: Int
    var streakGoalValue: Int
    var streakGoalPeriod: StreakPeriod
    var streakGoalType: StreakGoalType
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit)
    var completions: [HabitCompletion] = []

    init(
        name: String,
        habitDescription: String? = nil,
        emoji: String = "⭐️",
        color: String = "#5C7CFA",
        completionsPerDay: Int = 1,
        streakGoalValue: Int = 1,
        streakGoalPeriod: StreakPeriod = .day,
        streakGoalType: StreakGoalType = .dayBasis
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.emoji = emoji
        self.color = color
        self.completionsPerDay = max(1, completionsPerDay)
        self.streakGoalValue = max(1, streakGoalValue)
        self.streakGoalPeriod = streakGoalPeriod
        self.streakGoalType = streakGoalType
        self.createdAt = Date()
    }
}
