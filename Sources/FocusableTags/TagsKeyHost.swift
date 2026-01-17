import SwiftUI
import AppKit

struct TagsKeyHost: NSViewRepresentable {
    @Binding var isFocused: Bool

    let clearExternalFocusToken: UUID
    let onKeyboardInteraction: () -> Void

    let onMove: (TagMoveDirection, _ wrapping: Bool) -> Bool
    let onActivate: () -> Void

    let onFocusInByTagTraversal: (TagMoveDirection) -> Bool
    let onFocusOut: () -> Void

    let hostID: UUID
    let onBecameActiveHost: () -> Void

    func makeNSView(context: Context) -> TagsKeyHostView {
        let view = TagsKeyHostView()
        view.focusRingType = .none

        view.hostID = hostID
        applyCallbacks(to: view)
        view.lastClearToken = clearExternalFocusToken

        return view
    }

    func updateNSView(_ nsView: TagsKeyHostView, context: Context) {
        nsView.hostID = hostID
        applyCallbacks(to: nsView)

        if nsView.lastClearToken != clearExternalFocusToken {
            nsView.lastClearToken = clearExternalFocusToken
            DispatchQueue.main.async {
                guard let window = nsView.window else { return }
                if window.firstResponder !== nsView {
                    window.makeFirstResponder(nil)
                }
            }
        }

        DispatchQueue.main.async {
            guard let window = nsView.window else { return }

            let isActiveHost = MainActor.assumeIsolated {
                FocusableTagsFocusCoordinator.shared.activeHostID == hostID
            }

            if isFocused {
                if isActiveHost {
                    if window.firstResponder !== nsView {
                        window.makeFirstResponder(nsView)
                    }
                } else {
                    if window.firstResponder === nsView {
                        window.makeFirstResponder(nil)
                    }
                }
            } else {
                if window.firstResponder === nsView {
                    window.makeFirstResponder(nil)
                }
            }
        }
    }

    private func applyCallbacks(to view: TagsKeyHostView) {
        view.onMove = onMove
        view.onActivate = onActivate
        view.onKeyboardInteraction = onKeyboardInteraction
        view.onBecameActiveHost = onBecameActiveHost

        view.onFocusChange = { focused in
            DispatchQueue.main.async {
                self.isFocused = focused
                if focused == false { onFocusOut() }
            }
        }

        view.onTagTraversalIn = { direction in
            DispatchQueue.main.async {
                _ = onFocusInByTagTraversal(direction)
            }
        }
    }
}
