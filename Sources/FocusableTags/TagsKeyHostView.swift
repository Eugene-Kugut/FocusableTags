import AppKit

final class TagsKeyHostView: NSView {

    var hostID: UUID = UUID()

    var onMove: ((TagMoveDirection, Bool) -> Bool)?
    var onActivate: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var onKeyboardInteraction: (() -> Void)?
    var onTagTraversalIn: ((TagMoveDirection) -> Void)?
    var onBecameActiveHost: (() -> Void)?
    var lastClearToken = UUID()

    private var keyDownMonitorToken: Any?

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.recalculateKeyViewLoop()

        if window != nil {
            installWindowKeyDownMonitorIfNeeded()
        } else {
            removeWindowKeyDownMonitorIfNeeded()
        }
    }

    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)

        if newWindow == nil {
            removeWindowKeyDownMonitorIfNeeded()
        }
    }

    private func installWindowKeyDownMonitorIfNeeded() {
        guard keyDownMonitorToken == nil else { return }

        keyDownMonitorToken = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self else { return event }
            guard let window = self.window, event.window === window else { return event }

            if event.keyCode == 48, event.modifierFlags.contains(.control) {
                let isActiveHost = MainActor.assumeIsolated {
                    FocusableTagsFocusCoordinator.shared.activeHostID == self.hostID
                }
                guard isActiveHost else { return event }

                self.onBecameActiveHost?()
                self.onKeyboardInteraction?()

                let direction: TagMoveDirection = event.modifierFlags.contains(.shift) ? .previous : .next
                _ = self.onMove?(direction, true)

                DispatchQueue.main.async { [weak self] in
                    guard let self, let window = self.window else { return }
                    if window.firstResponder !== self {
                        window.makeFirstResponder(self)
                    }
                }

                return nil
            }

            return event
        }
    }

    private func removeWindowKeyDownMonitorIfNeeded() {
        guard let token = keyDownMonitorToken else { return }
        NSEvent.removeMonitor(token)
        keyDownMonitorToken = nil
    }

    override func becomeFirstResponder() -> Bool {
        onBecameActiveHost?()

        let ok = super.becomeFirstResponder()
        guard ok else { return false }

        onFocusChange?(true)

        if let event = NSApp.currentEvent,
           event.type == .keyDown,
           event.keyCode == 48,
           event.modifierFlags.contains(.control) == false {
            let direction: TagMoveDirection = event.modifierFlags.contains(.shift) ? .previous : .next
            onTagTraversalIn?(direction)
        }

        return true
    }

    override func resignFirstResponder() -> Bool {
        let ok = super.resignFirstResponder()
        if ok { onFocusChange?(false) }
        return ok
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard event.type == .keyDown else {
            return super.performKeyEquivalent(with: event)
        }

        if event.keyCode == 48, event.modifierFlags.contains(.control) {
            onBecameActiveHost?()
            onKeyboardInteraction?()

            let direction: TagMoveDirection = event.modifierFlags.contains(.shift) ? .previous : .next
            _ = onMove?(direction, true)
            return true
        }

        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {

        case 48: // Tab
            onKeyboardInteraction?()

            let isBackward = event.modifierFlags.contains(.shift)

            if event.modifierFlags.contains(.control) {
                onBecameActiveHost?()
                let direction: TagMoveDirection = isBackward ? .previous : .next
                _ = onMove?(direction, true)
                return
            }

            guard let window else { return }

            let before = window.firstResponder

            if isBackward {
                window.selectPreviousKeyView(self)
            } else {
                window.selectNextKeyView(self)
            }

            let after = window.firstResponder

            if after == nil || after === before || after === self {
                window.makeFirstResponder(self)
            }

        case 49 /* Space */, 36 /* Return */, 76 /* Enter */:
            onBecameActiveHost?()
            onKeyboardInteraction?()
            onActivate?()

        case 123: // Left  (<)
            onBecameActiveHost?()
            onKeyboardInteraction?()
            _ = onMove?(.previous, false)

        case 124: // Right (>)
            onBecameActiveHost?()
            onKeyboardInteraction?()
            _ = onMove?(.next, false)

        default:
            super.keyDown(with: event)
        }
    }
}
