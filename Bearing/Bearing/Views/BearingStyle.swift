import SwiftUI

enum BearingStyle {
    static let paper = adaptive(0xF6F5EF, 0x131C19)
    static let surface = adaptive(0xFFFFFF, 0x202C26)
    static let ink = adaptive(0x203C32, 0xF0F3EB)
    static let muted = adaptive(0x52645B, 0xB9C9BF)
    static let wash = adaptive(0xE6EDE4, 0x2B3D32)
    static let line = adaptive(0xD4DDD3, 0x45574B)
    static let danger = adaptive(0x9F302B, 0xFFB4A8)
    static let onAccent = adaptive(0xFFFFFF, 0x14251C)

    private static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
}

struct BearingPage<Content: View>: View {
    @ViewBuilder let content: Content
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) { content }
                .frame(maxWidth: 600, alignment: .leading)
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 32)
                .frame(maxWidth: .infinity)
        }
        .background(BearingStyle.paper)
        .buttonStyle(.automatic)
        .foregroundStyle(BearingStyle.ink)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BearingPrimaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.labelStyle(BearingActionLabelStyle()).font(.headline).multilineTextAlignment(.center)
            .padding(.horizontal, 20).padding(.vertical, 18)
            .frame(maxWidth: .infinity, minHeight: 58)
            .foregroundStyle(isEnabled ? BearingStyle.onAccent : BearingStyle.muted)
            .background(isEnabled ? Color.accentColor : BearingStyle.wash,
                        in: RoundedRectangle(cornerRadius: 18))
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

struct BearingSecondaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.labelStyle(BearingActionLabelStyle()).font(.headline).multilineTextAlignment(.center)
            .padding(.horizontal, 16).padding(.vertical, 16)
            .frame(maxWidth: .infinity, minHeight: 54)
            .foregroundStyle(Color.accentColor)
            .background(BearingStyle.wash.opacity(configuration.isPressed ? 0.6 : 1),
                        in: RoundedRectangle(cornerRadius: 18))
    }
}

private struct BearingActionLabelStyle: LabelStyle {
    @Environment(\.dynamicTypeSize) private var typeSize
    func makeBody(configuration: Configuration) -> some View {
        if typeSize.isAccessibilitySize {
            configuration.title
        } else {
            HStack(spacing: 10) { configuration.icon; configuration.title }
        }
    }
}

struct SectionCaption: View {
    let title: LocalizedStringKey
    var body: some View {
        Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(BearingStyle.muted)
            .accessibilityAddTraits(.isHeader)
    }
}

struct PrivacyNote: View {
    var body: some View {
        Text(Strings.disclaimer).font(.footnote).foregroundStyle(BearingStyle.ink)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct InstructionRow: View {
    let number: Int
    let title: LocalizedStringKey
    let detail: String
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(number.formatted()).font(.subheadline.weight(.semibold)).monospacedDigit()
                .frame(width: 30, height: 30).background(BearingStyle.wash, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                if title != "" { Text(title).font(.headline) }
                Text(detail).font(.body).foregroundStyle(BearingStyle.muted)
            }
        }.accessibilityElement(children: .combine)
    }
}

struct BearingMark: View {
    var body: some View {
        ZStack {
            Circle().trim(from: 0.1, to: 0.9).stroke(Color.accentColor.opacity(0.22), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(90)).padding(5)
            Path { path in
                path.move(to: CGPoint(x: 23, y: 39))
                path.addLine(to: CGPoint(x: 23, y: 23))
                path.addLine(to: CGPoint(x: 36, y: 10))
            }.stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            Circle().fill(Color.accentColor).frame(width: 7, height: 7)
        }.frame(width: 46, height: 46).accessibilityHidden(true)
    }
}

private struct ReturnHomeKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}
extension EnvironmentValues {
    var returnHome: () -> Void {
        get { self[ReturnHomeKey.self] }
        set { self[ReturnHomeKey.self] = newValue }
    }
}
