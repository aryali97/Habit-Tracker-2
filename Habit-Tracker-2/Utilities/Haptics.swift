//
//  Haptics.swift
//  Habit-Tracker-2
//

import Foundation

#if os(iOS)
import UIKit
#endif

enum Haptics {
    static func impact(_ style: ImpactStyle) {
#if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: style.uiKitStyle)
        generator.impactOccurred()
#endif
    }

    static func selection() {
#if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
#endif
    }

    static func notification(_ type: NotificationType) {
#if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type.uiKitType)
#endif
    }
}

extension Haptics {
    enum ImpactStyle {
        case light
        case medium
        case rigid

#if os(iOS)
        var uiKitStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:
                return .light
            case .medium:
                return .medium
            case .rigid:
                return .rigid
            }
        }
#endif
    }

    enum NotificationType {
        case success
        case warning
        case error

#if os(iOS)
        var uiKitType: UINotificationFeedbackGenerator.FeedbackType {
            switch self {
            case .success:
                return .success
            case .warning:
                return .warning
            case .error:
                return .error
            }
        }
#endif
    }
}
