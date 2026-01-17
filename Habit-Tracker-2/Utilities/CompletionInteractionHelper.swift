//
//  CompletionInteractionHelper.swift
//  Habit-Tracker-2
//

import Foundation

/// Shared logic for handling habit completion interactions across HabitCardView and calendar views.
/// This ensures consistent tap/long-press behavior throughout the app.
enum CompletionInteractionHelper {

    /// The action to perform when a user taps on a completion control
    enum TapAction {
        case toggle           // Binary habits: flip between 0 and 1
        case increment        // Add 1 to current count
        case reset            // Reset to 0 (build habits when complete)
        case showPicker       // Open the completion picker sheet
    }

    /// Determines what action to perform on tap for a given habit state
    /// - Parameters:
    ///   - habit: The habit being modified
    ///   - currentCount: Current completion count for the date
    /// - Returns: The action to perform
    static func tapAction(for habit: Habit, currentCount: Int) -> TapAction {
        // Binary habits always toggle
        if habit.effectiveIsBinary {
            return .toggle
        }

        let dailyGoal = habit.completionsPerDay
        let isQuitHabit = habit.effectiveHabitType == .quit

        // High-count habits (> 10) always use picker
        if dailyGoal > 10 {
            return .showPicker
        }

        if isQuitHabit {
            // Quit habit: track violations
            // When at or over the limit, show picker instead of continuing to increment
            if currentCount >= dailyGoal {
                return .showPicker
            }
            return .increment
        } else {
            // Build habit: track completions
            // When completed (at or over goal), tapping resets to 0
            if currentCount >= dailyGoal {
                return .reset
            }
            return .increment
        }
    }

    /// Determines what action to perform on tap when the habit is already "complete"
    /// (checkmark is showing for multi-completion habits)
    /// - Parameters:
    ///   - habit: The habit being modified
    ///   - currentCount: Current completion count for the date
    /// - Returns: The action to perform
    static func tapActionWhenComplete(for habit: Habit, currentCount: Int) -> TapAction {
        // Binary habits always toggle
        if habit.effectiveIsBinary {
            return .toggle
        }

        let dailyGoal = habit.completionsPerDay

        // High-count habits always use picker
        if dailyGoal > 10 {
            return .showPicker
        }

        if habit.effectiveHabitType == .quit {
            // Quit habit showing complete (0 violations): tapping adds a violation
            return .increment
        } else {
            // Build habit complete: tapping resets to 0
            return .reset
        }
    }

    /// Whether long-press should show the completion picker
    /// - Parameter habit: The habit being modified
    /// - Returns: true if long-press should open picker
    static func shouldShowPickerOnLongPress(for habit: Habit) -> Bool {
        // Only non-binary habits support the picker
        return !habit.effectiveIsBinary
    }

    /// Calculates the next count value when incrementing
    /// - Parameters:
    ///   - currentCount: Current completion count
    ///   - habit: The habit being modified
    /// - Returns: The new count value
    static func incrementedCount(from currentCount: Int, for habit: Habit) -> Int {
        return currentCount + 1
    }

    /// Determines if the habit is "complete" for the given count
    /// - Parameters:
    ///   - habit: The habit
    ///   - count: The current completion count
    /// - Returns: true if the habit is considered complete
    static func isComplete(habit: Habit, count: Int) -> Bool {
        if habit.effectiveHabitType == .quit {
            // Quit habit: complete when no violations (count == 0)
            return count == 0
        } else {
            // Build habit: complete when count >= daily goal
            return count >= habit.completionsPerDay
        }
    }
}
