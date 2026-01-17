# FocusableTags

**FocusableTags** is a SwiftUI control for macOS that provides keyboard-focusable tags with full AppKit key-view loop integration and **multi-selection** support.

- Multiple selection (`Set<ID>`)
- Full keyboard navigation:
  - `Tab` / `Shift+Tab` — enter / leave the control
  - `←` `→` — cyclic navigation between tags
  - `Space` / `Enter` — toggle selection
- Proper **AppKit key-view loop** behavior
- Correct focus handling on mouse interaction
- Hover states
- Automatic line wrapping (`WrapLayout`)

<p float="left">
  <img src="screenshots/selected.png" width="500" />
  <img src="screenshots/focused.png" width="500" />
  <img src="screenshots/hovered.png" width="500" />
</p>

## Installation (Swift Package Manager)

File → Add Packages Dependencies… → https://github.com/Eugene-Kugut/FocusableTags.git


## Usage

```swift
import SwiftUI
import FocusableTags

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
                            Image(systemName: "plus")
                                .font(.body)
                                .fontWeight(selection.contains(tag) ? .bold : .medium)
                                .foregroundStyle(selection.contains(tag) ? .white.opacity(0.8) : .accentColor)
                                .rotationEffect(.degrees(selection.contains(tag) ? 45 : 0))
                                .animation(.snappy(duration: 0.3), value: selection)
                            Text(tag.rawValue)
                                .font(.body)
                                .foregroundStyle(selection.contains(tag) ? .white : .primary)
                        })
                    }
            },
            selection: $selection,
            selectedBackground: .accentColor,
            overlayColor: .accentColor,
            horizontalSpacing: 4,
            verticalSpacing: 4
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
    overlayColor: .clear,
    overlayLineWidth: 1 / 3,
    contentInsets: NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 12),
    horizontalSpacing: 4,
    verticalSpacing: 4,
    cornerRadius: 8,
    alignment: .leading
)
```
