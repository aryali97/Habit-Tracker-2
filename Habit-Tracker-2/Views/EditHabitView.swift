//
//  EditHabitView.swift
//  Habit-Tracker-2
//

import SwiftUI
import SwiftData

struct EditHabitView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Existing habit for editing (nil for new habit)
    let habitToEdit: Habit?

    // Form state
    @State private var icon: String = HabitIcons.defaultIcon
    @State private var name: String = ""
    @State private var habitDescription: String = ""
    @State private var selectedColor: String = HabitColors.default
    @State private var completionsPerDay: Int = 1
    @State private var streakGoalValue: Int = 1
    @State private var streakGoalPeriod: StreakPeriod = .day
    @State private var streakGoalType: StreakGoalType = .dayBasis

    // Icon picker state
    @State private var showIconPicker = false
    @State private var formVisible = false
    @State private var iconPulse = false

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isEditing: Bool {
        habitToEdit != nil
    }

    init(habit: Habit? = nil) {
        self.habitToEdit = habit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icon Picker Button
                    IconPickerButton(icon: $icon, color: selectedColor) {
                        Haptics.selection()
                        showIconPicker = true
                    }
                    .scaleEffect(iconPulse ? 1.06 : 1)
                    .shadow(color: iconPulse ? Color(hex: selectedColor).opacity(0.35) : .clear, radius: 10, x: 0, y: 6)
                    .animation(.snappy, value: iconPulse)

                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Habit name", text: $name)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Description field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Optional description", text: $habitDescription)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Color Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        ColorPickerGrid(selectedColor: $selectedColor)
                    }

                    // Completions Per Day
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completions Per Day")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(completionsPerDay)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: completionsPerDay)

                            Text("/ Day")
                                .foregroundStyle(.secondary)

                            Spacer()

                            Stepper("", value: $completionsPerDay, in: 1...100)
                                .labelsHidden()
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Text("The square will be filled completely when this number is met")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Goal
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack {
                            Text("\(streakGoalValue)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)
                                .contentTransition(.numericText())
                                .animation(.snappy, value: streakGoalValue)

                            Text("/")
                                .foregroundStyle(.secondary)

                            Picker("Period", selection: $streakGoalPeriod) {
                                Text("Day").tag(StreakPeriod.day)
                                Text("Week").tag(StreakPeriod.week)
                                Text("Month").tag(StreakPeriod.month)
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(minWidth: 48)

                            Spacer()

                            Stepper("", value: $streakGoalValue, in: 1...365)
                                .labelsHidden()
                        }
                        .padding()
                        .background(AppColors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Goal Type
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Goal Type")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Picker("Goal Type", selection: $streakGoalType) {
                            Text("Day Basis").tag(StreakGoalType.dayBasis)
                            Text("Value Basis").tag(StreakGoalType.valueBasis)
                        }
                        .pickerStyle(.segmented)

                        Text(streakGoalType == .dayBasis
                            ? "Complete on \(streakGoalValue) \(streakGoalPeriod == .day ? "consecutive days" : "days this \(streakGoalPeriod.rawValue)")"
                            : "Reach \(streakGoalValue) total completions this \(streakGoalPeriod.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 40)
                }
                .padding()
                .opacity(formVisible ? 1 : 0)
                .scaleEffect(formVisible ? 1 : 0.98)
                .animation(.easeOut(duration: 0.22), value: formVisible)
            }
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: saveHabit) {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isFormValid
                                ? Color(hex: selectedColor)
                                : Color.gray.opacity(0.5)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .disabled(!isFormValid)
                .padding()
                .background(AppColors.background)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            loadExistingHabit()
            withAnimation(.easeOut(duration: 0.22)) {
                formVisible = true
            }
        }
        .onDisappear {
            formVisible = false
            iconPulse = false
        }
        .sheet(isPresented: $showIconPicker) {
            IconPickerView(selectedIcon: $icon)
        }
        .onChange(of: icon) { _, _ in
            Task { @MainActor in
                withAnimation(.snappy) {
                    iconPulse = true
                }
                try? await Task.sleep(nanoseconds: 180_000_000)
                withAnimation(.easeOut(duration: 0.2)) {
                    iconPulse = false
                }
            }
        }
        .onChange(of: completionsPerDay) { _, _ in
            Haptics.selection()
        }
        .onChange(of: streakGoalValue) { _, _ in
            Haptics.selection()
        }
        .onChange(of: streakGoalPeriod) { _, _ in
            Haptics.selection()
        }
        .onChange(of: streakGoalType) { _, _ in
            Haptics.selection()
        }
    }

    private func loadExistingHabit() {
        guard let habit = habitToEdit else { return }
        icon = habit.icon
        name = habit.name
        habitDescription = habit.habitDescription ?? ""
        selectedColor = habit.color
        completionsPerDay = habit.completionsPerDay
        streakGoalValue = habit.streakGoalValue
        streakGoalPeriod = habit.streakGoalPeriod
        streakGoalType = habit.streakGoalType
    }

    private func saveHabit() {
        Haptics.notification(.success)
        if let habit = habitToEdit {
            // Update existing habit
            habit.icon = icon
            habit.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            habit.habitDescription = habitDescription.isEmpty ? nil : habitDescription
            habit.color = selectedColor
            habit.completionsPerDay = completionsPerDay
            habit.streakGoalValue = streakGoalValue
            habit.streakGoalPeriod = streakGoalPeriod
            habit.streakGoalType = streakGoalType
        } else {
            // Create new habit
            let habit = Habit(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                habitDescription: habitDescription.isEmpty ? nil : habitDescription,
                icon: icon,
                color: selectedColor,
                completionsPerDay: completionsPerDay,
                streakGoalValue: streakGoalValue,
                streakGoalPeriod: streakGoalPeriod,
                streakGoalType: streakGoalType
            )
            modelContext.insert(habit)
        }

        dismiss()
    }
}

// MARK: - Icon Picker Button

struct IconPickerButton: View {
    @Binding var icon: String
    let color: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color(hex: color))
                .frame(width: 88, height: 88)
                .background(AppColors.cardBackground)
                .clipShape(Circle())
        }
        .buttonStyle(PressScaleButtonStyle())
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
                    Haptics.selection()
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
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: colorHex))
                .aspectRatio(1, contentMode: .fit)

            if isSelected {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white, lineWidth: 3)
            }
        }
        .scaleEffect(isSelected ? 1.06 : 1)
        .shadow(color: isSelected ? Color.white.opacity(0.2) : .clear, radius: 6, x: 0, y: 4)
        .animation(.snappy, value: isSelected)
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
