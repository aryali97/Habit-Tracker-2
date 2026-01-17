//
//  GoalIndicatorEvaluatorTests.swift
//  Habit-Tracker-2Tests
//

import XCTest
@testable import Habit_Tracker_2

final class GoalIndicatorEvaluatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func startOfWeek(for date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)!.start
    }

    private func evaluator(
        habitStartDate: Date,
        completionsByDate: [Date: Int],
        completionsPerDay: Int,
        habitType: HabitType = .build,
        streakGoalPeriod: StreakPeriod,
        streakGoalValue: Int,
        streakGoalType: StreakGoalType,
        gridStartDate: Date,
        today: Date
    ) -> GoalIndicatorEvaluator {
        GoalIndicatorEvaluator(
            habitStartDate: habitStartDate,
            completionsByDate: completionsByDate,
            completionsPerDay: completionsPerDay,
            habitType: habitType,
            streakGoalPeriod: streakGoalPeriod,
            streakGoalValue: streakGoalValue,
            streakGoalType: streakGoalType,
            gridStartDate: gridStartDate,
            daysInWeek: 7,
            today: today,
            calendar: calendar
        )
    }

    func testWeekGoalMetShowsIndicator() {
        let today = date(2026, 1, 7)
        let weekStart = startOfWeek(for: today)
        var completions: [Date: Int] = [:]

        for dayOffset in 0..<3 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            completions[calendar.startOfDay(for: day)] = 1
        }

        let evaluator = evaluator(
            habitStartDate: weekStart,
            completionsByDate: completions,
            completionsPerDay: 1,
            streakGoalPeriod: .week,
            streakGoalValue: 3,
            streakGoalType: .dayBasis,
            gridStartDate: weekStart,
            today: today
        )

        XCTAssertTrue(evaluator.weekQualifies(weekIndex: 0))
    }

    func testWeekAllDaysCompletedIncludesFutureDays() {
        let today = date(2026, 1, 7)
        let weekStart = startOfWeek(for: today)
        var completions: [Date: Int] = [:]

        completions[calendar.startOfDay(for: weekStart)] = 1

        let evaluator = evaluator(
            habitStartDate: weekStart,
            completionsByDate: completions,
            completionsPerDay: 1,
            streakGoalPeriod: .day,
            streakGoalValue: 1,
            streakGoalType: .dayBasis,
            gridStartDate: weekStart,
            today: today
        )

        XCTAssertFalse(evaluator.weekQualifies(weekIndex: 0))
    }

    func testMonthIndicatorDailyAllDaysCompleted() {
        let monthStart = date(2026, 1, 1)
        let today = date(2026, 1, 20)
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        var completions: [Date: Int] = [:]

        for offset in 0..<range.count {
            let day = calendar.date(byAdding: .day, value: offset, to: monthStart)!
            completions[calendar.startOfDay(for: day)] = 1
        }

        let evaluator = evaluator(
            habitStartDate: monthStart,
            completionsByDate: completions,
            completionsPerDay: 1,
            streakGoalPeriod: .day,
            streakGoalValue: 1,
            streakGoalType: .dayBasis,
            gridStartDate: startOfWeek(for: monthStart),
            today: today
        )

        XCTAssertTrue(evaluator.monthQualifies(monthStart: monthStart))
    }

    func testMonthIndicatorWeeklyAllWeeksMetIncludesPartials() {
        let monthStart = date(2026, 1, 1)
        let today = date(2026, 1, 20)
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let monthEnd = calendar.date(byAdding: .day, value: range.count - 1, to: monthStart)!
        var completions: [Date: Int] = [:]

        var weekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)!.start
        while weekStart <= monthEnd {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let segmentStart = max(weekStart, monthStart)
            let segmentEnd = min(weekEnd, monthEnd)
            let segmentLength = (calendar.dateComponents([.day], from: segmentStart, to: segmentEnd).day ?? 0) + 1

            for dayOffset in 0..<min(2, segmentLength) {
                let day = calendar.date(byAdding: .day, value: dayOffset, to: segmentStart)!
                completions[calendar.startOfDay(for: day)] = 1
            }

            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }

        let evaluator = evaluator(
            habitStartDate: monthStart,
            completionsByDate: completions,
            completionsPerDay: 1,
            streakGoalPeriod: .week,
            streakGoalValue: 2,
            streakGoalType: .dayBasis,
            gridStartDate: startOfWeek(for: monthStart),
            today: today
        )

        XCTAssertTrue(evaluator.monthQualifies(monthStart: monthStart))
    }

    func testMonthIndicatorWeeklyMissingWeekFails() {
        let monthStart = date(2026, 1, 1)
        let today = date(2026, 1, 20)
        let range = calendar.range(of: .day, in: .month, for: monthStart)!
        let monthEnd = calendar.date(byAdding: .day, value: range.count - 1, to: monthStart)!
        var completions: [Date: Int] = [:]

        var weekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)!.start
        var skippedFirstWeek = false
        while weekStart <= monthEnd {
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!
            let segmentStart = max(weekStart, monthStart)
            let segmentEnd = min(weekEnd, monthEnd)
            let segmentLength = (calendar.dateComponents([.day], from: segmentStart, to: segmentEnd).day ?? 0) + 1

            if skippedFirstWeek {
                for dayOffset in 0..<min(2, segmentLength) {
                    let day = calendar.date(byAdding: .day, value: dayOffset, to: segmentStart)!
                    completions[calendar.startOfDay(for: day)] = 1
                }
            } else {
                skippedFirstWeek = true
            }

            weekStart = calendar.date(byAdding: .weekOfYear, value: 1, to: weekStart)!
        }

        let evaluator = evaluator(
            habitStartDate: monthStart,
            completionsByDate: completions,
            completionsPerDay: 1,
            streakGoalPeriod: .week,
            streakGoalValue: 2,
            streakGoalType: .dayBasis,
            gridStartDate: startOfWeek(for: monthStart),
            today: today
        )

        XCTAssertFalse(evaluator.monthQualifies(monthStart: monthStart))
    }

    func testMonthGoalMetShowsIndicator() {
        let monthStart = date(2026, 1, 1)
        let today = date(2026, 1, 15)
        var completions: [Date: Int] = [:]

        for offset in 0..<10 {
            let day = calendar.date(byAdding: .day, value: offset, to: monthStart)!
            completions[calendar.startOfDay(for: day)] = 1
        }

        let evaluator = evaluator(
            habitStartDate: monthStart,
            completionsByDate: completions,
            completionsPerDay: 1,
            streakGoalPeriod: .month,
            streakGoalValue: 10,
            streakGoalType: .dayBasis,
            gridStartDate: startOfWeek(for: monthStart),
            today: today
        )

        XCTAssertTrue(evaluator.monthQualifies(monthStart: monthStart))
    }
}
