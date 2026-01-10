//
//  HabitCardView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct HabitCardView: View {
    let habit: Habit

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: emoji, name, completion button
            HStack {
                // Emoji with colored background
                Text(habit.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(habitColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(habit.name)
                    .font(.headline)
                    .foregroundStyle(.white)

                Spacer()

                // Completion button (placeholder for now)
                CompletionButtonView(habit: habit)
            }

            // Grid placeholder
            HabitGridPlaceholderView(habit: habit)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(habitColor.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CompletionButtonView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private var todayCompletion: HabitCompletion? {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completions.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var isCompletedToday: Bool {
        guard let completion = todayCompletion else { return false }
        return completion.count >= habit.completionsPerDay
    }

    private var todayCount: Int {
        todayCompletion?.count ?? 0
    }

    var body: some View {
        Button(action: toggleCompletion) {
            if habit.completionsPerDay == 1 {
                // Checkmark button for once-per-day habits
                Image(systemName: isCompletedToday ? "checkmark" : "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(isCompletedToday ? habitColor : .gray)
                    .frame(width: 44, height: 44)
                    .background(isCompletedToday ? habitColor.opacity(0.2) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isCompletedToday ? habitColor : .gray.opacity(0.5), lineWidth: 2)
                    )
            } else {
                // Progress ring for multi-completion habits
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(habitColor.opacity(0.2), lineWidth: 3)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: CGFloat(todayCount) / CGFloat(habit.completionsPerDay))
                        .stroke(habitColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    // Plus icon
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isCompletedToday ? habitColor : .gray)
                }
                .frame(width: 44, height: 44)
            }
        }
        .buttonStyle(.plain)
    }

    private func toggleCompletion() {
        let today = Calendar.current.startOfDay(for: Date())

        if let completion = todayCompletion {
            if habit.completionsPerDay == 1 {
                // Toggle for once-per-day
                completion.count = completion.count > 0 ? 0 : 1
            } else {
                // Increment for multi-completion (wrap around if at max)
                if completion.count >= habit.completionsPerDay {
                    completion.count = 0
                } else {
                    completion.count += 1
                }
            }
        } else {
            // Create new completion
            let completion = HabitCompletion(date: today, count: 1)
            completion.habit = habit
            modelContext.insert(completion)
        }
    }
}

struct HabitGridPlaceholderView: View {
    let habit: Habit

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    var body: some View {
        // Placeholder grid - will be replaced with actual grid in Phase 5
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(8), spacing: 2), count: 20), spacing: 2) {
            ForEach(0..<140, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1)
                    .fill(habitColor.opacity(0.15))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview("Once per day habit") {
    HabitCardPreview.oncePerDay
}

#Preview("Multi-completion habit") {
    HabitCardPreview.multiCompletion
}

@MainActor
struct HabitCardPreview {
    static var oncePerDay: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, configurations: config)
        let habit = Habit(name: "Morning Run", emoji: "🏃", color: "#51CF66")
        container.mainContext.insert(habit)

        return HabitCardView(habit: habit)
            .padding()
            .background(Color.black)
            .modelContainer(container)
    }

    static var multiCompletion: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, configurations: config)
        let habit = Habit(
            name: "Drink Water",
            emoji: "💧",
            color: "#339AF0",
            completionsPerDay: 8
        )
        container.mainContext.insert(habit)

        return HabitCardView(habit: habit)
            .padding()
            .background(Color.black)
            .modelContainer(container)
    }
}
