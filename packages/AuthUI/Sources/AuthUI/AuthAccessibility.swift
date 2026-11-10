import AppKit

func authAnnounce(_ text: String) {
    let element: Any = NSApp.mainWindow ?? NSApp as Any
    NSAccessibility.post(element: element, notification: .announcementRequested, userInfo: [
        NSAccessibility.NotificationUserInfoKey.announcement: text,
        NSAccessibility.NotificationUserInfoKey.priority: NSAccessibilityPriorityLevel.high.rawValue
    ])
}
