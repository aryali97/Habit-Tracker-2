//
//  HabitGridView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct CompletionPickerDateWrapper: Identifiable {
    let id = UUID()
    let date: Date
}

struct HabitGridView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @State private var showingMonthlyView = false
    @State private var completionPickerDate: CompletionPickerDateWrapper?
    @State private var restoreMonthlyViewAfterPicker = false

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

    private var goalEvaluator: GoalIndicatorEvaluator {
        return GoalIndicatorEvaluator(
            habitCreatedAt: habitCreatedAt,
            completionsByDate: completionsByDate,
            completionsPerDay: habit.completionsPerDay,
            habitType: habit.effectiveHabitType,
            streakGoalPeriod: habit.streakGoalPeriod,
            streakGoalValue: habit.streakGoalValue,
            streakGoalType: habit.streakGoalType,
            gridStartDate: gridStartDate,
            daysInWeek: daysInWeek
        )
    }

    private var monthlyGoalMetDates: Set<Date> {
        let calendar = Calendar.current
        var metMonths: Set<Date> = []

        var current = calendar.date(from: calendar.dateComponents([.year, .month], from: gridStartDate))!
        if current < gridStartDate {
            current = calendar.date(byAdding: .month, value: 1, to: current)!
        }

        while current <= gridEndDate {
            if goalEvaluator.monthQualifies(monthStart: current) {
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
                        monthlyGoalMetDates: monthlyGoalMetDates
                    )

                    WeekGoalBarRow(
                        numberOfWeeks: numberOfWeeks,
                        cellSize: cellSize,
                        cellSpacing: cellSpacing,
                        habitColor: habitColor,
                        meetsGoalForWeek: { weekIndex in
                            return goalEvaluator.weekQualifies(weekIndex: weekIndex)
                        }
                    )

                    HStack(spacing: cellSpacing) {
                        ForEach(0..<numberOfWeeks, id: \.self) { weekIndex in
                            WeekColumn(
                                weekIndex: weekIndex,
                                gridStartDate: gridStartDate,
                                completionsByDate: completionsByDate,
                                completionsPerDay: habit.completionsPerDay,
                                habitColor: habitColor,
                                habitCreatedAt: habitCreatedAt,
                                habitType: habit.effectiveHabitType,
                                cellSize: cellSize,
                                cellSpacing: cellSpacing
                            )
                            .id(weekIndex)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingMonthlyView = true
            }
            .onAppear {
                // Scroll to the last week (current week) on appear
                proxy.scrollTo(numberOfWeeks - 1, anchor: .trailing)
            }
        }
        .sheet(isPresented: $showingMonthlyView) {
            HabitMonthlyViewSheet(
                habit: habit,
                onShowCompletionPicker: { date in
                    showCompletionPicker(for: date)
                }
            )
        }
        .sheet(item: $completionPickerDate, onDismiss: handleCompletionPickerDismiss) { wrapper in
            CompletionPickerSheet(
                habit: habit,
                currentCount: completionCount(for: wrapper.date),
                title: completionPickerTitle(for: wrapper.date),
                onSave: { newCount in
                    setCompletionCount(newCount, for: wrapper.date)
                }
            )
            .presentationDetents([.medium])
        }
    }

    private func showCompletionPicker(for date: Date) {
        restoreMonthlyViewAfterPicker = showingMonthlyView
        showingMonthlyView = false
        // Use a small delay to ensure monthly view dismisses first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let startOfDate = Calendar.current.startOfDay(for: date)
            completionPickerDate = CompletionPickerDateWrapper(date: startOfDate)
        }
    }

    private func handleCompletionPickerDismiss() {
        if restoreMonthlyViewAfterPicker {
            showingMonthlyView = true
            restoreMonthlyViewAfterPicker = false
        }
    }

    private func completionPickerTitle(for date: Date) -> String {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())

        if calendar.isDate(startOfDate, inSameDayAs: today) {
            return "Today"
        }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(startOfDate, inSameDayAs: yesterday) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        formatter.locale = Locale.current
        return formatter.string(from: startOfDate).uppercased()
    }

    private func completionCount(for date: Date) -> Int {
        habit.completions.first { Calendar.current.isDate($0.date, inSameDayAs: date) }?.count ?? 0
    }

    private func setCompletionCount(_ count: Int, for date: Date) {
        let startOfDate = Calendar.current.startOfDay(for: date)

        if let completion = habit.completions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: startOfDate) }) {
            completion.count = count
        } else if count > 0 {
            let completion = HabitCompletion(date: startOfDate, count: count)
            completion.habit = habit
            modelContext.insert(completion)

            // Update habit start date if this completion is earlier
            if startOfDate < Calendar.current.startOfDay(for: habit.createdAt) {
                habit.createdAt = startOfDate
            }
        }

        Haptics.notification(.success)
        saveContext()
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save habit completion: \(error)")
        }
    }

}

