//
//  EditHabitView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

fileprivate enum EditMode: String, CaseIterable {
    case build = "Build"
    case quit = "Quit"
}

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let habitToEdit: Habit?
    private var isEditing: Bool { habitToEdit != nil }

    // Form State
    @State private var editMode: EditMode = .build
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var icon: String = HabitIcons.defaultIcon
    @State private var color: String = HabitColors.default
    @State private var completionsPerDay: Int = 1
    
    @State private var largerGoalPeriod: StreakPeriod? = nil
    @State private var largerGoalValue: Int = 1
    @State private var largerGoalType: StreakGoalType = .valueBasis

    @State private var showIconPicker = false
    @State private var showDeleteConfirmation = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    init(habit: Habit? = nil) {
        self.habitToEdit = habit
        _name = State(initialValue: habit?.name ?? "")
        _notes = State(initialValue: habit?.habitDescription ?? "")
        _icon = State(initialValue: habit?.icon ?? HabitIcons.defaultIcon)
        _color = State(initialValue: habit?.color ?? HabitColors.default)
        let cPerDay = habit?.completionsPerDay ?? 1
        _completionsPerDay = State(initialValue: cPerDay)
        _editMode = State(initialValue: habit?.effectiveHabitType == .quit ? .quit : .build)

        // If the habit's goal is set to daily with value matching completionsPerDay, treat as "None" in UI
        if let habit = habit,
           habit.streakGoalPeriod == .day,
           habit.streakGoalValue == habit.completionsPerDay,
           habit.streakGoalType == .valueBasis {
            _largerGoalPeriod = State(initialValue: nil)
            _largerGoalValue = State(initialValue: 1)
            _largerGoalType = State(initialValue: .valueBasis)
        } else {
            _largerGoalPeriod = State(initialValue: habit?.streakGoalPeriod)
            _largerGoalValue = State(initialValue: habit?.streakGoalValue ?? 1)
            _largerGoalType = State(initialValue: habit?.streakGoalType ?? .valueBasis)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CustomSegmentedControl(selection: $editMode)
                        .padding(.horizontal)

                    headerCard
                        .padding(.horizontal)

                    colorPaletteCard
                        .padding(.horizontal)

                    dailyGoalSection
                        .padding(.horizontal)

                    largerGoalSection
                        .padding(.horizontal)

                    if isEditing {
                        deleteButton
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .navigationTitle("Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { saveHabit() }
                        .disabled(!isFormValid)
                }
            }
            .safeAreaInset(edge: .bottom) {
                saveChangesButton
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showIconPicker) { IconPickerView(selectedIcon: $icon) }
        .alert("Delete Habit", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: deleteHabit)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this habit? This action cannot be undone.")
        }
    }

    // MARK: - UI Sections

    private var headerCard: some View {
        VStack(spacing: 20) {
            iconSection
            nameAndNotesSection
        }
        .padding(.vertical)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var iconSection: some View {
        ZStack(alignment: .bottomTrailing) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: color))
                .frame(width: 100, height: 100)
                .background(Color(hex: color).opacity(0.2))
                .clipShape(Circle())
                .if(editMode == .quit) { view in
                    view.slashOverlay(color: Color(hex: color))
                }
        }
        .onTapGesture {
            showIconPicker = true
        }
    }
    
    private var nameAndNotesSection: some View {
        VStack(spacing: 4) {
            TextField("Morning Run", text: $name)
                .font(.largeTitle).bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(.white)
            
            TextField("Minutes of running", text: $notes)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.gray)
        }
    }

    private var colorPaletteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("COLOR")
                .font(.footnote).bold()
                .foregroundStyle(.gray)
            
            ColorPickerGrid(selectedColor: $color)
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }


    private var dailyGoalSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) { // Increased spacing
                Text(editMode == .build ? "DAILY GOAL" : "DAILY LIMIT")
                    .font(.footnote).bold()
                    .foregroundStyle(.gray)
                Text(editMode == .build
                    ? "Completions required per day"
                    : "Maximum violations allowed per day")
                    .font(.caption)
                    .foregroundStyle(Color(UIColor.systemGray2))
            }
            Spacer()
            ExactCustomStepper(value: $completionsPerDay, minValue: 0, maxValue: 999)
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: completionsPerDay) { oldValue, newValue in
            // Binary habits (completionsPerDay == 1) can only use day basis
            if newValue == 1 {
                largerGoalType = .dayBasis
            }
        }
    }

    private var largerGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(editMode == .build ? "LARGER GOAL" : "LARGER LIMIT")
                        .font(.footnote).bold()
                        .foregroundStyle(.gray)

                    Text(editMode == .build
                        ? "Long-term target frequency"
                        : "Long-term maximum allowance")
                        .font(.caption)
                        .foregroundStyle(Color(UIColor.systemGray2))
                }
                Spacer()
                if largerGoalPeriod != nil {
                    ExactCustomStepper(value: $largerGoalValue, minValue: 1, maxValue: 999)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .scale.combined(with: .opacity)
                        ))
                }
            }

            Picker("Larger Goal", selection: $largerGoalPeriod) {
                Text("None").tag(StreakPeriod?(nil))
                Text("Weekly").tag(StreakPeriod?.some(.week))
                Text("Monthly").tag(StreakPeriod?.some(.month))
            }
            .pickerStyle(.segmented)
            .frame(height: 36)

            if largerGoalPeriod != nil {
                // Only show basis selection for non-binary habits
                if completionsPerDay > 1 {
                    HStack(spacing: 12) {
                        BasisSelectionCard(
                            icon: "calendar",
                            title: "By Days",
                            subtitle: "Complete on specific days of the period",
                            isSelected: largerGoalType == .dayBasis
                        )
                        .onTapGesture {
                            largerGoalType = .dayBasis
                        }

                        BasisSelectionCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "By Value",
                            subtitle: "Reach a total sum across the period",
                            isSelected: largerGoalType == .valueBasis
                        )
                        .onTapGesture {
                            largerGoalType = .valueBasis
                        }
                    }
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                }

                Text(streakDescription)
                    .font(.caption)
                    .foregroundStyle(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 4)
                    .transition(.opacity)
            }
        }
        .padding()
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .animation(.spring(duration: 0.4, bounce: 0.3), value: largerGoalPeriod)
        .animation(.spring(duration: 0.4, bounce: 0.3), value: completionsPerDay)
    }
    
    private var deleteButton: some View {
        Button(role: .destructive) {
            showDeleteConfirmation = true
        } label: {
            Text("Delete Habit")
                .bold()
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private var saveChangesButton: some View {
        Button(action: saveHabit) {
            Text("Save Changes")
                .font(.headline).bold()
                .foregroundStyle(isFormValid ? .black : Color(uiColor: .darkGray))
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? .white : AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!isFormValid)
        .padding()
        .background(.black)
    }
    
    // MARK: - Logic
    
    private var streakDescription: String {
        guard let period = largerGoalPeriod else { return "" }
        let periodString = period.rawValue

        if editMode == .quit {
            // Quit habit description
            if largerGoalType == .dayBasis {
                return "Stay within limit on \(largerGoalValue) days within the \(periodString)."
            } else {
                return "Keep total violations under \(largerGoalValue) within the \(periodString)."
            }
        } else {
            // Build habit description
            if largerGoalType == .dayBasis {
                return "Your streak will be maintained as long as you complete this habit on \(largerGoalValue) days within the \(periodString)."
            } else {
                return "Your streak will be maintained as long as you hit \(largerGoalValue) completions within the \(periodString)."
            }
        }
    }

    private func saveHabit() {
        if !isFormValid { return }

        let habit = habitToEdit ?? Habit(name: name)

        habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        habit.habitDescription = notes.isEmpty ? nil : notes
        habit.icon = icon
        habit.color = color
        habit.completionsPerDay = completionsPerDay
        habit.habitType = editMode == .quit ? .quit : .build
        habit.isBinary = completionsPerDay == 1

        if let period = largerGoalPeriod {
            habit.streakGoalPeriod = period
            habit.streakGoalValue = largerGoalValue
            // Binary habits can only use day basis
            habit.streakGoalType = completionsPerDay == 1 ? .dayBasis : largerGoalType
        } else {
            // When "None" is selected, default to daily goal matching completionsPerDay
            habit.streakGoalPeriod = .day
            habit.streakGoalValue = completionsPerDay
            habit.streakGoalType = .valueBasis
        }

        if !isEditing {
            modelContext.insert(habit)
        }

        dismiss()
    }
    
    private func deleteHabit() {
        guard let habit = habitToEdit else { return }

        // Delete associated HabitOrder first
        let habitId = habit.id
        let descriptor = FetchDescriptor<HabitOrder>(
            predicate: #Predicate<HabitOrder> { order in
                order.habit.id == habitId
            }
        )

        if let habitOrders = try? modelContext.fetch(descriptor),
           let habitOrder = habitOrders.first {
            modelContext.delete(habitOrder)
        }

        // Delete the habit (this will cascade delete completions)
        modelContext.delete(habit)

        // Save the context
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to delete habit: \(error)")
        }

        dismiss()
    }
}

