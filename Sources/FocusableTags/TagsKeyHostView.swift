import AppKit

final class TagsKeyHostView: NSView {

    var onMove: ((TagMoveDirection, Bool) -> Bool)?
    var onActivate: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?
    var onKeyboardInteraction: (() -> Void)?
    var onTagTraversalIn: ((TagMoveDirection) -> Void)?
    var lastClearToken = UUID()

    override var acceptsFirstResponder: Bool { true }
    override var canBecomeKeyView: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.recalculateKeyViewLoop()
    }

    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        guard ok else { return false }

        onFocusChange?(true)

        // If became firstResponder because of Tag traversal -> run entry logic.
        if let event = NSApp.currentEvent,
           event.type == .keyDown,
           event.keyCode == 48 {
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

    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 48: // Tab
            onKeyboardInteraction?()

            let isBackward = event.modifierFlags.contains(.shift)
            let direction: TagMoveDirection = isBackward ? .previous : .next

            // 1) Try move focus within tags without wrap
            let handled = onMove?(direction, false) ?? false

            // 2) If not handled -> move to next/prev key-view
            if !handled {
                guard let window else { return }

                let before = window.firstResponder

                if isBackward {
                    window.selectPreviousKeyView(self)
                } else {
                    window.selectNextKeyView(self)
                }

                let after = window.firstResponder

                // 3) If focus did not leave (tags is the only control) -> wrap inside
                if after == nil || after === before || after === self {
                    window.makeFirstResponder(self)
                    _ = onMove?(direction, true)
                }
            }

        case 49 /* Space */, 36 /* Return */, 76 /* Enter */:
            onKeyboardInteraction?()
            onActivate?()

        case 123: // Left
            onKeyboardInteraction?()
            _ = onMove?(.previous, true)

        case 124: // Right
            onKeyboardInteraction?()
            _ = onMove?(.next, true)

        default:
            super.keyDown(with: event)
        }
    }
}
