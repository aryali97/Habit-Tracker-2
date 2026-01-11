//
//  HabitGridView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct HabitGridView: View {
    let habit: Habit

    private let cellSize: CGFloat = 10
    private let cellSpacing: CGFloat = 2
    private let numberOfWeeks = 52
    private let daysInWeek = 7

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private var habitCreatedAt: Date {
        Calendar.current.startOfDay(for: habit.createdAt)
    }

    // Calculate the start date (52 weeks ago, aligned to Sunday)
    private var gridStartDate: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Find the Sunday of the current week
        let weekday = calendar.component(.weekday, from: today)
        let daysFromSunday = weekday - 1 // Sunday = 1
        let currentWeekSunday = calendar.date(byAdding: .day, value: -daysFromSunday, to: today)!

        // Go back 51 weeks to get 52 total weeks
        return calendar.date(byAdding: .weekOfYear, value: -(numberOfWeeks - 1), to: currentWeekSunday)!
    }

    // Build a lookup dictionary for completions by date
    private var completionsByDate: [Date: Int] {
        var dict: [Date: Int] = [:]
        let calendar = Calendar.current
        for completion in habit.completions {
            let dateKey = calendar.startOfDay(for: completion.date)
            dict[dateKey] = completion.count
        }
        return dict
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: cellSpacing) {
                    ForEach(0..<numberOfWeeks, id: \.self) { weekIndex in
                        WeekColumn(
                            weekIndex: weekIndex,
                            gridStartDate: gridStartDate,
                            completionsByDate: completionsByDate,
                            completionsPerDay: habit.completionsPerDay,
                            habitColor: habitColor,
                            habitCreatedAt: habitCreatedAt,
                            cellSize: cellSize,
                            cellSpacing: cellSpacing
                        )
                        .id(weekIndex)
                    }
                }
                .padding(.horizontal, 4)
            }
            .onAppear {
                // Scroll to the last week (current week) on appear
                proxy.scrollTo(numberOfWeeks - 1, anchor: .trailing)
            }
        }
    }
}

// MARK: - Week Column

struct WeekColumn: View {
    let weekIndex: Int
    let gridStartDate: Date
    let completionsByDate: [Date: Int]
    let completionsPerDay: Int
    let habitColor: Color
    let habitCreatedAt: Date
    let cellSize: CGFloat
    let cellSpacing: CGFloat

    private let daysInWeek = 7

    var body: some View {
        VStack(spacing: cellSpacing) {
            ForEach(0..<daysInWeek, id: \.self) { dayIndex in
                let date = dateForCell(weekIndex: weekIndex, dayIndex: dayIndex)
                let count = completionsByDate[date] ?? 0

                DayCell(
                    date: date,
                    count: count,
                    goal: completionsPerDay,
                    color: habitColor,
                    habitCreatedAt: habitCreatedAt,
                    size: cellSize
                )
            }
        }
    }

    private func dateForCell(weekIndex: Int, dayIndex: Int) -> Date {
        let calendar = Calendar.current
        let daysOffset = (weekIndex * daysInWeek) + dayIndex
        return calendar.date(byAdding: .day, value: daysOffset, to: gridStartDate)!
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let count: Int
    let goal: Int
    let color: Color
    let habitCreatedAt: Date
    let size: CGFloat

    private var today: Date {
        Calendar.current.startOfDay(for: Date())
    }

    private var isFuture: Bool {
        date > today
    }

    private var isBeforeHabitCreation: Bool {
        date < habitCreatedAt
    }

    // Three states: inactive (darkest), failed (medium), completed (brightest)
    private var opacity: Double {
        // Inactive: before habit creation OR future days
        if isBeforeHabitCreation || isFuture {
            return HabitOpacity.inactive
        }

        // Failed: after habit creation, in the past, but no completions
        if count == 0 {
            return HabitOpacity.failed
        }

        // Completed: has completions
        if count >= goal {
            return HabitOpacity.completed
        }

        // Partial completion: gradient based on progress
        let progress = Double(count) / Double(goal)
        return HabitOpacity.partial(progress: progress)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2.5)
            .fill(color.opacity(opacity))
            .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("Grid with completions") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(
        name: "Morning Run",
        emoji: "🏃",
        color: "#51CF66",
        completionsPerDay: 1
    )
    container.mainContext.insert(habit)

    // Add some sample completions
    let calendar = Calendar.current
    let today = Date()

    for dayOffset in [0, -1, -2, -3, -5, -7, -8, -10, -14, -15, -16] {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let completion = HabitCompletion(date: date, count: 1)
            completion.habit = habit
            container.mainContext.insert(completion)
        }
    }

    return HabitGridView(habit: habit)
        .padding()
        .background(AppColors.background)
        .modelContainer(container)
}

#Preview("Multi-completion grid") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)

    let habit = Habit(
        name: "Drink Water",
        emoji: "💧",
        color: "#339AF0",
        completionsPerDay: 8
    )
    container.mainContext.insert(habit)

    // Add sample completions with varying counts
    let calendar = Calendar.current
    let today = Date()

    let completionData: [(Int, Int)] = [
        (0, 6), (-1, 8), (-2, 4), (-3, 8), (-4, 2),
        (-5, 8), (-6, 7), (-7, 8), (-8, 3), (-9, 8)
    ]

    for (dayOffset, count) in completionData {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let completion = HabitCompletion(date: date, count: count)
            completion.habit = habit
            container.mainContext.insert(completion)
        }
    }

    return HabitGridView(habit: habit)
        .padding()
        .background(AppColors.background)
        .modelContainer(container)
}
