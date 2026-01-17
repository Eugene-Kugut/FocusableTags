import SwiftUI
import AppKit
import Combine

public struct FocusableTags<ID: Hashable, Label: View>: View {

    public struct Item: Identifiable {
        public var id: ID
        public var isEnabled: Bool
        public var label: () -> Label

        public init(
            _ id: ID,
            isEnabled: Bool = true,
            @ViewBuilder label: @escaping () -> Label
        ) {
            self.id = id
            self.isEnabled = isEnabled
            self.label = label
        }
    }

    public let items: [Item]
    public let selectedBackground: Color
    public let focusedBackground: Color
    public let focusedOverlay: Color
    public let focusedOverlayLineWidth: CGFloat
    public let selectedOverlayColor: Color
    public let overlayColor: Color
    public let overlayLineWidth: CGFloat
    public let hoveredBackground: Color
    public let horizontalSpacing: CGFloat
    public let verticalSpacing: CGFloat
    public let cornerRadius: CGFloat
    public let alignment: HorizontalAlignment
    public let contentInsets: NSEdgeInsets

    @Binding public var selection: Set<ID>

    public init(
        items: [Item],
        selection: Binding<Set<ID>>,
        selectedBackground: Color = Color.primary.opacity(0.10),
        focusedBackground: Color = Color.accentColor.opacity(0.12),
        hoveredBackground: Color = Color.primary.opacity(0.06),
        focusedOverlay: Color = Color.accentColor.opacity(0.9),
        focusedOverlayLineWidth: CGFloat = 1.5,
        selectedOverlayColor: Color = .clear,
        overlayColor: Color = .clear,
        overlayLineWidth: CGFloat = 1,
        contentInsets: NSEdgeInsets = .init(top: 6, left: 12, bottom: 6, right: 12),
        horizontalSpacing: CGFloat = 4,
        verticalSpacing: CGFloat = 4,
        cornerRadius: CGFloat = 8,
        alignment: HorizontalAlignment = .leading
    ) {
        self.items = items
        self._selection = selection
        self.selectedBackground = selectedBackground
        self.focusedBackground = focusedBackground
        self.hoveredBackground = hoveredBackground
        self.focusedOverlay = focusedOverlay
        self.selectedOverlayColor = selectedOverlayColor
        self.focusedOverlayLineWidth = focusedOverlayLineWidth
        self.overlayColor = overlayColor
        self.overlayLineWidth = overlayLineWidth
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.contentInsets = contentInsets
        self.cornerRadius = cornerRadius
        self.alignment = alignment
    }

    private final class HostIdentity: ObservableObject {
        let id = UUID()
    }

    @StateObject private var identity = HostIdentity()

    @State private var isKeyHostFocused = false
    @State private var focusedTagID: ID?
    @State private var showsKeyboardFocus = false
    @State private var anchorTagID: ID?
    @State private var clearExternalFocusToken = UUID()
    @State private var lastSelection: ID?

