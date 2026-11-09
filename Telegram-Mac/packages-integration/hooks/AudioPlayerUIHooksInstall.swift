import Cocoa
import TGUIKit
import TelegramCore
import Postbox
import SwiftSignalKit
import AudioPlayerUI
import AudioPlayerCore
import InAppSettings
import Localization
import KeyboardKey

extension InstantVideoPIP: @retroactive InlineAudioPlayerInstantVideoPIP {

}

private func darkGramFormattedTime(_ time: TimeInterval) -> String {
    let total = max(0, Int(time))
    let hours = total / 3600
    let minutes = total / 60 % 60
    let seconds = total % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    }
    return String(format: "%d:%02d", minutes, seconds)
}

private func darkGramAnnounce(_ text: String) {
    guard NSWorkspace.shared.isVoiceOverEnabled else {
        return
    }
    NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [
        .announcement: text,
        .priority: NSAccessibilityPriorityLevel.high.rawValue
    ])
}

private func darkGramIsEditingText(_ event: NSEvent) -> Bool {
    guard let responder = event.window?.firstResponder else {
        return false
    }
    let name = String(describing: responder)
    return name.contains("TextView") || name.contains("TextField")
}

private func darkGramIsPlaying(_ controller: APController) -> Bool {
    if case .playing = controller.state.status {
        return true
    }
    return false
}

private func darkGramSeek(_ controller: APController, by delta: TimeInterval) {
    let target = min(max(controller.currentTime + delta, 0), max(controller.duration, 0))
    guard controller.set(seek: target) else {
        return
    }
    darkGramAnnounce(darkGramFormattedTime(target))
}

private func darkGramAdjustRate(_ controller: APController, by delta: Double) {
    let isMusic = controller is APChatMusicController
    let current = isMusic ? FastSettings.playingMusicRate : FastSettings.playingRate
    let rate = min(max(((current + delta) * 100).rounded() / 100, 0.5), 2.5)
    if isMusic {
        FastSettings.setPlayingMusicRate(rate)
    } else {
        FastSettings.setPlayingRate(rate)
    }
    controller.baseRate = rate
    darkGramAnnounce("\(strings().voiceOverCommonPlaybackSpeed) \(String(format: "%.2fx", rate))")
}

private func installDarkGramPlayerShortcuts() {
    _ = NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        guard flags == .option else {
            return event
        }
        guard let context = appDelegate?.currentContext, let controller = context.sharedContext.getAudioPlayer() else {
            return event
        }
        if event.keyCode == KeyboardKey.E.rawValue {
            context.sharedContext.endInlinePlayer(animated: true)
            return nil
        }
        guard !darkGramIsEditingText(event) else {
            return event
        }
        if event.keyCode == KeyboardKey.P.rawValue {
            let wasPlaying = darkGramIsPlaying(controller)
            if controller.playOrPause() {
                darkGramAnnounce(wasPlaying ? strings().voiceOverCommonPause : strings().voiceOverCommonPlay)
            }
            return nil
        } else if event.keyCode == KeyboardKey.LeftArrow.rawValue {
            darkGramSeek(controller, by: -5)
            return nil
        } else if event.keyCode == KeyboardKey.RightArrow.rawValue {
            darkGramSeek(controller, by: 5)
            return nil
        } else if event.keyCode == KeyboardKey.UpArrow.rawValue {
            darkGramAdjustRate(controller, by: 0.25)
            return nil
        } else if event.keyCode == KeyboardKey.DownArrow.rawValue {
            darkGramAdjustRate(controller, by: -0.25)
            return nil
        }
        return event
    })
}

func installAudioPlayerUIHooks() {
    AudioPlayerUIHooks.install(AudioPlayerUIHooks(makeInstantVideoPip: { controller in
        return InstantVideoPIP(controller, context: controller.context.concrete, window: controller.context.concrete.window)
    }, updateInstantVideoPip: { instantVideoPip, tableView, controller in
        (instantVideoPip as? InstantVideoPIP)?.updateTableView(tableView, context: controller.context.concrete, controller: controller)
    }, hideInstantVideoPip: { instantVideoPip in
        (instantVideoPip as? InstantVideoPIP)?.hide()
    }, addGlobalAudioToVisible: { tableView, controller in
        tableView.enumerateViews(with: { (view) in
            var contentView: NSView? = (view as? ChatRowView)?.contentView.subviews.last ?? (view as? PeerMediaMusicRowView)
            if let view = ((view as? ChatMessageView)?.webpageContent as? WPMediaContentView)?.contentNode {
                contentView = view
            }

            if let view = view as? ChatGroupedView {
                for content in view.contents {
                    controller.add(listener: content)
                }
            } else if let view = contentView as? ChatAudioContentView {
                controller.add(listener: view)
            } else if let view = contentView as? ChatVideoMessageContentView {
                controller.add(listener: view)
            } else if let view = contentView as? WPMediaContentView {
                if let contentNode = view.contentNode as? ChatAudioContentView {
                    controller.add(listener: contentNode)
                }
            } else if let view = view as? PeerMediaMusicRowView {
                controller.add(listener: view)
            } else if let view = view as? PeerMediaVoiceRowView {
                controller.add(listener: view)
            } else if let view = view as? StorageUsageMediaItemView {
                controller.add(listener: view)
            } else if let view = view as? ChatRichTextRowView {
                for content in view.audioContentViews() {
                    controller.add(listener: content)
                }
            }
            return true
        })
    }, gotoMessage: { context, message in
        let context = context.concrete
        if let controller = context.bindings.rootNavigation().controller as? ChatController, controller.chatInteraction.peerId == message.id.peerId {
            controller.chatInteraction.focusMessageId(nil, .init(messageId: message.id, string: nil), .center(id: 0, innerId: nil, animated: true, focus: .init(focus: false), inset: 0))
        } else {
            navigateToChat(navigation: context.bindings.rootNavigation(), context: context, chatLocation: .peer(message.id.peerId), focusTarget: .init(messageId: message.id))
        }
    }, showChatPlayerList: { audioPlayer, controller, context, message, window in
        showModal(with: PlayerListController(audioPlayer: audioPlayer, context: controller.context.concrete, currentContext: context.concrete, source: .chat(message.id.peerId, MessageIndex(message), controller.messages)), for: window)
    }, showProfilePlayerList: { audioPlayer, controller, context, reference, window in
        showModal(with: PlayerListController(audioPlayer: audioPlayer, context: controller.context.concrete, currentContext: context.concrete, source: .profile(controller.peer, reference.media, controller.currentState, controller.profileMusicContext)), for: window)
    }, endInlinePlayer: { context, animated in
        context?.concrete.sharedContext.endInlinePlayer(animated: animated)
    }, getAudioPlayer: { context in
        return (context as! AccountContext).sharedContext.getAudioPlayer()
    }, focusSearch: { context, text in
        context.bindings.mainViewController.focusSearch(animated: true, text: text)
    }))

    installDarkGramPlayerShortcuts()
}
