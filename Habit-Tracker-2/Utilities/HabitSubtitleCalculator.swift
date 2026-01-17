//
//  HabitSubtitleCalculator.swift
//  Habit-Tracker-2
//

import Foundation

enum SubtitleSecondaryStyle: Equatable {
    case normal      // Gray color
    case violation   // Red color
    case streak      // Habit color
}

struct HabitSubtitle: Equatable {
    let goalText: String
    let secondaryText: String?
    let secondaryStyle: SubtitleSecondaryStyle

    var hasSecondary: Bool {
        secondaryText != nil
    }
}

struct HabitSubtitleCalculator {
    let habit: Habit
    let completionsByDate: [Date: Int]
    let calendar: Calendar
    let today: Date

    init(
        habit: Habit,
        completionsByDate: [Date: Int],
        calendar: Calendar = .current,
        today: Date = Calendar.current.startOfDay(for: Date())
    ) {
        self.habit = habit
        self.completionsByDate = completionsByDate
        self.calendar = calendar
        self.today = today
    }

    func calculate() -> HabitSubtitle {
        let goal = goalText()

        if let (secondPart, style) = streakOrLeftText() {
            return HabitSubtitle(goalText: goal, secondaryText: secondPart, secondaryStyle: style)
        }

        return HabitSubtitle(goalText: goal, secondaryText: nil, secondaryStyle: .normal)
    }

    // MARK: - Goal Text

    func goalText() -> String {
        let isQuit = habit.effectiveHabitType == .quit
        let prefix = isQuit ? "Max " : ""

        let hasLargerGoal = habit.streakGoalPeriod != .day

        if !hasLargerGoal {
            return "\(prefix)\(habit.completionsPerDay) a day"
        }

        let periodName = habit.streakGoalPeriod == .week ? "week" : "month"

        if habit.streakGoalType == .dayBasis {
            return "\(prefix)\(habit.streakGoalValue) days a \(periodName)"
        } else {
            return "\(prefix)\(habit.streakGoalValue) a \(periodName)"
        }
    }

    // MARK: - Streak or Left Text

    func streakOrLeftText() -> (String, SubtitleSecondaryStyle)? {
        let todayCount = completionsByDate[today] ?? 0
        let isQuit = habit.effectiveHabitType == .quit

        // Priority 1: Quit habit over daily limit (RED)
        if isQuit && todayCount > habit.completionsPerDay {
            if habit.effectiveIsBinary {
                return ("Failed today", .violation)
            } else {
                let over = todayCount - habit.completionsPerDay
                return ("\(over) over limit", .violation)
            }
        }

        // Priority 2: Non-binary build habit incomplete today
        if !isQuit {
            let isTodayComplete = todayCount >= habit.completionsPerDay

            if !isTodayComplete && !habit.effectiveIsBinary {
                let left = habit.completionsPerDay - todayCount
                return ("\(left) left today", .normal)
            }

            // Binary build habit incomplete - no second part
            if !isTodayComplete && habit.effectiveIsBinary {
                return nil
            }
        }

        // Priority 3: Check for streaks (today must be complete for build habits)
        if let streak = calculateStreak() {
            // Only show day streaks if > 1, but always show week/month streaks
            if streak.period == .day && streak.count <= 1 {
                // Skip showing "1 day streak"
            } else {
                let periodName: String
                switch streak.period {
                case .day:
                    periodName = "day"
                case .week:
                    periodName = "week"
                case .month:
                    periodName = "month"
                }
                return ("\(streak.count) \(periodName) streak", .streak)
            }
        }

        // Priority 4: Left this period (only for build habits with larger goals, when today is complete)
        if !isQuit && habit.streakGoalPeriod != .day {
            let isTodayComplete = todayCount >= habit.completionsPerDay
            if isTodayComplete, let left = leftThisPeriod() {
                if left > 0 {
                    let periodName = habit.streakGoalPeriod == .week ? "week" : "month"
                    return ("\(left) left this \(periodName)", .normal)
                }
            }
        }

        return nil
    }

    // MARK: - Streak Calculation

