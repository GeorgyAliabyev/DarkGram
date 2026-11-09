import Cocoa
import TGUIKit
import SwiftSignalKit
import InputDataUI
import GeneralRows
import Localization
import TelegramContext
import TelegramUtils
import TelegramTheme
import ColorPalette
import FoundationUtils
import TelegramCore
import Postbox

private func darkGramHotkeyEntry(sectionId: Int32, index: Int32, action: DarkGramHotkeyAction, title: String, viewType: GeneralViewType, onChange: @escaping () -> Void) -> InputDataEntry {
    let data = InputDataGeneralData(name: title, color: theme.colors.text, icon: nil, type: .context(DarkGramHotkeys.shared.displayString(for: action)), viewType: viewType, enabled: true, description: nil, action: {
        darkGramHotkeyAnnounce(strings().shortcutsControllerDarkGramPressKeys)
        darkGramHotkeyRecord { binding in
            guard let binding = binding else {
                return
            }
            DarkGramHotkeys.shared.add(binding, for: action)
            darkGramHotkeyAnnounce("\(strings().shortcutsControllerDarkGramRecorded): \(binding.display)")
            onChange()
        }
    })
    return .general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("darkgram_hotkey_\(action.rawValue)"), data: data)
}

private func shortcutEntires(onChange: @escaping () -> Void) -> [InputDataEntry] {
    var entries:[InputDataEntry] = []

    var sectionId:Int32 = 0
    var index: Int32 = 0

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    // darkgram player

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerDarkGramTitle), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1

    entries.append(darkGramHotkeyEntry(sectionId: sectionId, index: index, action: .closePlayer, title: strings().shortcutsControllerDarkGramClosePlayer, viewType: .firstItem, onChange: onChange))
    index += 1

    entries.append(darkGramHotkeyEntry(sectionId: sectionId, index: index, action: .playPause, title: strings().shortcutsControllerDarkGramPlayPause, viewType: .innerItem, onChange: onChange))
    index += 1

    entries.append(darkGramHotkeyEntry(sectionId: sectionId, index: index, action: .seekBackward, title: strings().shortcutsControllerDarkGramSeekBackward, viewType: .innerItem, onChange: onChange))
    index += 1

    entries.append(darkGramHotkeyEntry(sectionId: sectionId, index: index, action: .seekForward, title: strings().shortcutsControllerDarkGramSeekForward, viewType: .innerItem, onChange: onChange))
    index += 1

    entries.append(darkGramHotkeyEntry(sectionId: sectionId, index: index, action: .speedUp, title: strings().shortcutsControllerDarkGramSpeedUp, viewType: .innerItem, onChange: onChange))
    index += 1

    entries.append(darkGramHotkeyEntry(sectionId: sectionId, index: index, action: .speedDown, title: strings().shortcutsControllerDarkGramSpeedDown, viewType: .innerItem, onChange: onChange))
    index += 1

    let resetData = InputDataGeneralData(name: strings().shortcutsControllerDarkGramReset, color: theme.colors.accent, icon: nil, type: .none, viewType: .lastItem, enabled: true, description: nil, action: {
        DarkGramHotkeys.shared.resetAll()
        darkGramHotkeyAnnounce(strings().shortcutsControllerDarkGramReset)
        onChange()
    })
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("darkgram_hotkeys_reset"), data: resetData))
    index += 1

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1

    // chat

    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerChat), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("chat_open_info"), data: InputDataGeneralData(name: strings().shortcutsControllerChatOpenInfo, color: theme.colors.text, icon: nil, type: .context("→"), viewType: .firstItem, enabled: true, description: nil)))
    index += 1
    
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("reply_to_message"), data: InputDataGeneralData(name: strings().shortcutsControllerChatSelectMessageToReply, color: theme.colors.text, icon: nil, type: .context("⌘↑ / ⌘↓"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("edit_message"), data: InputDataGeneralData(name: strings().shortcutsControllerChatEditLastMessage, color: theme.colors.text, icon: nil, type: .context("↑"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1

    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("edit_media"), data: InputDataGeneralData(name: strings().shortcutsControllerChatRecordVoiceMessage, color: theme.colors.text, icon: nil, type: .context("⌘R"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("search_in_chat"), data: InputDataGeneralData(name: strings().shortcutsControllerChatSearchMessages, color: theme.colors.text, icon: nil, type: .context("⌘F"), viewType: .lastItem, enabled: true, description: nil)))
    index += 1
    
    // video chat
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerVideoChat), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("toggle_camera"), data: InputDataGeneralData(name: strings().shortcutsControllerVideoChatToggleCamera, color: theme.colors.text, icon: nil, type: .context("⌘E"), viewType: .firstItem, enabled: true, description: nil)))
    index += 1

    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("toggle_screen"), data: InputDataGeneralData(name: strings().shortcutsControllerVideoChatToggleScreencast, color: theme.colors.text, icon: nil, type: .context("⌘T"), viewType: .lastItem, enabled: true, description: nil)))
    index += 1

    
    //search
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerSearch), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("quick_search"), data: InputDataGeneralData(name: strings().shortcutsControllerSearchQuickSearch, color: theme.colors.text, icon: nil, type: .context("⌘K"), viewType: .firstItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("global_search"), data: InputDataGeneralData(name: strings().shortcutsControllerSearchGlobalSearch, color: theme.colors.text, icon: nil, type: .context("⇧⌘F"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("switch_account"), data: InputDataGeneralData(name: strings().shortcutsControllerSearchSwitchAccount, color: theme.colors.text, icon: nil, type: .context("⇧⌘M"), viewType: .lastItem, enabled: true, description: nil)))
    index += 1
    
    
    //MARKDOWN
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerMarkdown), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("markdown_bold"), data: InputDataGeneralData(name: strings().shortcutsControllerMarkdownBold, color: theme.colors.text, icon: nil, type: .context("⌘B / **"), viewType: .firstItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("markdown_italic"), data: InputDataGeneralData(name: strings().shortcutsControllerMarkdownItalic, color: theme.colors.text, icon: nil, type: .context("⌘I / __"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("markdown_monospace"), data: InputDataGeneralData(name: strings().shortcutsControllerMarkdownMonospace, color: theme.colors.text, icon: nil, type: .context("⇧⌘K / `"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("markdown_url"), data: InputDataGeneralData(name: strings().shortcutsControllerMarkdownHyperlink, color: theme.colors.text, icon: nil, type: .context("⌘U"), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("markdown_strikethrough"), data: InputDataGeneralData(name: strings().shortcutsControllerMarkdownStrikethrough, color: theme.colors.text, icon: nil, type: .context("~~"), viewType: .lastItem, enabled: true, description: nil)))
    index += 1
    
    // OTHERS
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerOthers), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("lock_passcode"), data: InputDataGeneralData(name: strings().shortcutsControllerOthersLockByPasscode, color: theme.colors.text, icon: nil, type: .context("⌘L"), viewType: .singleItem, enabled: true, description: nil)))
    index += 1
    
    
    // MOUSE
    
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerMouse), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("fast_reply"), data: InputDataGeneralData(name: strings().shortcutsControllerMouseFastReply, color: theme.colors.text, icon: nil, type: .context(strings().shortcutsControllerMouseFastReplyValue), viewType: .firstItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("schedule"), data: InputDataGeneralData(name: strings().shortcutsControllerMouseScheduleMessage, color: theme.colors.text, icon: nil, type: .context(strings().shortcutsControllerMouseScheduleMessageValue), viewType: .lastItem, enabled: true, description: nil)))
    index += 1
    

    //Trackpad Gesture

    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    entries.append(.desc(sectionId: sectionId, index: index, text: .plain(strings().shortcutsControllerGestures), data: .init(color: theme.colors.listGrayText, viewType: .textTopItem)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("swipe_reply"), data: InputDataGeneralData(name: strings().shortcutsControllerGesturesReply, color: theme.colors.text, icon: nil, type: .context(strings().shortcutsControllerGesturesReplyValue), viewType: .firstItem, enabled: true, description: nil)))
    index += 1
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("swipe_actions"), data: InputDataGeneralData(name: strings().shortcutsControllerGesturesChatAction, color: theme.colors.text, icon: nil, type: .context(strings().shortcutsControllerGesturesChatActionValue), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("swipe_navigation"), data: InputDataGeneralData(name: strings().shortcutsControllerGesturesNavigation, color: theme.colors.text, icon: nil, type: .context(strings().shortcutsControllerGesturesNavigationsValue), viewType: .innerItem, enabled: true, description: nil)))
    index += 1
    
    
    entries.append(.general(sectionId: sectionId, index: index, value: .none, error: nil, identifier: InputDataIdentifier("swipe_stickers"), data: InputDataGeneralData(name: strings().shortcutsControllerGesturesStickers, color: theme.colors.text, icon: nil, type: .context(strings().shortcutsControllerGesturesStickersValue), viewType: .lastItem, enabled: true, description: nil)))
    index += 1
    
    
    entries.append(.sectionId(sectionId, type: .normal))
    sectionId += 1
    
    
    return entries
}

public func ShortcutListController(context: any AccountContextProtocol) -> ViewController {
    let promise = ValuePromise<[InputDataEntry]>([])

    func currentEntries() -> [InputDataEntry] {
        return shortcutEntires(onChange: {
            promise.set(currentEntries())
        })
    }

    promise.set(currentEntries())

    let controller = InputDataController(dataSignal: promise.get() |> map { InputDataSignalValue(entries: $0) }, title: strings().shortcutsControllerTitle, validateData: { data in
        return .fail(.none)
    }, removeAfterDisappear: true, hasDone: false, identifier: "shortcuts")
    
    controller._abolishWhenNavigationSame = true
    
    return controller
}