// MARK: - Month Header

struct MonthHeaderView: View {
    let gridStartDate: Date
    let numberOfWeeks: Int
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let habitColor: Color
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
            ForEach(monthLabels.indices, id: \.self) { labelIndex in
                let item = monthLabels[labelIndex]
                let isLastMonth = labelIndex == monthLabels.count - 1
                let columnStartX = CGFloat(item.index) * columnWidth

                // Determine display label, truncating last month if needed
                let displayLabel: String = {
                    if isLastMonth {
                        // Calculate remaining space from this column to grid end
                        let remainingWidth = gridWidth - columnStartX
                        // Rough estimate: each character is about 6 points at size 10 semibold
                        let estimatedLabelWidth = CGFloat(item.label.count) * 6.0

                        if estimatedLabelWidth > remainingWidth {
                            return String(item.label.prefix(1)) + "."
                        }
                    }
                    return item.label
                }()

                Text(displayLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        monthlyGoalMetDates.contains(item.monthStart)
                            ? habitColor
                            : Color.white.opacity(0.45)
                    )
                    .fixedSize()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .offset(x: columnStartX, y: 0)
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

    func meetsGoal(streakGoalValue: Int, streakGoalType: StreakGoalType, habitType: HabitType) -> Bool {
        if habitType == .quit {
            // QUIT LOGIC: violations must be UNDER limit
            switch streakGoalType {
            case .dayBasis:
                return dayCount <= streakGoalValue  // Days within limit
            case .valueBasis:
                return valueCount <= streakGoalValue  // Total violations under limit
            }
        } else {
            // BUILD LOGIC: completions must be OVER goal
            switch streakGoalType {
            case .dayBasis:
                return dayCount >= streakGoalValue
            case .valueBasis:
                return valueCount >= streakGoalValue
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
    let habitType: HabitType
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
                    habitType: habitType,
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
    let habitType: HabitType
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

        if habitType == .quit {
            // QUIT LOGIC: inverted

            // Perfect day: 0 violations
            if count == 0 {
                return HabitOpacity.completed
            }

            // Over limit: same as failed
            if count > goal {
                return HabitOpacity.failed
            }

            // At limit: dimmer
            if count == goal {
                return HabitOpacity.partialMin
            }

            // Partial violations: fewer violations = brighter (inverted progress)
            let progress = 1.0 - (Double(count) / Double(goal))
            return HabitOpacity.partial(progress: progress)

        } else {
            // BUILD LOGIC: existing

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
        completionsPerDay: 1,
        streakGoalValue: 1,
        streakGoalType: .dayBasis
    )
    container.mainContext.insert(habit)

    // Add some sample completions
    let calendar = Calendar.current
    let today = Date()
    var addedDates: Set<Date> = []

    for dayOffset in [0, -1, -2, -3, -5, -7, -8, -10, -14, -15, -16] {
        if let date = calendar.date(byAdding: .day, value: dayOffset, to: today) {
            let dateKey = calendar.startOfDay(for: date)
            if addedDates.contains(dateKey) {
                continue
            }
            let completion = HabitCompletion(date: date, count: 1)
            completion.habit = habit
            container.mainContext.insert(completion)
            addedDates.insert(dateKey)
        }
    }

    if let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today)),
       let monthDayRange = calendar.range(of: .day, in: .month, for: monthStart),
       let monthEnd = calendar.date(byAdding: .day, value: monthDayRange.count - 1, to: monthStart),
       var weekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start {
        while weekStart <= monthEnd {
            let dateKey = calendar.startOfDay(for: weekStart)
            if !addedDates.contains(dateKey) {
                let completion = HabitCompletion(date: weekStart, count: 1)
                completion.habit = habit
                container.mainContext.insert(completion)
                addedDates.insert(dateKey)
            }
            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
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
