//
//  HabitSubtitleCalculatorTests.swift
//  Habit-Tracker-2Tests
//

import XCTest
@testable import Habit_Tracker_2

final class HabitSubtitleCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = 1  // Sunday
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }

    private func makeHabit(
        completionsPerDay: Int = 1,
        habitType: HabitType = .build,
        streakGoalPeriod: StreakPeriod = .day,
        streakGoalValue: Int? = nil,
        streakGoalType: StreakGoalType = .valueBasis,
        habitStartDate: Date? = nil
    ) -> Habit {
        Habit(
            name: "Test",
            completionsPerDay: completionsPerDay,
            habitType: habitType,
            streakGoalValue: streakGoalValue,
            streakGoalPeriod: streakGoalPeriod,
            streakGoalType: streakGoalType,
            habitStartDate: habitStartDate ?? date(2026, 1, 1)
        )
    }

    private func calculator(
        habit: Habit,
        completionsByDate: [Date: Int],
        today: Date
    ) -> HabitSubtitleCalculator {
        HabitSubtitleCalculator(
            habit: habit,
            completionsByDate: completionsByDate,
            calendar: calendar,
            today: today
        )
    }

    // MARK: - Goal Text Tests

    func testGoalText_buildDaily() {
        let habit = makeHabit(completionsPerDay: 8)
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "8 a day")
        XCTAssertEqual(calc.calculate().goalText, "8 a day")
    }

    func testGoalText_buildWeeklyDayBasis() {
        let habit = makeHabit(
            completionsPerDay: 1,
            streakGoalPeriod: .week,
            streakGoalValue: 5,
            streakGoalType: .dayBasis
        )
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "5 days a week")
    }

    func testGoalText_buildWeeklyValueBasis() {
        let habit = makeHabit(
            completionsPerDay: 60,
            streakGoalPeriod: .week,
            streakGoalValue: 150,
            streakGoalType: .valueBasis
        )
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "150 a week")
    }

    func testGoalText_buildMonthlyDayBasis() {
        let habit = makeHabit(
            completionsPerDay: 1,
            streakGoalPeriod: .month,
            streakGoalValue: 20,
            streakGoalType: .dayBasis
        )
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "20 days a month")
    }

    func testGoalText_buildMonthlyValueBasis() {
        let habit = makeHabit(
            completionsPerDay: 30,
            streakGoalPeriod: .month,
            streakGoalValue: 500,
            streakGoalType: .valueBasis
        )
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "500 a month")
    }

    func testGoalText_quitDaily() {
        let habit = makeHabit(completionsPerDay: 3, habitType: .quit)
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "Max 3 a day")
    }

    func testGoalText_quitWeeklyValueBasis() {
        let habit = makeHabit(
            completionsPerDay: 3,
            habitType: .quit,
            streakGoalPeriod: .week,
            streakGoalValue: 10,
            streakGoalType: .valueBasis
        )
        let calc = calculator(habit: habit, completionsByDate: [:], today: date(2026, 1, 15))

        XCTAssertEqual(calc.goalText(), "Max 10 a week")
    }

    // MARK: - Left Today Tests

    func testLeftToday_nonBinaryBuildIncomplete() {
        let habit = makeHabit(completionsPerDay: 8)
        let today = date(2026, 1, 15)
        let completions = [today: 3]
        let calc = calculator(habit: habit, completionsByDate: completions, today: today)

        let subtitle = calc.calculate()
        XCTAssertEqual(subtitle.secondaryText, "5 left today")
        XCTAssertEqual(subtitle.secondaryStyle, .normal)
    }

    func testLeftToday_binaryBuildIncomplete() {
        let habit = makeHabit(completionsPerDay: 1)
        let today = date(2026, 1, 15)
        let completions: [Date: Int] = [:]  // No completion today
        let calc = calculator(habit: habit, completionsByDate: completions, today: today)

        let subtitle = calc.calculate()
        // Binary incomplete should just show goal text, no secondary
        XCTAssertEqual(subtitle.goalText, "1 a day")
        XCTAssertNil(subtitle.secondaryText)
    }

    func testLeftToday_buildComplete() {
        let habit = makeHabit(completionsPerDay: 8)
        let today = date(2026, 1, 15)
        let completions = [today: 8]
        let calc = calculator(habit: habit, completionsByDate: completions, today: today)

        let subtitle = calc.calculate()
        // Complete today - should not show "left today"
        XCTAssertNotEqual(subtitle.secondaryText, "0 left today")
        if let secondary = subtitle.secondaryText {
            XCTAssertFalse(secondary.contains("left today"))
        }
    }

    // MARK: - Violation Tests

    func testViolation_quitBinaryOverLimit() {
        // Binary quit habit has completionsPerDay = 1 (minimum due to Habit init constraint)
        let habit = makeHabit(completionsPerDay: 1, habitType: .quit)
        let today = date(2026, 1, 15)
        let completions = [today: 2]  // 2 violations when limit is 1 = over limit
        let calc = calculator(habit: habit, completionsByDate: completions, today: today)

        let subtitle = calc.calculate()
        XCTAssertEqual(subtitle.secondaryText, "Failed today")
        XCTAssertEqual(subtitle.secondaryStyle, .violation)
    }

    func testViolation_quitNonBinaryOverLimit() {
        let habit = makeHabit(completionsPerDay: 3, habitType: .quit)
        let today = date(2026, 1, 15)
        let completions = [today: 5]  // 2 over the limit of 3
        let calc = calculator(habit: habit, completionsByDate: completions, today: today)

        let subtitle = calc.calculate()
        XCTAssertEqual(subtitle.secondaryText, "2 over limit")
        XCTAssertEqual(subtitle.secondaryStyle, .violation)
    }

    func testViolation_quitUnderLimit() {
        let habit = makeHabit(completionsPerDay: 3, habitType: .quit)
        let today = date(2026, 1, 15)
        let completions = [today: 2]  // Under limit
        let calc = calculator(habit: habit, completionsByDate: completions, today: today)

        let subtitle = calc.calculate()
        XCTAssertNotEqual(subtitle.secondaryStyle, .violation)
        if let secondary = subtitle.secondaryText {
            XCTAssertFalse(secondary.contains("over limit"))
            XCTAssertFalse(secondary.contains("Failed"))
        }
    }

    // MARK: - Streak Tests

    func testStreak_dailyConsecutive() {
        let habit = makeHabit(completionsPerDay: 1, habitStartDate: date(2026, 1, 1))
        let today = date(2026, 1, 10)

        // 6 consecutive days including today
        var completions: [Date: Int] = [:]
        for offset in 0..<6 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            completions[day] = 1
        }

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.secondaryText, "6 day streak")
        XCTAssertEqual(subtitle.secondaryStyle, .streak)
    }

    func testStreak_dailyOneDayNotShown() {
        // Day streaks of 1 should not be shown
        let habit = makeHabit(completionsPerDay: 1, habitStartDate: date(2026, 1, 1))
        let today = date(2026, 1, 10)

        // Only today complete (1 day streak)
        let completions = [today: 1]

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        // Should NOT show "1 day streak"
        XCTAssertNil(subtitle.secondaryText)
    }

    func testStreak_weeklyConsecutive() {
        let habit = makeHabit(
            completionsPerDay: 1,
            streakGoalPeriod: .week,
            streakGoalValue: 3,
            streakGoalType: .dayBasis,
            habitStartDate: date(2025, 12, 1)
        )
        let today = date(2026, 1, 15)  // Mid-January

        // Complete 3 days in each of the previous 3 weeks
        var completions: [Date: Int] = [:]
        for weekOffset in 1...3 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: calendar.dateInterval(of: .weekOfYear, for: today)!.start)!
            for dayOffset in 0..<3 {
                let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
                completions[day] = 1
            }
        }
        // Also complete today so we're not showing "left today"
        completions[today] = 1

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.secondaryText, "3 week streak")
        XCTAssertEqual(subtitle.secondaryStyle, .streak)
    }

    func testStreak_weeklyOneWeekShown() {
        // Week/month streaks of 1 SHOULD be shown (unlike day streaks)
        let habit = makeHabit(
            completionsPerDay: 1,
            streakGoalPeriod: .week,
            streakGoalValue: 3,
            streakGoalType: .dayBasis,
            habitStartDate: date(2025, 12, 1)
        )
        let today = date(2026, 1, 15)

        // Complete 3 days in just the previous week
        var completions: [Date: Int] = [:]
        let weekStart = calendar.date(byAdding: .weekOfYear, value: -1, to: calendar.dateInterval(of: .weekOfYear, for: today)!.start)!
        for dayOffset in 0..<3 {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart)!
            completions[day] = 1
        }
        completions[today] = 1

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.secondaryText, "1 week streak")
        XCTAssertEqual(subtitle.secondaryStyle, .streak)
    }

    func testStreak_monthlyConsecutive() {
        let habit = makeHabit(
            completionsPerDay: 1,
            streakGoalPeriod: .month,
            streakGoalValue: 10,
            streakGoalType: .dayBasis,
            habitStartDate: date(2025, 10, 1)
        )
        let today = date(2026, 1, 15)

        // Complete 10 days in November and December
        var completions: [Date: Int] = [:]
        for month in [11, 12] {  // November and December 2025
            let monthStart = date(2025, month, 1)
            for dayOffset in 0..<10 {
                let day = calendar.date(byAdding: .day, value: dayOffset, to: monthStart)!
                completions[day] = 1
            }
        }
        // Also complete today
        completions[today] = 1

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.secondaryText, "2 month streak")
        XCTAssertEqual(subtitle.secondaryStyle, .streak)
    }

    func testStreak_noneWhenBroken() {
        let habit = makeHabit(completionsPerDay: 1, habitStartDate: date(2026, 1, 1))
        let today = date(2026, 1, 10)

        // 3 consecutive days, then a gap, then more
        var completions: [Date: Int] = [:]
        completions[today] = 1
        completions[calendar.date(byAdding: .day, value: -1, to: today)!] = 1
        completions[calendar.date(byAdding: .day, value: -2, to: today)!] = 1
        // Skip day -3
        completions[calendar.date(byAdding: .day, value: -4, to: today)!] = 1

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        // Should have a 3 day streak (not counting the broken chain)
        XCTAssertEqual(subtitle.secondaryText, "3 day streak")
        XCTAssertEqual(subtitle.secondaryStyle, .streak)
    }

    // MARK: - Left This Period Tests

    func testLeftThisPeriod_weeklyNoStreak() {
        let habit = makeHabit(
            completionsPerDay: 60,
            streakGoalPeriod: .week,
            streakGoalValue: 150,
            streakGoalType: .valueBasis,
            habitStartDate: date(2026, 1, 1)
        )
        let today = date(2026, 1, 15)

        // Complete today's goal but not enough for week
        let completions: [Date: Int] = [today: 60]

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.secondaryText, "90 left this week")
        XCTAssertEqual(subtitle.secondaryStyle, .normal)
    }

    func testLeftThisPeriod_monthlyNoStreak() {
        let habit = makeHabit(
            completionsPerDay: 30,
            streakGoalPeriod: .month,
            streakGoalValue: 500,
            streakGoalType: .valueBasis,
            habitStartDate: date(2026, 1, 1)
        )
        let today = date(2026, 1, 15)

        // Complete 250 total this month
        var completions: [Date: Int] = [:]
        for offset in 0..<5 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            completions[day] = 50
        }

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.secondaryText, "250 left this month")
        XCTAssertEqual(subtitle.secondaryStyle, .normal)
    }

    func testLeftThisPeriod_dailyNoLargerGoal() {
        let habit = makeHabit(completionsPerDay: 8, habitStartDate: date(2026, 1, 1))
        let today = date(2026, 1, 15)
        let completions = [today: 8]

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        // No larger goal and only 1 day streak (not shown), so no secondary
        XCTAssertNil(subtitle.secondaryText)
    }

    // MARK: - Full Subtitle Format Tests

    func testSubtitle_fullFormat_buildWithStreak() {
        let habit = makeHabit(completionsPerDay: 1, habitStartDate: date(2026, 1, 1))
        let today = date(2026, 1, 10)

        var completions: [Date: Int] = [:]
        for offset in 0..<5 {
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            completions[day] = 1
        }

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.goalText, "1 a day")
        XCTAssertEqual(subtitle.secondaryText, "5 day streak")
        XCTAssertEqual(subtitle.secondaryStyle, .streak)
    }

    func testSubtitle_fullFormat_quitViolation() {
        let habit = makeHabit(completionsPerDay: 3, habitType: .quit)
        let today = date(2026, 1, 15)
        let completions = [today: 5]

        let calc = calculator(habit: habit, completionsByDate: completions, today: today)
        let subtitle = calc.calculate()

        XCTAssertEqual(subtitle.goalText, "Max 3 a day")
        XCTAssertEqual(subtitle.secondaryText, "2 over limit")
        XCTAssertEqual(subtitle.secondaryStyle, .violation)
    }
}
