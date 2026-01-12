//
//  GoalIndicatorEvaluator.swift
//  Habit-Tracker-2
//

import Foundation

struct GoalIndicatorEvaluator {
    let habitCreatedAt: Date
    let completionsByDate: [Date: Int]
    let completionsPerDay: Int
    let streakGoalPeriod: StreakPeriod
    let streakGoalValue: Int
    let streakGoalType: StreakGoalType
    let gridStartDate: Date
    let daysInWeek: Int
    let today: Date
    let calendar: Calendar

    init(
        habitCreatedAt: Date,
        completionsByDate: [Date: Int],
        completionsPerDay: Int,
        streakGoalPeriod: StreakPeriod,
        streakGoalValue: Int,
        streakGoalType: StreakGoalType,
        gridStartDate: Date,
        daysInWeek: Int,
        today: Date = Calendar.current.startOfDay(for: Date()),
        calendar: Calendar = Calendar.current
    ) {
        self.habitCreatedAt = habitCreatedAt
        self.completionsByDate = completionsByDate
        self.completionsPerDay = completionsPerDay
        self.streakGoalPeriod = streakGoalPeriod
        self.streakGoalValue = streakGoalValue
        self.streakGoalType = streakGoalType
        self.gridStartDate = gridStartDate
        self.daysInWeek = daysInWeek
        self.today = today
        self.calendar = calendar
    }

    func weekQualifies(weekIndex: Int) -> Bool {
        weekMeetsGoal(weekIndex: weekIndex) || weekAllDaysCompleted(weekIndex: weekIndex)
    }

    func monthQualifies(monthStart: Date) -> Bool {
        monthMeetsGoal(monthStart: monthStart)
            || monthAllDaysCompleted(monthStart: monthStart)
            || monthAllWeeksMeetGoal(monthStart: monthStart)
    }

    private func weekMeetsGoal(weekIndex: Int) -> Bool {
        guard streakGoalPeriod == .week else {
            return false
        }
        let weekStart = calendar.date(byAdding: .day, value: weekIndex * daysInWeek, to: gridStartDate)!
        let totals = periodTotals(startDate: weekStart, lengthInDays: daysInWeek)
        return totals.meetsGoal(streakGoalValue: streakGoalValue, streakGoalType: streakGoalType)
    }

    private func weekAllDaysCompleted(weekIndex: Int) -> Bool {
        let weekStart = calendar.date(byAdding: .day, value: weekIndex * daysInWeek, to: gridStartDate)!
        var hasActiveDay = false

        for offset in 0..<daysInWeek {
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                continue
            }
            if date < habitCreatedAt {
                continue
            }
            hasActiveDay = true
            let count = completionsByDate[date] ?? 0
            if count < completionsPerDay {
                return false
            }
        }

        return hasActiveDay
    }

    private func monthMeetsGoal(monthStart: Date) -> Bool {
        guard streakGoalPeriod == .month else {
            return false
        }
        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return false
        }
        let totals = periodTotals(startDate: monthStart, lengthInDays: dayRange.count)
        return totals.meetsGoal(streakGoalValue: streakGoalValue, streakGoalType: streakGoalType)
    }

    private func monthAllDaysCompleted(monthStart: Date) -> Bool {
        guard streakGoalPeriod == .day else {
            return false
        }
        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return false
        }
        var hasActiveDay = false

        for offset in 0..<monthRange.count {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else {
                continue
            }
            if date < habitCreatedAt {
                continue
            }
            hasActiveDay = true
            let count = completionsByDate[date] ?? 0
            if count < completionsPerDay {
                return false
            }
        }

        return hasActiveDay
    }

    private func monthAllWeeksMeetGoal(monthStart: Date) -> Bool {
        guard streakGoalPeriod == .week else {
            return false
        }
        guard let monthRange = calendar.range(of: .day, in: .month, for: monthStart) else {
            return false
        }
        let monthEnd = calendar.date(byAdding: .day, value: monthRange.count - 1, to: monthStart)!
        guard var weekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
            return false
        }
        var hasActiveWeek = false

        while weekStart <= monthEnd {
            let weekEnd = calendar.date(byAdding: .day, value: daysInWeek - 1, to: weekStart)!
            let segmentStart = max(weekStart, monthStart)
            let segmentEnd = min(weekEnd, monthEnd)
            let length = (calendar.dateComponents([.day], from: segmentStart, to: segmentEnd).day ?? 0) + 1

            let totalsResult = periodTotalsIncludingFuture(startDate: segmentStart, lengthInDays: length)
            if totalsResult.activeDayCount > 0 {
                hasActiveWeek = true
                if !totalsResult.totals.meetsGoal(
                    streakGoalValue: streakGoalValue,
                    streakGoalType: streakGoalType
                ) {
                    return false
                }
            }

            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }

        return hasActiveWeek
    }

    private func periodTotals(startDate: Date, lengthInDays: Int) -> PeriodTotals {
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

    private func periodTotalsIncludingFuture(startDate: Date, lengthInDays: Int) -> (totals: PeriodTotals, activeDayCount: Int) {
        var dayCount = 0
        var valueCount = 0
        var activeDayCount = 0

        for offset in 0..<lengthInDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else {
                continue
            }
            if date < habitCreatedAt {
                continue
            }
            activeDayCount += 1
            let count = completionsByDate[date] ?? 0
            if count > 0 {
                dayCount += 1
            }
            valueCount += count
        }

        return (PeriodTotals(dayCount: dayCount, valueCount: valueCount), activeDayCount)
    }
}
