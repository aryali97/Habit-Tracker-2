//
//  HabitGridView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct HabitGridView: View {
    let habit: Habit

    private let cellSize: CGFloat = 8
    private let cellSpacing: CGFloat = 2
    private let numberOfWeeks = 52
    private let daysInWeek = 7

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private var habitCreatedAt: Date {
        Calendar.current.startOfDay(for: habit.createdAt)
    }

    private var gridEndDate: Date {
        let totalDays = (numberOfWeeks * 7) - 1
        return Calendar.current.date(byAdding: .day, value: totalDays, to: gridStartDate)!
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

    private var monthlyGoalMetDates: Set<Date> {
        guard habit.streakGoalPeriod == .month else { return [] }
        let calendar = Calendar.current
        var metMonths: Set<Date> = []

        var current = calendar.date(from: calendar.dateComponents([.year, .month], from: gridStartDate))!
        if current < gridStartDate {
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        while current <= gridEndDate {
            if monthMeetsGoal(monthStart: current) {
                metMonths.insert(current)
            }
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        return metMonths
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 6) {
                    MonthHeaderView(
                        gridStartDate: gridStartDate,
                        numberOfWeeks: numberOfWeeks,
                        cellSize: cellSize,
                        cellSpacing: cellSpacing,
                        habitColor: habitColor,
                        highlightMonthlyGoals: habit.streakGoalPeriod == .month,
                        monthlyGoalMetDates: monthlyGoalMetDates
                    )

                    if habit.streakGoalPeriod == .week {
                        WeekGoalBarRow(
                            numberOfWeeks: numberOfWeeks,
                            cellSize: cellSize,
                            cellSpacing: cellSpacing,
                            habitColor: habitColor,
                            meetsGoalForWeek: { weekIndex in
                                weekMeetsGoal(weekIndex: weekIndex)
                            }
                        )
                    }

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
                }
                .padding(.horizontal, 4)
            }
            .onAppear {
                // Scroll to the last week (current week) on appear
                proxy.scrollTo(numberOfWeeks - 1, anchor: .trailing)
            }
        }
    }

    private func weekMeetsGoal(weekIndex: Int) -> Bool {
        let calendar = Calendar.current
        let weekStart = calendar.date(byAdding: .day, value: weekIndex * daysInWeek, to: gridStartDate)!
        let totals = periodTotals(startDate: weekStart, lengthInDays: daysInWeek)
        return totals.meetsGoal(streakGoalValue: habit.streakGoalValue, streakGoalType: habit.streakGoalType)
    }

    private func monthMeetsGoal(monthStart: Date) -> Bool {
        let calendar = Calendar.current
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return false
        }
        let totals = periodTotals(startDate: monthStart, lengthInDays: dayRange.count)
        return totals.meetsGoal(streakGoalValue: habit.streakGoalValue, streakGoalType: habit.streakGoalType)
    }

    private func periodTotals(startDate: Date, lengthInDays: Int) -> PeriodTotals {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var dayCount = 0
        var valueCount = 0

        for offset in 0..<lengthInDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                continue
            }
            if date < habitCreatedAt || date > today {
                continue
            }
            let count = completionsByDate[date] ?? 0
            if count > 0 {
                dayCount += 1
            }
            valueCount += count
        }

        return PeriodTotals(dayCount: dayCount, valueCount: valueCount)
    }
}

// MARK: - Month Header

struct MonthHeaderView: View {
    let gridStartDate: Date
    let numberOfWeeks: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let habitColor: Color
    let highlightMonthlyGoals: Bool
    let monthlyGoalMetDates: Set<Date>

    private var gridEndDate: Date {
        let totalDays = (numberOfWeeks * 7) - 1
        return Calendar.current.date(byAdding: .day, value: totalDays, to: gridStartDate)!
    }

    private var monthLabels: [(index: Int, label: String, monthStart: Date)] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        formatter.locale = Locale.current

        var labels: [(Int, String, Date)] = []
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: gridStartDate))!
        var current = startOfMonth
        if current < gridStartDate {
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        while current <= gridEndDate {
            let dayOffset = calendar.dateComponents([.day], from: gridStartDate, to: current).day ?? 0
            let weekIndex = min(max(dayOffset / 7, 0), numberOfWeeks - 1)
            let label = formatter.string(from: current).uppercased()
            labels.append((weekIndex, label, current))
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        return labels
    }

    var body: some View {
        let columnWidth = cellSize + cellSpacing
        let gridWidth = (CGFloat(numberOfWeeks - 1) * columnWidth) + cellSize

        ZStack(alignment: .topLeading) {
            ForEach(monthLabels, id: \.index) { item in
                Text(item.label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(
                        highlightMonthlyGoals && monthlyGoalMetDates.contains(item.monthStart)
                            ? habitColor
                            : Color.white.opacity(0.45)
                    )
                    .fixedSize()
                    .position(x: (CGFloat(item.index) * columnWidth) + (cellSize / 2), y: 6)
            }
        }
        .frame(width: gridWidth, height: 16, alignment: .leading)
    }
}

// MARK: - Weekly Goal Bar Row

struct WeekGoalBarRow: View {
    let numberOfWeeks: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let habitColor: Color
    let meetsGoalForWeek: (Int) -> Bool

    var body: some View {
        HStack(spacing: cellSpacing) {
            ForEach(0..<numberOfWeeks, id: \.self) { weekIndex in
                if meetsGoalForWeek(weekIndex) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(habitColor)
                        .frame(width: cellSize, height: 3)
                } else {
                    Color.clear
                        .frame(width: cellSize, height: 3)
                }
            }
        }
    }
}

struct PeriodTotals {
    let dayCount: Int
    let valueCount: Int

    func meetsGoal(streakGoalValue: Int, streakGoalType: StreakGoalType) -> Bool {
        switch streakGoalType {
        case .dayBasis:
            return dayCount >= streakGoalValue
        case .valueBasis:
            return valueCount >= streakGoalValue
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
        RoundedRectangle(cornerRadius: 2)
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
        icon: "figure.run",
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
        icon: "drop.fill",
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
