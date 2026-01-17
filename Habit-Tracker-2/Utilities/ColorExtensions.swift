//
//  ColorExtensions.swift
//  Habit-Tracker-2
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct HabitColors {
    static let palette: [String] = [
        // Row 1 - Warm
        "#FF6B6B", "#FF922B", "#FCC419", "#FFD43B", "#A9E34B", "#51CF66", "#20C997",
        // Row 2 - Cool
        "#22B8CF", "#339AF0", "#5C7CFA", "#7950F2", "#BE4BDB", "#F06595",
        // Row 3 - Neutral
        "#868E96"
    ]

    static var `default`: String { "#5C7CFA" }
}

/// App background colors
enum AppColors {
    /// Main background color (dark gray)
    static let background = Color(hex: "#0C0D0F")

    /// Card/input background color (darker than main)
    static let cardBackground = Color(hex: "#121417")

    /// Button background color
    static let buttonBackground = Color(white: 0.18)

    /// Header secondary text color
    static let headerSecondary = Color.white.opacity(0.6)

    /// Header add button colors
    static let addButtonBackground = Color(hex: "#45E06F")
    static let addButtonForeground = Color(hex: "#0C0D0F")

    /// Card shadow colors
    static let cardShadow = Color.black.opacity(0.55)
    static let cardHighlight = Color.white.opacity(0.04)
}

/// Opacity values for habit color states
enum HabitOpacity {
    /// Inactive state: before habit creation, future days, unchecked buttons
    static let inactive: Double = 0.1

    /// Failed state: days within tracking period with no completions
    static let failed: Double = 0.25

    /// Minimum opacity for partial completions
    static let partialMin: Double = 0.4

    /// Maximum opacity for partial completions (just below full)
    static let partialMax: Double = 0.85

    /// Full completion
    static let completed: Double = 1.0

    /// Calculate opacity for partial completion progress
    static func partial(progress: Double) -> Double {
        partialMin + (progress * (partialMax - partialMin))
    }
}

// MARK: - Slash Overlay for Quit Habits

struct SlashOverlay: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    let lineWidth = max(2, size * 0.05)
                    let lineLength = size * 1.05  // Slightly longer to fill the diameter

                    Rectangle()
                        .fill(color)
                        .frame(width: lineWidth, height: lineLength)
                        .rotationEffect(.degrees(45))
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            )
    }
}

struct AnimatedSlashOverlay: ViewModifier {
    let color: Color
    let isVisible: Bool

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    let size = min(geometry.size.width, geometry.size.height)
                    let lineWidth = max(2, size * 0.05)

                    SlashLine()
                        .trim(from: 0, to: isVisible ? 1 : 0)
                        .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .animation(.easeInOut(duration: 0.25), value: isVisible)
                }
            )
    }
}

struct SlashLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Draw from top-right to bottom-left (45 degree diagonal)
        path.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return path
    }
}

extension View {
    func slashOverlay(color: Color) -> some View {
        modifier(SlashOverlay(color: color))
    }

    func animatedSlashOverlay(color: Color, isVisible: Bool) -> some View {
        modifier(AnimatedSlashOverlay(color: color, isVisible: isVisible))
    }

    /// Conditionally apply a transformation to a view
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