// MARK: - Custom Subviews

fileprivate struct CustomSegmentedControl: View {
    @Binding var selection: EditMode

    var body: some View {
        HStack(spacing: 4) {
            ForEach(EditMode.allCases, id: \.self) { mode in
                Text(mode.rawValue)
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == mode ? .white : .clear)
                    )
                    .foregroundStyle(selection == mode ? .black : .white)
                    .onTapGesture {
                        selection = mode
                    }
            }
        }
        .padding(4)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

fileprivate struct ExactCustomStepper: View {
    @Binding var value: Int
    let minValue: Int
    let maxValue: Int

    @State private var minusTimer: Timer? = nil
    @State private var plusTimer: Timer? = nil

    var body: some View {
        HStack(spacing: 0) {
            HoldableButton(
                systemImage: "minus",
                onIncrement: { step in decrementValue(by: step) },
                timer: $minusTimer
            )

            Divider().frame(height: 16)
                .background(Color(UIColor.systemGray5))

            Text("\(value)")
                .font(.title3).bold()
                .frame(width: 50, height: 36)
                .contentTransition(.numericText())
                .animation(.spring(duration: 0.3, bounce: 0.4), value: value)

            Divider().frame(height: 16)
                .background(Color(UIColor.systemGray5))

            HoldableButton(
                systemImage: "plus",
                onIncrement: { step in incrementValue(by: step) },
                timer: $plusTimer
            )
        }
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(Capsule())
        .foregroundStyle(.white)
    }

    private func incrementValue(by step: Int) {
        value = min(value + step, maxValue)
    }

    private func decrementValue(by step: Int) {
        value = max(value - step, minValue)
    }
}

