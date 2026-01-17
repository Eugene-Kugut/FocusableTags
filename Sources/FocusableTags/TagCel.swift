import SwiftUI

struct TagCell<Label: View>: View {
    let label: () -> Label

    let isEnabled: Bool
    let isSelected: Bool
    let isFocused: Bool

    let backgroundColor: (_ isSelected: Bool, _ isFocused: Bool, _ isHovered: Bool) -> Color
    let focusedOverlay: Color
    let focusedOverlayLineWidth: CGFloat
    let overlayColor: Color
    let overlayLineWidth: CGFloat
    let contentInsets: NSEdgeInsets
    let cornerRadius: CGFloat
    let onClick: () -> Void

    @State private var isHovered = false

    var body: some View {
        label()
            .lineLimit(1)
            .padding(.top, contentInsets.top)
            .padding(.bottom, contentInsets.bottom)
            .padding(.leading, contentInsets.left)
            .padding(.trailing, contentInsets.right)
            .contentShape(Rectangle())
            .onHover { isHovered = $0 }
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(backgroundColor(isSelected, isFocused, isHovered))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isFocused ? focusedOverlay : overlayColor,
                        lineWidth: isFocused ? focusedOverlayLineWidth : overlayLineWidth
                    )
            }
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.easeOut(duration: 0.12), value: isHovered)
            .opacity(isEnabled ? 1.0 : 0.45)
            .onTapGesture {
                guard isEnabled else { return }
                onClick()
            }
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
    }
}

