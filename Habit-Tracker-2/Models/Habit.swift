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
final class Habit: Identifiable {
    var id: UUID
    var name: String
    var habitDescription: String?
    var icon: String  // SF Symbol name (e.g., "star.fill")
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
        icon: String = "star.fill",
        color: String = "#5C7CFA",
        completionsPerDay: Int = 1,
        streakGoalValue: Int = 1,
        streakGoalPeriod: StreakPeriod = .day,
        streakGoalType: StreakGoalType = .dayBasis,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.icon = icon
        self.color = color
        self.completionsPerDay = max(1, completionsPerDay)
        self.streakGoalValue = max(1, streakGoalValue)
        self.streakGoalPeriod = streakGoalPeriod
        self.streakGoalType = streakGoalType
        self.createdAt = createdAt
    }
}
