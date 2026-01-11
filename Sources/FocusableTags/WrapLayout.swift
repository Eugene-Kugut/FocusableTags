import SwiftUI

struct WrapLayout: Layout {
    let spacing: CGFloat
    let alignment: HorizontalAlignment

    // MARK: - Layout

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = makeRows(subviews: subviews, maxWidth: maxWidth, proposal: proposal)

        var totalHeight: CGFloat = 0
        var maxRowWidth: CGFloat = 0

        for (i, row) in rows.enumerated() {
            maxRowWidth = max(maxRowWidth, row.width)
            totalHeight += row.height
            if i != rows.count - 1 { totalHeight += spacing }
        }

        // Если proposal.width задан — обычно логично "занять" его,
        // но сам Layout может вернуть и контентную ширину.
        // Оставим контентную ширину (как у тебя было).
        return CGSize(width: maxRowWidth, height: totalHeight)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let maxWidth = proposal.width ?? bounds.width
        let rows = makeRows(subviews: subviews, maxWidth: maxWidth, proposal: proposal)

        var y = bounds.minY

        for row in rows {
            let xOffset: CGFloat = {
                let free = max(0, bounds.width - row.width)
                switch alignment {
                case .leading:
                    return 0
                case .center:
                    return free / 2
                case .trailing:
                    return free
                default:
                    return 0
                }
            }()

            var x = bounds.minX + xOffset

            for item in row.items {
                let size = item.size
                item.subview.place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(width: size.width, height: size.height)
                )
                x += size.width + spacing
            }

            y += row.height + spacing
        }
    }

    // MARK: - Row building

    private struct RowItem {
        let subview: Subviews.Element
        let size: CGSize
    }

    private struct Row {
        var items: [RowItem] = []
        var width: CGFloat = 0      // точная ширина строки (без "лишнего" spacing в конце)
        var height: CGFloat = 0
    }

    private func makeRows(
        subviews: Subviews,
        maxWidth: CGFloat,
        proposal: ProposedViewSize
    ) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        func commitRowIfNeeded() {
            if !current.items.isEmpty {
                rows.append(current)
                current = Row()
            }
        }

        for subview in subviews {
            // ВАЖНО: меряем без "максимальной ширины строки" внутри каждого subview,
            // чтобы не раздувать размеры (особенно Text).
            let size = subview.sizeThatFits(ProposedViewSize(width: nil, height: proposal.height))

            let proposedWidthForAppend: CGFloat = current.items.isEmpty
                ? size.width
                : current.width + spacing + size.width

            if proposedWidthForAppend > maxWidth, !current.items.isEmpty {
                commitRowIfNeeded()
            }

            if current.items.isEmpty {
                current.items.append(.init(subview: subview, size: size))
                current.width = size.width
                current.height = size.height
            } else {
                current.items.append(.init(subview: subview, size: size))
                current.width += spacing + size.width
                current.height = max(current.height, size.height)
            }
        }

        commitRowIfNeeded()
        return rows
    }
}
