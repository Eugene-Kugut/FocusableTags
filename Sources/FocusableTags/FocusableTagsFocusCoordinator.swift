import Foundation

enum FocusableTagsFocusNotifications {
    static let activeHostDidChange = Notification.Name("FocusableTags.activeHostDidChange")
    static let activeHostIDKey = "activeHostID"
}

@MainActor
final class FocusableTagsFocusCoordinator {
    static let shared = FocusableTagsFocusCoordinator()
    private init() {}

    var activeHostID: UUID? = nil {
        didSet {
            NotificationCenter.default.post(
                name: FocusableTagsFocusNotifications.activeHostDidChange,
                object: nil,
                userInfo: [FocusableTagsFocusNotifications.activeHostIDKey: activeHostID as Any]
            )
        }
    }
}
