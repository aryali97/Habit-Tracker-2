//
//  PressScaleButtonStyle.swift
//  Habit-Tracker-2
//

import SwiftUI

struct PressScaleButtonStyle: ButtonStyle {
    var pressedScale: CGFloat = 0.96
    var duration: Double = 0.12

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .animation(.easeOut(duration: duration), value: configuration.isPressed)
    }
}