    func calculateStreak() -> (count: Int, period: StreakPeriod)? {
        switch habit.streakGoalPeriod {
        case .day:
            return calculateDailyStreak()
        case .week:
            return calculateWeeklyStreak()
        case .month:
            return calculateMonthlyStreak()
        }
    }

    private func calculateDailyStreak() -> (Int, StreakPeriod)? {
        var streakCount = 0
        var currentDate = today
        let isQuit = habit.effectiveHabitType == .quit

        while true {
            guard currentDate >= habit.effectiveStartDate else { break }

            let count = completionsByDate[currentDate] ?? 0
            let meetsGoal = isQuit
                ? count <= habit.completionsPerDay
                : count >= habit.completionsPerDay

            guard meetsGoal else { break }

            streakCount += 1

            guard let prevDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
            currentDate = prevDay
        }

        return streakCount > 0 ? (streakCount, .day) : nil
    }

    private func calculateWeeklyStreak() -> (Int, StreakPeriod)? {
        var streakCount = 0

        // Start from the week BEFORE current week
        guard let currentWeekStart = calendar.dateInterval(of: .weekOfYear, for: today)?.start,
              var checkWeekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekStart) else {
            return nil
        }

        while true {
            guard checkWeekStart >= habit.effectiveStartDate else { break }

            let weekMeetsGoal = evaluateWeek(startingAt: checkWeekStart)
            guard weekMeetsGoal else { break }

            streakCount += 1

            guard let prevWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: checkWeekStart) else { break }
            checkWeekStart = prevWeek
        }

        return streakCount > 0 ? (streakCount, .week) : nil
    }

    private func calculateMonthlyStreak() -> (Int, StreakPeriod)? {
        var streakCount = 0

        // Start from the month BEFORE current month
        let currentMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        guard var checkMonthStart = calendar.date(byAdding: .month, value: -1, to: currentMonthStart) else {
            return nil
        }

        while true {
            guard checkMonthStart >= habit.effectiveStartDate else { break }

            let monthMeetsGoal = evaluateMonth(startingAt: checkMonthStart)
            guard monthMeetsGoal else { break }

            streakCount += 1

            guard let prevMonth = calendar.date(byAdding: .month, value: -1, to: checkMonthStart) else { break }
            checkMonthStart = prevMonth
        }

        return streakCount > 0 ? (streakCount, .month) : nil
    }

    private func evaluateWeek(startingAt weekStart: Date) -> Bool {
        let totals = periodTotals(startDate: weekStart, lengthInDays: 7)
        return totals.meetsGoal(
            streakGoalValue: habit.streakGoalValue,
            streakGoalType: habit.streakGoalType,
            habitType: habit.effectiveHabitType
        )
    }

    private func evaluateMonth(startingAt monthStart: Date) -> Bool {
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return false
        }
        let totals = periodTotals(startDate: monthStart, lengthInDays: dayRange.count)
        return totals.meetsGoal(
            streakGoalValue: habit.streakGoalValue,
            streakGoalType: habit.streakGoalType,
            habitType: habit.effectiveHabitType
        )
    }

    private func periodTotals(startDate: Date, lengthInDays: Int) -> PeriodTotals {
        var dayCount = 0
        var valueCount = 0

        for offset in 0..<lengthInDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                continue
            }
            if date < habit.effectiveStartDate || date > today {
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

    // MARK: - Left This Period

    func leftThisPeriod() -> Int? {
        guard habit.streakGoalPeriod != .day else { return nil }

        let periodStart: Date

        if habit.streakGoalPeriod == .week {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
                return nil
            }
            periodStart = weekInterval.start
        } else {
            periodStart = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
        }

        let totals: PeriodTotals
        if habit.streakGoalPeriod == .week {
            totals = periodTotals(startDate: periodStart, lengthInDays: 7)
        } else {
            guard let dayRange = calendar.range(of: .day, in: .month, for: periodStart) else {
                return nil
            }
            totals = periodTotals(startDate: periodStart, lengthInDays: dayRange.count)
        }

        if habit.streakGoalType == .dayBasis {
            return max(0, habit.streakGoalValue - totals.dayCount)
        } else {
            return max(0, habit.streakGoalValue - totals.valueCount)
        }
    }
}
