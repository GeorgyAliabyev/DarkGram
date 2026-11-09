import Cocoa
import Localization

public enum DarkGramHotkeyAction: String, CaseIterable {
    case closePlayer
    case playPause
    case seekBackward
    case seekForward
    case speedUp
    case speedDown
}

public struct DarkGramHotkeyBinding: Codable, Equatable {
    public let keyCode: UInt16
    public let modifierFlags: UInt
    public let display: String

    public init(keyCode: UInt16, modifierFlags: UInt, display: String) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.display = display
    }

    init(event: NSEvent) {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        self.init(keyCode: event.keyCode, modifierFlags: flags.rawValue, display: DarkGramHotkeyBinding.displayString(for: event, flags: flags))
    }

    var isFunctionKey: Bool {
        return DarkGramHotkeyBinding.functionKeys[keyCode] != nil
    }

    private static let functionKeys: [UInt16: String] = [
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12"
    ]

    private static let specialKeys: [UInt16: String] = [
        123: "←", 124: "→", 126: "↑", 125: "↓",
        49: "Space", 36: "↩", 48: "⇥", 51: "⌫", 117: "⌦", 53: "⎋",
        115: "Home", 119: "End", 116: "Page Up", 121: "Page Down"
    ]

    private static func displayString(for event: NSEvent, flags: NSEvent.ModifierFlags) -> String {
        var result = ""
        if flags.contains(.control) {
            result += "⌃"
        }
        if flags.contains(.option) {
            result += "⌥"
        }
        if flags.contains(.shift) {
            result += "⇧"
        }
        if flags.contains(.command) {
            result += "⌘"
        }
        if let special = DarkGramHotkeyBinding.specialKeys[event.keyCode] ?? DarkGramHotkeyBinding.functionKeys[event.keyCode] {
            return result + special
        }
        if let characters = event.charactersIgnoringModifiers, !characters.isEmpty {
            return result + characters.uppercased()
        }
        return result + "Key \(event.keyCode)"
    }
}

public final class DarkGramHotkeys {
    public static let shared = DarkGramHotkeys()

    private let storageKey = "DarkGram.Hotkeys.v1"
    private var bindings: [DarkGramHotkeyAction: [DarkGramHotkeyBinding]]

    private init() {
        self.bindings = DarkGramHotkeys.defaultBindings
        guard let data = UserDefaults.standard.data(forKey: self.storageKey) else {
            return
        }
        guard let stored = try? JSONDecoder().decode([String: [DarkGramHotkeyBinding]].self, from: data) else {
            return
        }
        var decoded: [DarkGramHotkeyAction: [DarkGramHotkeyBinding]] = [:]
        for (raw, value) in stored {
            if let action = DarkGramHotkeyAction(rawValue: raw) {
                decoded[action] = value
            }
        }
        for (action, value) in DarkGramHotkeys.defaultBindings where decoded[action] == nil {
            decoded[action] = value
        }
        self.bindings = decoded
    }

    private static var defaultBindings: [DarkGramHotkeyAction: [DarkGramHotkeyBinding]] {
        return [
            .closePlayer: [
                DarkGramHotkeyBinding(keyCode: 118, modifierFlags: 0, display: "F4"),
                DarkGramHotkeyBinding(keyCode: 14, modifierFlags: NSEvent.ModifierFlags.option.rawValue, display: "⌥E")
            ],
            .playPause: [
                DarkGramHotkeyBinding(keyCode: 35, modifierFlags: NSEvent.ModifierFlags.option.rawValue, display: "⌥P")
            ],
            .seekBackward: [
                DarkGramHotkeyBinding(keyCode: 123, modifierFlags: NSEvent.ModifierFlags.option.rawValue, display: "⌥←")
            ],
            .seekForward: [
                DarkGramHotkeyBinding(keyCode: 124, modifierFlags: NSEvent.ModifierFlags.option.rawValue, display: "⌥→")
            ],
            .speedUp: [
                DarkGramHotkeyBinding(keyCode: 126, modifierFlags: NSEvent.ModifierFlags.option.rawValue, display: "⌥↑")
            ],
            .speedDown: [
                DarkGramHotkeyBinding(keyCode: 125, modifierFlags: NSEvent.ModifierFlags.option.rawValue, display: "⌥↓")
            ]
        ]
    }

    public func bindings(for action: DarkGramHotkeyAction) -> [DarkGramHotkeyBinding] {
        return self.bindings[action] ?? []
    }

    public func displayString(for action: DarkGramHotkeyAction) -> String {
        let values = self.bindings(for: action).map { $0.display }
        if values.isEmpty {
            return "—"
        }
        return values.joined(separator: " / ")
    }

    public func action(for event: NSEvent) -> DarkGramHotkeyAction? {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift]).rawValue
        for action in DarkGramHotkeyAction.allCases {
            for binding in self.bindings(for: action) where binding.keyCode == event.keyCode && binding.modifierFlags == flags {
                return action
            }
        }
        return nil
    }

    public func add(_ binding: DarkGramHotkeyBinding, for action: DarkGramHotkeyAction) {
        for other in DarkGramHotkeyAction.allCases {
            self.bindings[other] = self.bindings[other]?.filter { existing in
                return !(existing.keyCode == binding.keyCode && existing.modifierFlags == binding.modifierFlags)
            }
        }
        var values = self.bindings[action] ?? []
        values.removeAll { $0 == binding }
        values.append(binding)
        self.bindings[action] = values
        self.save()
    }

    public func reset(_ action: DarkGramHotkeyAction) {
        self.bindings[action] = DarkGramHotkeys.defaultBindings[action]
        self.save()
    }

    public func resetAll() {
        self.bindings = DarkGramHotkeys.defaultBindings
        self.save()
    }

    private func save() {
        var encoded: [String: [DarkGramHotkeyBinding]] = [:]
        for (action, value) in self.bindings {
            encoded[action.rawValue] = value
        }
        guard let data = try? JSONEncoder().encode(encoded) else {
            return
        }
        UserDefaults.standard.set(data, forKey: self.storageKey)
    }
}

private var darkGramHotkeyMonitor: Any?

func darkGramHotkeyAnnounce(_ text: String) {
    guard NSWorkspace.shared.isVoiceOverEnabled else {
        return
    }
    NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [
        .announcement: text,
        .priority: NSAccessibilityPriorityLevel.high.rawValue
    ])
}

func darkGramHotkeyRecord(_ completion: @escaping (DarkGramHotkeyBinding?) -> Void) {
    if let monitor = darkGramHotkeyMonitor {
        NSEvent.removeMonitor(monitor)
        darkGramHotkeyMonitor = nil
    }
    darkGramHotkeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
        if event.keyCode == 53 {
            if let monitor = darkGramHotkeyMonitor {
                NSEvent.removeMonitor(monitor)
                darkGramHotkeyMonitor = nil
            }
            completion(nil)
            return nil
        }
        let binding = DarkGramHotkeyBinding(event: event)
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        if flags.isEmpty && !binding.isFunctionKey {
            darkGramHotkeyAnnounce(strings().shortcutsControllerDarkGramPressKeys)
            return nil
        }
        if let monitor = darkGramHotkeyMonitor {
            NSEvent.removeMonitor(monitor)
            darkGramHotkeyMonitor = nil
        }
        completion(binding)
        return nil
    })
}