    public var body: some View {
        ZStack {
            HStack(spacing: 0, content: {
                if alignment == .center || alignment == .trailing {
                    Spacer(minLength: 0)
                }
                WrapLayout(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing, alignment: alignment) {
                    ForEach(items) { item in
                        tagCell(for: item)
                            .id(item.id)
                    }
                }
                if alignment == .center || alignment == .leading {
                    Spacer(minLength: 0)
                }
            })

            TagsKeyHost(
                isFocused: $isKeyHostFocused,
                clearExternalFocusToken: clearExternalFocusToken,
                onKeyboardInteraction: {
                    showsKeyboardFocus = true
                    MainActor.assumeIsolated {
                        FocusableTagsFocusCoordinator.shared.activeHostID = identity.id
                    }
                },
                onMove: { direction, wrapping in
                    moveFocus(direction, wrapping: wrapping)
                },
                onActivate: activateFocused,
                onFocusInByTagTraversal: { direction in
                    showsKeyboardFocus = true
                    return focusOnEntry(direction)
                },
                onFocusOut: {
                    focusedTagID = nil
                    showsKeyboardFocus = false
                    anchorTagID = nil
                },
                hostID: identity.id,
                onBecameActiveHost: {
                    MainActor.assumeIsolated {
                        FocusableTagsFocusCoordinator.shared.activeHostID = identity.id
                    }
                }
            )
            .frame(width: 1, height: 1)
            .opacity(0.01)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .background(
            OutsideClickMonitor {
                anchorTagID = nil
                focusedTagID = nil
                showsKeyboardFocus = false
                isKeyHostFocused = false
            }
            .allowsHitTesting(false)
        )
        .onTapGesture {
            focusedTagID = nil
            anchorTagID = nil
            showsKeyboardFocus = false

            MainActor.assumeIsolated {
                FocusableTagsFocusCoordinator.shared.activeHostID = identity.id
            }

            isKeyHostFocused = true
            clearExternalFocusToken = UUID()
        }
        .onAppear {
            focusedTagID = nil
            anchorTagID = nil
            showsKeyboardFocus = false
            lastSelection = currentSelectionAnchor()
        }
        .onReceive(NotificationCenter.default.publisher(for: FocusableTagsFocusNotifications.activeHostDidChange)) { note in
            let active = note.userInfo?[FocusableTagsFocusNotifications.activeHostIDKey] as? UUID
            if active != identity.id, isKeyHostFocused {
                anchorTagID = nil
                focusedTagID = nil
                showsKeyboardFocus = false
                isKeyHostFocused = false
            }
        }
        .onChange(of: selection) { _, _ in
            if let last = lastSelection, selection.contains(last) == false {
                lastSelection = currentSelectionAnchor()
            } else if lastSelection == nil {
                lastSelection = currentSelectionAnchor()
            }

            if isKeyHostFocused && showsKeyboardFocus {
                let id = focusedTagID ?? anchorTagID ?? lastSelection ?? currentSelectionAnchor()
                if let id {
                    focusedTagID = id
                    anchorTagID = id
                }
            }
        }
    }

    private func tagCell(for item: Item) -> some View {
        let isSelected = selection.contains(item.id)
        let isFocused = showsKeyboardFocus && isKeyHostFocused && item.id == focusedTagID

        return TagCell(
            label: item.label,
            isEnabled: item.isEnabled,
            isSelected: isSelected,
            isFocused: isFocused,
            backgroundColor: tagBackgroundColor(isSelected:isFocused:isHovered:),
            focusedOverlay: focusedOverlay,
            focusedOverlayLineWidth: focusedOverlayLineWidth,
            overlayColor: overlayColor,
            overlayLineWidth: overlayLineWidth,
            contentInsets: contentInsets,
            cornerRadius: cornerRadius,
            onClick: {
                guard item.isEnabled else { return }

                toggleSelection(item.id)

                anchorTagID = item.id
                focusedTagID = nil
                showsKeyboardFocus = false

                MainActor.assumeIsolated {
                    FocusableTagsFocusCoordinator.shared.activeHostID = identity.id
                }

                isKeyHostFocused = true
                clearExternalFocusToken = UUID()
            }
        )
    }

    private func tagBackgroundColor(isSelected: Bool, isFocused: Bool, isHovered: Bool) -> Color {
        if isSelected { return selectedBackground }
        if isFocused { return focusedBackground }
        if isHovered { return hoveredBackground }
        return .clear
    }

    private func toggleSelection(_ id: ID) {
        if selection.contains(id) {
            selection.remove(id)
            if lastSelection == id {
                lastSelection = currentSelectionAnchor()
            }
        } else {
            selection.insert(id)
            lastSelection = id
        }
    }

    private func currentSelectionAnchor() -> ID? {
        for item in items where selection.contains(item.id) {
            return item.id
        }
        return nil
    }

    private func isEnabled(_ id: ID) -> Bool {
        items.first(where: { $0.id == id })?.isEnabled == true
    }

    private func firstEnabledID() -> ID? {
        items.first(where: { $0.isEnabled })?.id
    }

    private func lastEnabledID() -> ID? {
        items.last(where: { $0.isEnabled })?.id
    }

    private func nextEnabled(after id: ID) -> ID? {
        let ids = items.map(\.id)
        guard let index = ids.firstIndex(of: id) else { return nil }
        guard index + 1 < ids.count else { return nil }

        for index in (index + 1)..<ids.count {
            let candidate = ids[index]
            if isEnabled(candidate) { return candidate }
        }
        return nil
    }

    private func previousEnabled(before id: ID) -> ID? {
        let ids = items.map(\.id)
        guard let index = ids.firstIndex(of: id) else { return nil }
        guard index - 1 >= 0 else { return nil }

        for index in stride(from: index - 1, through: 0, by: -1) {
            let candidate = ids[index]
            if isEnabled(candidate) { return candidate }
        }
        return nil
    }

    private func focusOnEntry(_ direction: TagMoveDirection) -> Bool {
        if let anchor = anchorTagID, !isEnabled(anchor) {
            anchorTagID = nil
        }

        let targetID: ID? = {
            if let anchor = anchorTagID {
                switch direction {
                case .next:
                    return nextEnabled(after: anchor) ?? firstEnabledID()
                case .previous:
                    return previousEnabled(before: anchor) ?? lastEnabledID()
                }
            } else {
                switch direction {
                case .next: return firstEnabledID()
                case .previous: return lastEnabledID()
                }
            }
        }()

        guard let id = targetID else { return false }
        focusedTagID = id
        anchorTagID = id
        return true
    }

    @discardableResult
    private func moveFocus(_ direction: TagMoveDirection, wrapping: Bool) -> Bool {
        guard !items.isEmpty else { return false }

        let ids = items.map(\.id)

        let currentID: ID = {
            if let id = focusedTagID { return id }
            if let id = anchorTagID { return id }
            if let id = lastSelection { return id }
            if let id = currentSelectionAnchor() { return id }
            return firstEnabledID() ?? ids.first!
        }()

        guard let currentIndex = ids.firstIndex(of: currentID) else {
            if let first = firstEnabledID() {
                focusedTagID = first
                anchorTagID = first
                return true
            }
            return false
        }

        if wrapping {
            func nextIndex(_ index: Int) -> Int {
                switch direction {
                case .next: return (index + 1) % ids.count
                case .previous: return (index - 1 + ids.count) % ids.count
                }
            }

            var newIndex = nextIndex(currentIndex)
            for _ in 0..<ids.count {
                let candidate = ids[newIndex]
                if isEnabled(candidate) {
                    focusedTagID = candidate
                    anchorTagID = candidate
                    return true
                }
                newIndex = nextIndex(newIndex)
            }
            return false
        }

        switch direction {
        case .next:
            guard currentIndex + 1 < ids.count else { return false }
            for index in (currentIndex + 1)..<ids.count {
                let candidate = ids[index]
                if isEnabled(candidate) {
                    focusedTagID = candidate
                    anchorTagID = candidate
                    return true
                }
            }
            return false

        case .previous:
            guard currentIndex - 1 >= 0 else { return false }
            for index in stride(from: currentIndex - 1, through: 0, by: -1) {
                let candidate = ids[index]
                if isEnabled(candidate) {
                    focusedTagID = candidate
                    anchorTagID = candidate
                    return true
                }
            }
            return false
        }
    }

    private func activateFocused() {
        let id: ID? = focusedTagID ?? anchorTagID ?? lastSelection ?? currentSelectionAnchor()
        guard let id, isEnabled(id) else { return }

        toggleSelection(id)

        focusedTagID = id
        anchorTagID = id

        showsKeyboardFocus = true

        MainActor.assumeIsolated {
            FocusableTagsFocusCoordinator.shared.activeHostID = identity.id
        }

        isKeyHostFocused = true
    }
}
