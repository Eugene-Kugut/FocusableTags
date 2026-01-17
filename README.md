# FocusableTags

**FocusableTags** is a SwiftUI control for macOS that provides keyboard-focusable tags with full AppKit key-view loop integration and **multi-selection** support.

- FocusableTags is a keyboard-driven tag list for macOS SwiftUI with a “keyboard focus only” behavior.
- Layout: tags are arranged in a wrapping (multi-line) layout and can be aligned leading / center / trailing.
- Selection: supports multi-selection (Binding<Set<ID>>). Clicking a tag toggles its selection.
- Focus model: visual focus appears only after keyboard interaction (Tab / Ctrl+Tab / arrow keys). Mouse clicks do not show the keyboard focus ring.
- Entering focus (Tab): when FocusableTags becomes the first responder via Tab traversal, it chooses a reasonable starting tag (anchor / last selection / first enabled) and highlights it.
- Ctrl+Tab navigation: Ctrl+Tab / Ctrl+Shift+Tab moves focus between tags (wraps around), without leaving the control.
- Arrow navigation: Left / Right moves focus to previous / next enabled tag. If there is no next/previous tag, focus does not wrap.
- Activate: Space / Return / Enter toggles selection for the currently focused tag.
- Outside click: clicking anywhere outside the control clears focus (and hides keyboard focus).


<p float="left">
  <img src="screenshots/selected.png" width="500" />
  <img src="screenshots/focused.png" width="500" />
  <img src="screenshots/hovered.png" width="500" />
</p>

## Installation (Swift Package Manager)

File → Add Packages Dependencies… → https://github.com/Eugene-Kugut/FocusableTags.git


## Usage

```swift
enum DemoTag: String, CaseIterable, Hashable {
    case swift = "Swift"
    case kotlin = "Kotlin"
    case cpp = "C++"
    case phyton = "Phyton"
    case php = "PHP"
    case pascal = "Pascal"
    case js = "Java Script"
    case java = "Java"
    case asm = "Assembler"
    case basic = "Basic"
}

struct DemoView: View {
    @State private var selection: Set<DemoTag> = [.java, .kotlin]

    var body: some View {
        FocusableTags(
            items: DemoTag.allCases.map { tag in
                    .init(tag) {
                        HStack(spacing: 8, content: {
                            Text(tag.rawValue)
                                .font(.body)
                                .foregroundStyle(selection.contains(tag) ? .white : .primary)
                            Image(systemName: "plus")
                                .font(.body)
                                .fontWeight(selection.contains(tag) ? .medium : .medium)
                                .foregroundStyle(selection.contains(tag) ? Color.white : Color.accentColor)
                                .rotationEffect(.degrees(selection.contains(tag) ? 45 : 0))
                                .animation(.snappy(duration: 0.3), value: selection)
                        })
                    }
            },
            selection: $selection,
            selectedBackground: .indigo,
            focusedBackground: Color.accentColor.opacity(0.2),
            hoveredBackground: Color(NSColor.secondarySystemFill).opacity(0.8),
            selectedOverlayColor: .primary.opacity(0.2),
            overlayColor: .primary.opacity(0.1),
            overlayLineWidth: 1,
            horizontalSpacing: 6,
            verticalSpacing: 4,
        )
        .padding(.horizontal)
        .padding(.vertical)
    }
}

```

## Customization

```swift
FocusableTags(
    items: items,
    selection: $selection,
    selectedBackground: Color.primary.opacity(0.10),
    focusedBackground: Color.accentColor.opacity(0.12),
    hoveredBackground: Color.primary.opacity(0.06),
    focusedOverlay: Color.accentColor.opacity(0.9),
    focusedOverlayLineWidth: 1.5,
    selectedOverlayColor: .clear,
    overlayColor: .blue,
    overlayLineWidth: 1,
    contentInsets: NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12),
    horizontalSpacing: 4,
    verticalSpacing: 4,
    cornerRadius: 8,
    alignment: .leading
)
```
