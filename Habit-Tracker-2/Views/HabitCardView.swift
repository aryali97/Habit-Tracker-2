//
//  HabitCardView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct HabitCardView: View {
    let habit: Habit
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: icon, name, completion button
            HStack {
                // Icon and name section (tappable for edit, has context menu)
                HStack {
                    // Icon with colored background (inactive color)
                    Image(systemName: habit.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(habitColor)
                        .frame(width: 44, height: 44)
                        .background(habitColor.opacity(HabitOpacity.inactive))
                        .clipShape(Circle())

                    Text(habit.name)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white)

                    Spacer()
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    Haptics.impact(.light)
                    onEdit?()
                }
                .contextMenu {
                    if let onEdit = onEdit {
                        Button {
                            Haptics.impact(.light)
                            onEdit()
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                    }

                    if let onDelete = onDelete {
                        Button(role: .destructive) {
                            Haptics.impact(.rigid)
                            onDelete()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }

                // Completion button (separate from context menu)
                CompletionButtonView(habit: habit)
            }

            // Completion grid
            HabitGridView(habit: habit)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.cardBackground)
                .shadow(color: AppColors.cardShadow, radius: 16, x: 0, y: 8)
                .shadow(color: AppColors.cardHighlight, radius: 1, x: 0, y: -1)
        )
    }
}