fileprivate struct HoldableButton: View {
    let systemImage: String
    let onIncrement: (Int) -> Void
    @Binding var timer: Timer?

    @State private var isPressed = false
    @State private var holdStartTime: Date? = nil

    var body: some View {
        Image(systemName: systemImage)
            .frame(width: 40, height: 36)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            holdStartTime = Date()

                            // Initial tap
                            onIncrement(1)

                            // Start repeating after initial delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                if isPressed {
                                    timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { _ in
                                        let step = calculateStep()
                                        onIncrement(step)
                                    }
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        holdStartTime = nil
                        timer?.invalidate()
                        timer = nil
                    }
            )
    }

    private func calculateStep() -> Int {
        guard let startTime = holdStartTime else { return 1 }
        let elapsed = Date().timeIntervalSince(startTime)

        if elapsed < 1.5 {
            return 1
        } else if elapsed < 3.0 {
            return 10
        } else {
            return 100
        }
    }
}

// MARK: - Color Picker Grid

struct ColorPickerGrid: View {
    @Binding var selectedColor: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 7)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitColors.palette, id: \.self) { colorHex in
                ColorCircle(
                    colorHex: colorHex,
                    isSelected: selectedColor == colorHex
                )
                .onTapGesture {
                    selectedColor = colorHex
                }
            }
        }
    }
}

struct ColorCircle: View {
    let colorHex: String
    let isSelected: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: colorHex))
                .aspectRatio(1, contentMode: .fit)

            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white, lineWidth: 3)
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1)
        .animation(.snappy, value: isSelected)
    }
}

// MARK: - Basis Selection Card

fileprivate struct BasisSelectionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .gray)

                Spacer()

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.blue : Color.gray, lineWidth: 2)
                        .frame(width: 20, height: 20)

                    if isSelected {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 12, height: 12)
                    }
                }
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.gray)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Previews

#Preview("New Habit") {
    EditHabitView()
        .modelContainer(PreviewContainer.empty)
}

#Preview("Edit Habit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Habit.self, configurations: config)
    let habit = Habit(
        name: "Morning Run",
        habitDescription: "Run every morning",
        icon: "figure.run",
        color: "#51CF66",
        completionsPerDay: 1,
        streakGoalValue: 5,
        streakGoalPeriod: .week,
        streakGoalType: .dayBasis
    )
    container.mainContext.insert(habit)

    return EditHabitView(habit: habit)
        .modelContainer(container)
}
