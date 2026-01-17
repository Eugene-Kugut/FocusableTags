import SwiftUI

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
                                .fontWeight(.medium)
                                .rotationEffect(.degrees(selection.contains(tag) ? 45 : 0))
                                .animation(.snappy(duration: 0.3), value: selection)
                            Text(tag.rawValue)
                                .font(.body)
                                .foregroundStyle(selection.contains(tag) ? .primary : .secondary)
                        })
                    }
            },
            selection: $selection,
            overlayColor: .primary.opacity(0.3),
            horizontalSpacing: 4,
            verticalSpacing: 4
        )
    }
}

#Preview {
    DemoView()
}
