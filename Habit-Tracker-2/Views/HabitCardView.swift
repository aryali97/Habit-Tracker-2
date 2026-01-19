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
    var onReorder: (() -> Void)? = nil

    private var habitColor: Color {
        Color(hex: habit.color)
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

    private var subtitle: HabitSubtitle {
        let calculator = HabitSubtitleCalculator(
            habit: habit,
            completionsByDate: completionsByDate
        )
        return calculator.calculate()
    }

    private var secondaryColor: Color {
        switch subtitle.secondaryStyle {
        case .normal:
            return Color(UIColor.systemGray2)
        case .violation:
            return .red
        case .streak:
            return habitColor
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header row: icon, name, completion button
            HStack(alignment: .center, spacing: 12) {
                // Icon and name section (icon tap edits, long-press menu on row)
                HStack(spacing: 12) {
                    Button {
                        Haptics.impact(.light)
                        onEdit?()
                    } label: {
                        Image(systemName: habit.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(habitColor)
                            .frame(width: 44, height: 44)
                            .background(habitColor.opacity(HabitOpacity.inactive))
                            .clipShape(Circle())
                            .if(habit.effectiveHabitType == .quit) { view in
                                view.slashOverlay(color: habitColor)
                            }
                    }
                    .buttonStyle(PressScaleButtonStyle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)

                        HStack(spacing: 0) {
                            Text(subtitle.goalText)
                                .font(.caption)
                                .foregroundStyle(Color(UIColor.systemGray2))

                            if let secondaryText = subtitle.secondaryText {
                                Text(" \u{2022} ")
                                    .font(.caption)
                                    .foregroundStyle(Color(UIColor.systemGray2))

                                Text(secondaryText)
                                    .font(.caption)
                                    .foregroundStyle(secondaryColor)
                                    .contentTransition(.numericText())
                                    .animation(.snappy, value: secondaryText)
                            }
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
                .contextMenu {
                    if let onReorder = onReorder {
                        Button {
                            Haptics.impact(.light)
                            onReorder()
                        } label: {
                            Label("Reorder", systemImage: "arrow.up.arrow.down")
                        }
                    }

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
    @GestureState private var isPressed = false

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    private var todayCompletion: HabitCompletion? {
        let today = Calendar.current.startOfDay(for: Date())
        return habit.completions.first { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private var isCompletedToday: Bool {
        guard let completion = todayCompletion else {
            return habit.effectiveHabitType == .quit  // Quit: no violations = complete
        }
        if habit.effectiveHabitType == .quit {
            return completion.count == 0
        } else {
            return completion.count >= habit.completionsPerDay
        }
    }

    private var todayCount: Int {
        todayCompletion?.count ?? 0
    }

    private var usesPickerOnTap: Bool {
        !habit.effectiveIsBinary && (habit.completionsPerDay > 10 || (habit.habitType == .quit && todayCount >= habit.completionsPerDay))
    }

    var body: some View {
        Group {
            if habit.effectiveIsBinary {
                // Checkmark button for once-per-day habits
                Button(action: toggleCompletion) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .symbolEffect(.bounce, options: .speed(2.8), value: isCompletedToday)
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
                .buttonStyle(PressScaleButtonStyle())
                .transition(.scale.combined(with: .opacity))
                .animation(.snappy, value: isCompletedToday)
            } else {
                // Progress ring and completion checkmark for multi-completion habits
                ZStack {
                    SegmentedProgressButton(
                        count: todayCount,
                        goal: habit.completionsPerDay,
                        color: habitColor,
                        isComplete: isCompletedToday,
                        habitType: habit.effectiveHabitType,
                        onTap: {
                            if usesPickerOnTap {
                                showingPicker = true
                            } else if habit.effectiveHabitType == .quit && todayCount >= habit.completionsPerDay {
                                // Quit habit at limit: open picker
                                showingPicker = true
                            } else {
                                incrementCompletion()
                            }
                        },
                        onLongPress: { showingPicker = true }
                    )
                    .opacity(isCompletedToday ? 0 : 1)
                    .scaleEffect(isCompletedToday ? 0.9 : 1)
                    .allowsHitTesting(!isCompletedToday)

                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .symbolEffect(.bounce, options: .speed(2.8), value: isCompletedToday)
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(habitColor)
                        .clipShape(Circle())
                        .shadow(color: habitColor.opacity(0.45), radius: 10, x: 0, y: 6)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .contentShape(Circle())
                        .gesture(
                            LongPressGesture(minimumDuration: 0.5)
                                .onEnded { _ in
                                    Haptics.impact(.medium)
                                    showingPicker = true
                                }
                                .sequenced(before: TapGesture())
                                .exclusively(before: TapGesture().onEnded { _ in
                                    Haptics.impact(.light)
                                    if usesPickerOnTap {
                                        showingPicker = true
                                    } else if habit.effectiveHabitType == .quit {
                                        // Quit habit at 0 violations: increment to 1 violation
                                        incrementCompletion()
                                    } else {
                                        // Build habit: reset to 0
                                        resetCompletion()
                                    }
                                })
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .updating($isPressed) { _, state, _ in
                                    state = true
                                }
                        )
                    .opacity(isCompletedToday ? 1 : 0)
                    .scaleEffect(isCompletedToday ? 1 : 0.9)
                    .allowsHitTesting(isCompletedToday)
                }
                .animation(.interpolatingSpring(stiffness: 260, damping: 22), value: isCompletedToday)
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
        .animation(.snappy, value: isCompletedToday)
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
    let habitType: HabitType
    let onTap: () -> Void
    let onLongPress: () -> Void
    @GestureState private var isPressed = false

    private let size: CGFloat = 44
    private let lineWidth: CGFloat = 3
    private let gapDegrees: Double = 6

    private var usesContinuousArc: Bool {
        goal > 10
    }

    var body: some View {
        ZStack {
            if usesContinuousArc {
                // Continuous arc for high-count habits
                Circle()
                    .stroke(color.opacity(HabitOpacity.failed), lineWidth: lineWidth)
                    .frame(width: size - lineWidth, height: size - lineWidth)

                // Filled arc (capped at 100%)
                Circle()
                    .trim(from: 0, to: habitType == .quit
                        ? max(0, 1.0 - Double(count) / Double(goal))  // Decreases as violations increase
                        : min(Double(count) / Double(goal), 1.0))     // Normal for build
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size - lineWidth, height: size - lineWidth)
                    .rotationEffect(.degrees(-90))
            } else {
                // Background segments
                ForEach(0..<goal, id: \.self) { index in
                    segmentArc(index: index, filled: false)
                        .stroke(color.opacity(HabitOpacity.failed), lineWidth: lineWidth)
                }

                // Filled segments
                if habitType == .quit {
                    // For quit: show filled segments from top, removing as count increases
                    let segmentsToShow = max(0, goal - count)
                    ForEach(0..<segmentsToShow, id: \.self) { index in
                        segmentArc(index: index, filled: true)
                            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }
                } else {
                    // For build: show filled segments progressively (capped at goal)
                    ForEach(0..<min(count, goal), id: \.self) { index in
                        segmentArc(index: index, filled: true)
                            .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    }
                }
            }

            // Plus/Minus icon
            Image(systemName: habitType == .quit ? "minus" : "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(color)
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressed) { _, state, _ in
                    state = true
                }
        )
        .scaleEffect(isPressed ? 0.96 : 1)
        .animation(.easeOut(duration: 0.12), value: isPressed)
        .animation(.interpolatingSpring(stiffness: 240, damping: 24), value: count)
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
    let title: String

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCount: Int
    @State private var stepSize: Int

    private let stepOptions: [Int] = [1, 5, 10, 25, 50]

    private var habitColor: Color {
        Color(hex: habit.color)
    }

    init(
        habit: Habit,
        currentCount: Int,
        title: String = "Today's Progress",
        onSave: @escaping (Int) -> Void
    ) {
        self.habit = habit
        self.currentCount = currentCount
        self.title = title
        self.onSave = onSave
        self._selectedCount = State(initialValue: currentCount)

        // Set default step size based on daily goal
        let defaultStep: Int
        if habit.completionsPerDay <= 10 {
            defaultStep = 1
        } else if habit.completionsPerDay <= 25 {
            defaultStep = 5
        } else if habit.completionsPerDay <= 50 {
            defaultStep = 10
        } else if habit.completionsPerDay <= 100 {
            defaultStep = 25
        } else {
            defaultStep = 50
        }
        self._stepSize = State(initialValue: defaultStep)
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
                        .clipShape(Circle())
                        .if(habit.effectiveHabitType == .quit) { view in
                            view.slashOverlay(color: habitColor)
                        }

                    VStack(alignment: .leading) {
                        Text(habit.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if let description = habit.habitDescription, !description.isEmpty {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal)

                // Large progress ring
                ZStack {
                    if habit.completionsPerDay > 10 {
                        // Continuous arc for high-count habits
                        Circle()
                            .stroke(habitColor.opacity(HabitOpacity.failed), lineWidth: 8)
                            .frame(width: 172, height: 172)

                        // Filled arc (capped at 100%)
                        Circle()
                            .trim(from: 0, to: habit.effectiveHabitType == .quit
                                ? max(0, 1.0 - Double(selectedCount) / Double(habit.completionsPerDay))
                                : min(Double(selectedCount) / Double(habit.completionsPerDay), 1.0))
                            .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 172, height: 172)
                            .rotationEffect(.degrees(-90))
                    } else {
                        // Segmented arc for low-count habits
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
                        if habit.effectiveHabitType == .quit {
                            // For quit: show filled segments from top, removing as count increases
                            let segmentsToShow = max(0, habit.completionsPerDay - selectedCount)
                            ForEach(0..<segmentsToShow, id: \.self) { index in
                                LargeSegmentArc(
                                    index: index,
                                    total: habit.completionsPerDay,
                                    size: 180
                                )
                                .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            }
                        } else {
                            // For build: show filled segments progressively (capped at goal)
                            ForEach(0..<min(selectedCount, habit.completionsPerDay), id: \.self) { index in
                                LargeSegmentArc(
                                    index: index,
                                    total: habit.completionsPerDay,
                                    size: 180
                                )
                                .stroke(habitColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            }
                        }
                    }

                    // Count display
                    VStack(spacing: 4) {
                        Text({
                            if habit.effectiveHabitType == .quit {
                                let remaining = habit.completionsPerDay - selectedCount
                                return "\(abs(remaining))"
                            } else {
                                return "\(selectedCount)"
                            }
                        }())
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                habit.effectiveHabitType == .quit && selectedCount > habit.completionsPerDay
                                    ? Color.red
                                    : habitColor
                            )

                        Text({
                            if habit.effectiveHabitType == .quit {
                                if selectedCount <= habit.completionsPerDay {
                                    return "left"
                                } else {
                                    return "over limit"
                                }
                            } else {
                                return "of \(habit.completionsPerDay)"
                            }
                        }())
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 180, height: 180)

                // Stepper controls
                HStack(spacing: 12) {
                    // For quit habits: minus adds violations (increases count)
                    // For build habits: minus removes completions (decreases count)
                    let canDecrement = habit.effectiveHabitType == .quit ? true : selectedCount > 0
                    Button {
                        if habit.effectiveHabitType == .quit {
                            // Quit: minus adds violations
                            let nextValue = selectedCount + stepSize
                            withAnimation(.interpolatingSpring(stiffness: 260, damping: 22)) {
                                selectedCount = nextValue
                            }
                        } else {
                            // Build: minus removes completions
                            guard selectedCount > 0 else { return }
                            let nextValue = max(selectedCount - stepSize, 0)
                            withAnimation(.interpolatingSpring(stiffness: 260, damping: 22)) {
                                selectedCount = nextValue
                            }
                        }
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: "minus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    .disabled(!canDecrement)
                    .opacity(canDecrement ? 1 : 0.45)

                    ForEach(stepOptions, id: \.self) { option in
                        Button {
                            guard stepSize != option else { return }
                            withAnimation(.easeOut(duration: 0.15)) {
                                stepSize = option
                            }
                            Haptics.selection()
                        } label: {
                            Text("\(option)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(stepSize == option ? habitColor : .white.opacity(0.7))
                                .frame(width: 28, height: 28)
                        }
                        .buttonStyle(.plain)
                    }

                    // For quit habits: plus removes violations (decreases count)
                    // For build habits: plus adds completions (increases count)
                    let canIncrement = habit.effectiveHabitType == .quit ? selectedCount > 0 : true
                    Button {
                        if habit.effectiveHabitType == .quit {
                            // Quit: plus removes violations
                            guard selectedCount > 0 else { return }
                            let nextValue = max(selectedCount - stepSize, 0)
                            withAnimation(.interpolatingSpring(stiffness: 260, damping: 22)) {
                                selectedCount = nextValue
                            }
                        } else {
                            // Build: plus adds completions
                            let nextValue = selectedCount + stepSize
                            withAnimation(.interpolatingSpring(stiffness: 260, damping: 22)) {
                                selectedCount = nextValue
                            }
                        }
                        Haptics.impact(.light)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(habitColor)
                            .clipShape(Circle())
                    }
                    .disabled(!canIncrement)
                    .opacity(canIncrement ? 1 : 0.45)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(Capsule())

                Spacer()
            }
            .safeAreaPadding(.top, 56)
            .background(AppColors.background)
            .navigationTitle(title)
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
