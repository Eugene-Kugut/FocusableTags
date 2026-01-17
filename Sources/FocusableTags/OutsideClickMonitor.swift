import SwiftUI
import AppKit

struct OutsideClickMonitor: NSViewRepresentable {
    let onOutsideClick: () -> Void

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.onOutsideClick = onOutsideClick
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.onOutsideClick = onOutsideClick
    }

    final class MonitorView: NSView {
        var onOutsideClick: (() -> Void)?

        private var eventMonitorToken: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            if window != nil {
                installMonitorIfNeeded()
            } else {
                removeMonitorIfNeeded()
            }
        }

        override func viewWillMove(toWindow newWindow: NSWindow?) {
            super.viewWillMove(toWindow: newWindow)

            if newWindow == nil {
                removeMonitorIfNeeded()
            }
        }

        private func installMonitorIfNeeded() {
            guard eventMonitorToken == nil else { return }

            eventMonitorToken = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] event in
                guard let self else { return event }
                guard let window = self.window, event.window === window else { return event }

                let rectInWindow = self.convert(self.bounds, to: nil)
                let point = event.locationInWindow

                if !rectInWindow.contains(point) {
                    DispatchQueue.main.async { [weak self] in
                        self?.onOutsideClick?()
                    }
                }

                return event
            }
        }

        private func removeMonitorIfNeeded() {
            guard let token = eventMonitorToken else { return }
            NSEvent.removeMonitor(token)
            eventMonitorToken = nil
        }
    }
}
