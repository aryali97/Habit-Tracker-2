//
//  HabitMonthlyViewSheet.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData
import UIKit

struct HabitMonthlyViewSheet: View {
    let habit: Habit
    let onShowCompletionPicker: (Date) -> Void
    @State private var monthOffset: Int = 0
    @Environment(\.modelContext) private var modelContext

    init(habit: Habit, onShowCompletionPicker: @escaping (Date) -> Void) {
        self.habit = habit
        self.onShowCompletionPicker = onShowCompletionPicker
    }

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private var habitCreatedAt: Date {
        Calendar.current.startOfDay(for: habit.createdAt)
    }

    private var completionsByDate: [Date: Int] {
        var dict: [Date: Int] = [:]
        let calendar = Calendar.current
        for completion in habit.completions {
            let dateKey = calendar.startOfDay(for: completion.date)
            dict[dateKey] = completion.count
        }
        return dict
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: monthStart).uppercased()
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        return formatter.shortWeekdaySymbols.map { $0.prefix(3).uppercased() }
    }

    private var gridDates: [Date] {
        let calendar = Calendar.current
        guard let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
            return []
        }

        return (0..<42).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: firstWeekStart)
        }
    }

    private var currentMonthStart: Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return calendar.date(from: calendar.dateComponents([.year, .month], from: today)) ?? today
    }

    private var monthStart: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: currentMonthStart) ?? currentMonthStart
    }

    private var monthOffsets: [Int] {
        let maxPastMonths = 24
        return Array((-maxPastMonths)...0)
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: habit.icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(habitColor)
                    .frame(width: 36, height: 36)
                    .background(habitColor.opacity(HabitOpacity.inactive))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)

                    if let description = habit.habitDescription, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1)
                .padding(.horizontal, 16)

            TabView(selection: $monthOffset) {
                ForEach(monthOffsets, id: \.self) { offset in
                    MonthCalendarPage(
                        monthStart: Calendar.current.date(byAdding: .month, value: offset, to: currentMonthStart)
                            ?? currentMonthStart,
                        weekdaySymbols: weekdaySymbols,
                        habitCreatedAt: habitCreatedAt,
                        completionsByDate: completionsByDate,
                        habitColor: habitColor,
                        onSelectDate: { date in
                            handleDateTap(date)
                        }
                    )
                    .tag(offset)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AppColors.cardBackground)
        .presentationBackground(AppColors.cardBackground)
        .presentationDetents([.height(detentHeight)])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    private var detentHeight: CGFloat {
        let headerPaddingTop: CGFloat = 12
        let headerRowHeight: CGFloat = 36
        let dividerHeight: CGFloat = 1
        let titleHeight: CGFloat = 18
        let calendarTitleSpacing: CGFloat = 16
        let weekdayHeight: CGFloat = 13
        let verticalSpacing: CGFloat = 16
        let rowHeight: CGFloat = 42
        let rowSpacing: CGFloat = 8
        let bottomPadding: CGFloat = 16
        let rows: CGFloat = 6
        let headerBlock = headerPaddingTop
            + headerRowHeight
            + verticalSpacing
            + dividerHeight
            + verticalSpacing
        let gridBlock = titleHeight
            + calendarTitleSpacing
            + weekdayHeight
            + (rows * rowHeight)
            + ((rows - 1) * rowSpacing)
            + bottomPadding
        let calculated = headerBlock + gridBlock
        let maxHeight = (currentScreenHeight ?? 800) * 0.85
        return min(maxHeight, calculated)
    }

    private var currentScreenHeight: CGFloat? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .screen
            .bounds
            .height
    }

    private func handleDateTap(_ date: Date) {
        let startOfDate = Calendar.current.startOfDay(for: date)

        if habit.completionsPerDay == 1 {
            toggleCompletion(for: startOfDate)
        } else if habit.completionsPerDay <= 10 {
            cycleCompletion(for: startOfDate)
        } else {
            onShowCompletionPicker(startOfDate)
        }
    }

    private func toggleCompletion(for date: Date) {
        let currentCount = completionCount(for: date)
        let isCompleting = currentCount == 0
        Haptics.impact(isCompleting ? .medium : .light)
        setCompletionCount(isCompleting ? 1 : 0, for: date)
    }

    private func cycleCompletion(for date: Date) {
        let currentCount = completionCount(for: date)
        let nextCount = currentCount >= habit.completionsPerDay ? 0 : currentCount + 1
        let impactStyle: Haptics.ImpactStyle = nextCount == 0 ? .light : (nextCount >= habit.completionsPerDay ? .medium : .light)
        Haptics.impact(impactStyle)
        setCompletionCount(nextCount, for: date)
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

private struct MonthCalendarPage: View {
    let monthStart: Date
    let weekdaySymbols: [String]
    let habitCreatedAt: Date
    let completionsByDate: [Date: Int]
    let habitColor: Color
    let onSelectDate: (Date) -> Void

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale.current
        return formatter.string(from: monthStart).uppercased()
    }

    private var gridDates: [Date] {
        let calendar = Calendar.current
        guard let firstWeekStart = calendar.dateInterval(of: .weekOfYear, for: monthStart)?.start else {
            return []
        }

        return (0..<42).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: firstWeekStart)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(monthTitle)
                .font(.system(size: 15, weight: .semibold))
                .padding(.vertical, 4)
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(gridDates, id: \.self) { date in
                    let isInteractive = canInteract(with: date)
                    Button {
                        onSelectDate(date)
                    } label: {
                        MonthlyDayCell(
                            date: date,
                            monthStart: monthStart,
                            habitCreatedAt: habitCreatedAt,
                            completionCount: completionsByDate[Calendar.current.startOfDay(for: date)] ?? 0,
                            habitColor: habitColor
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isInteractive)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    private func canInteract(with date: Date) -> Bool {
        let calendar = Calendar.current
        let startOfDate = calendar.startOfDay(for: date)
        let isCurrentMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
        let isFuture = startOfDate > calendar.startOfDay(for: Date())
        return isCurrentMonth && !isFuture
    }
}

private struct MonthlyDayCell: View {
    let date: Date
    let monthStart: Date
    let habitCreatedAt: Date
    let completionCount: Int
    let habitColor: Color

    private var calendar: Calendar { Calendar.current }

    private var isCurrentMonth: Bool {
        calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
    }

    private var isFuture: Bool {
        date > calendar.startOfDay(for: Date())
    }

    private var isBeforeCreation: Bool {
        date < habitCreatedAt
    }

    private var numberOpacity: Double {
        if !isCurrentMonth || isFuture {
            return 0.35
        }
        return 0.95
    }

    private var showsBackground: Bool {
        completionCount > 0
    }

    var body: some View {
        ZStack {
            if showsBackground {
                RoundedRectangle(cornerRadius: 8)
                    .fill(habitColor.opacity(HabitOpacity.inactive))
            }

            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(numberOpacity))

            if shouldShowCompletionMarkers {
                completionMarkerRow
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .padding(.bottom, 2)
            }
        }
        .frame(height: 42)
    }

    private var shouldShowCompletionMarkers: Bool {
        completionCount > 0 && isCurrentMonth && !isFuture
    }

    @ViewBuilder
    private var completionMarkerRow: some View {
        let dotSize: CGFloat = 4
        let markerHeight: CGFloat = 14
        let dotColor = habitColor.opacity(HabitOpacity.completed)
        let textColor = Color.white.opacity(numberOpacity)

        if completionCount <= 5 {
            HStack(spacing: 3) {
                ForEach(0..<completionCount, id: \.self) { _ in
                    Circle()
                        .fill(dotColor)
                        .frame(width: dotSize, height: dotSize)
                }
            }
            .frame(height: markerHeight, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
        } else {
            HStack(alignment: .center, spacing: 4) {
                Circle()
                    .fill(dotColor)
                    .frame(width: dotSize, height: dotSize)
                Text("\(completionCount)")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
            }
            .frame(height: markerHeight, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