struct CompletionButtonView: View {
    let habit: Habit
    @Environment(\.modelContext) private var modelContext
    @State private var showingPicker = false

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
        Group {
            if habit.completionsPerDay == 1 {
                // Checkmark button for once-per-day habits
                Button(action: toggleCompletion) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(isCompletedToday ? .white : habitColor)
                        .frame(width: 44, height: 44)
                        .background(isCompletedToday ? habitColor : .clear)
                        .overlay(
                            Circle()
                                .stroke(
                                    isCompletedToday ? .clear : habitColor.opacity(HabitOpacity.inactive),
                                    lineWidth: 2
                                )
                        )
                        .clipShape(Circle())
                        .shadow(
                            color: isCompletedToday ? habitColor.opacity(0.45) : .clear,
                            radius: 10,
                            x: 0,
                            y: 6
                        )
                }
                .buttonStyle(.plain)
            } else if isCompletedToday {
                // Show checkmark when multi-completion habit is fully complete
                Button(action: resetCompletion) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(habitColor)
                        .clipShape(Circle())
                        .shadow(color: habitColor.opacity(0.45), radius: 10, x: 0, y: 6)
                }
                .buttonStyle(.plain)
            } else {
                // Progress ring for multi-completion habits (not yet complete)
                SegmentedProgressButton(
                    count: todayCount,
                    goal: habit.completionsPerDay,
                    color: habitColor,
                    isComplete: isCompletedToday,
                    onTap: incrementCompletion,
                    onLongPress: { showingPicker = true }
                )
                .sheet(isPresented: $showingPicker) {
                    CompletionPickerSheet(
                        habit: habit,
                        currentCount: todayCount,
                        onSave: { newCount in
                            setCompletionCount(newCount)
                        }
                    )
                    .presentationDetents([.medium])
                }
            }
        }
    }

    private func toggleCompletion() {
        // Toggle for once-per-day habits
        let today = Calendar.current.startOfDay(for: Date())

        let isCompleting = !isCompletedToday
        Haptics.impact(isCompleting ? .medium : .light)

        if let completion = todayCompletion {
            completion.count = completion.count > 0 ? 0 : 1
        } else {
            let completion = HabitCompletion(date: today, count: 1)
            completion.habit = habit
            modelContext.insert(completion)
        }

        saveContext()
    }

    private func incrementCompletion() {
        // Increment for multi-completion habits (only when not complete)
        let today = Calendar.current.startOfDay(for: Date())

        let nextCount = (todayCompletion?.count ?? 0) + 1
        let impactStyle: Haptics.ImpactStyle = nextCount >= habit.completionsPerDay ? .medium : .light
        Haptics.impact(impactStyle)

        if let completion = todayCompletion {
            completion.count += 1
        } else {
            let completion = HabitCompletion(date: today, count: 1)
            completion.habit = habit
            modelContext.insert(completion)
        }

        saveContext()
    }

    private func resetCompletion() {
        // Reset multi-completion habit to 0
        if let completion = todayCompletion {
            Haptics.impact(.light)
            completion.count = 0
            saveContext()
        }
    }

    private func setCompletionCount(_ count: Int) {
        let today = Calendar.current.startOfDay(for: Date())

        if let completion = todayCompletion {
            completion.count = count
        } else if count > 0 {
            let completion = HabitCompletion(date: today, count: count)
            completion.habit = habit
            modelContext.insert(completion)
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

// MARK: - Segmented Progress Button

struct SegmentedProgressButton: View {
    let count: Int
    let goal: Int
    let color: Color
    let isComplete: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    private let size: CGFloat = 44
    private let lineWidth: CGFloat = 3
    private let gapDegrees: Double = 6

    var body: some View {
        ZStack {
            // Background segments
            ForEach(0..<goal, id: \.self) { index in
                segmentArc(index: index, filled: false)
                    .stroke(color.opacity(HabitOpacity.failed), lineWidth: lineWidth)
            }

            // Filled segments
            ForEach(0..<count, id: \.self) { index in
                segmentArc(index: index, filled: true)
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }

            // Plus icon
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture(minimumDuration: 0.5) {
            Haptics.impact(.medium)
            onLongPress()
        }
    }

    private func segmentArc(index: Int, filled: Bool) -> Path {
        let totalGapDegrees = Double(goal) * gapDegrees
        let availableDegrees = 360.0 - totalGapDegrees
        let segmentDegrees = availableDegrees / Double(goal)

        let startAngle = -90.0 + (Double(index) * (segmentDegrees + gapDegrees)) + (gapDegrees / 2)
        let endAngle = startAngle + segmentDegrees

        return Path { path in
            path.addArc(
                center: CGPoint(x: size / 2, y: size / 2),
                radius: (size - lineWidth) / 2,
                startAngle: .degrees(startAngle),
                endAngle: .degrees(endAngle),
                clockwise: false
            )
        }
    }
}

// MARK: - Completion Picker Sheet

struct CompletionPickerSheet: View {
    let habit: Habit
    let currentCount: Int
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCount: Int

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    init(habit: Habit, currentCount: Int, onSave: @escaping (Int) -> Void) {
        self.habit = habit
        self.currentCount = currentCount
        self.onSave = onSave
        self._selectedCount = State(initialValue: currentCount)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                // Habit info
                HStack {
                    Image(systemName: habit.icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(habitColor)
                        .frame(width: 64, height: 64)
                        .background(habitColor.opacity(HabitOpacity.inactive))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Goal: \(habit.completionsPerDay) per day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // Large progress ring
                ZStack {
                    // Background segments
                    ForEach(0..<habit.completionsPerDay, id: \.self) { index in
                        LargeSegmentArc(
                            index: index,
                            total: habit.completionsPerDay,
                            size: 180
                        )
                        .stroke(
                            habitColor.opacity(HabitOpacity.failed),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                    }

                    // Filled segments
                    ForEach(0..<selectedCount, id: \.self) { index in
                        LargeSegmentArc(
                            index: index,
                            total: habit.completionsPerDay,
                            size: 180
                        )
                        .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    }

                    // Count display
                    VStack(spacing: 4) {
                        Text("\(selectedCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(habitColor)

                        Text("of \(habit.completionsPerDay)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 180, height: 180)

                // Stepper controls
                HStack(spacing: 24) {
                    Button {
                        if selectedCount > 0 {
                            selectedCount -= 1
                            Haptics.selection()
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    .disabled(selectedCount == 0)
                    .opacity(selectedCount == 0 ? 0.5 : 1)

                    Button {
                        if selectedCount < habit.completionsPerDay {
                            selectedCount += 1
                            Haptics.selection()
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(habitColor)
                            .clipShape(Circle())
                    }
                    .disabled(selectedCount >= habit.completionsPerDay)
                    .opacity(selectedCount >= habit.completionsPerDay ? 0.5 : 1)
                }

                Spacer()
            }
            .safeAreaPadding(.top, 56)
            .background(AppColors.background)
            .navigationTitle("Today's Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        Haptics.impact(.light)
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(selectedCount)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(habitColor)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct LargeSegmentArc: Shape {
    let index: Int
    let total: Int
    let size: CGFloat
    private let gapDegrees: Double = 6

    func path(in rect: CGRect) -> Path {
        let totalGapDegrees = Double(total) * gapDegrees
        let availableDegrees = 360.0 - totalGapDegrees
        let segmentDegrees = availableDegrees / Double(total)

        let startAngle = -90.0 + (Double(index) * (segmentDegrees + gapDegrees)) + (gapDegrees / 2)
        let endAngle = startAngle + segmentDegrees

        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: (size - 8) / 2,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
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
        let habit = Habit(name: "Morning Run", icon: "figure.run", color: "#51CF66")
        container.mainContext.insert(habit)

        return HabitCardView(habit: habit)
            .padding()
            .background(AppColors.background)
            .modelContainer(container)
    }

    static var multiCompletion: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Habit.self, configurations: config)
        let habit = Habit(
            name: "Drink Water",
            icon: "drop.fill",
            color: "#339AF0",
            completionsPerDay: 8
        )
        container.mainContext.insert(habit)

        return HabitCardView(habit: habit)
            .padding()
            .background(AppColors.background)
            .modelContainer(container)
    }
}
