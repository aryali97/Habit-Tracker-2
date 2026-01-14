//
//  Habit.swift
//  Habit-Tracker-2
//

import Foundation
import SwiftData

enum StreakPeriod: String, Codable, CaseIterable {
    case day
    case week
    case month
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
        streakGoalValue: Int? = nil,
        streakGoalPeriod: StreakPeriod? = nil,
        streakGoalType: StreakGoalType? = nil,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.habitDescription = habitDescription
        self.icon = icon
        self.color = color
        let validCompletionsPerDay = max(1, completionsPerDay)
        self.completionsPerDay = validCompletionsPerDay
        // Default to daily goal matching completionsPerDay
        self.streakGoalValue = streakGoalValue ?? validCompletionsPerDay
        self.streakGoalPeriod = streakGoalPeriod ?? .day
        self.streakGoalType = streakGoalType ?? .valueBasis
        self.createdAt = createdAt
    }
}
