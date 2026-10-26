import UIKit

@MainActor
final class ReportPageWriter {
    static let page = CGRect(x: 0, y: 0, width: 612, height: 792)
    private let context: UIGraphicsPDFRendererContext
    private let subtitle: String
    private var pageNumber = 0
    private var y: CGFloat = 92
    private let left: CGFloat = 48
    private let width: CGFloat = 516
    private let bottom: CGFloat = 680
    private let ink = UIColor(red: 0.13, green: 0.24, blue: 0.20, alpha: 1)

    init(context: UIGraphicsPDFRendererContext, subtitle: String) {
        self.context = context; self.subtitle = subtitle
    }

    func newPage(_ title: String) {
        context.beginPage(); pageNumber += 1; y = 92
        draw(Loc.t("Bearing movement summary"), at: 46, font: .boldSystemFont(ofSize: 11), color: ink)
        draw(subtitle, at: 64, font: .systemFont(ofSize: 9), color: .darkGray)
        draw(Loc.f("Page %lld", pageNumber), at: 692, font: .systemFont(ofSize: 9), color: .darkGray)
        draw(Strings.disclaimer, at: 710, font: .boldSystemFont(ofSize: 9), color: ink)
        text(title, size: 20, bold: true, gap: 0)
    }

    private func draw(_ value: String, at top: CGFloat, font: UIFont, color: UIColor) {
        (value as NSString).draw(in: CGRect(x: left, y: top, width: width, height: 28),
                                withAttributes: [.font: font, .foregroundColor: color])
    }

    func text(_ value: String, size: CGFloat = 11, bold: Bool = false, gap: CGFloat = 7) {
        guard !value.isEmpty else { return }
        let attributes: [NSAttributedString.Key: Any] = [
            .font: bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size),
            .foregroundColor: ink
        ]
        func height(_ value: String) -> CGFloat {
            ceil((value as NSString).boundingRect(with: CGSize(width: width, height: .greatestFiniteMagnitude),
                 options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil).height)
        }
        var remaining = Array(value)
        var spacing = gap
        while !remaining.isEmpty {
            if bottom - y - spacing < size * 2 { newPage(Loc.t("Continued")) }
            let room = bottom - y - spacing
            var count = remaining.count
            if height(String(remaining)) > room {
                var low = 1, high = remaining.count
                while low < high {
                    let middle = (low + high + 1) / 2
                    if height(String(remaining.prefix(middle))) <= room { low = middle } else { high = middle - 1 }
                }
                count = low
                if let boundary = remaining.prefix(count).lastIndex(where: { $0.isWhitespace }), boundary > 0 { count = boundary + 1 }
            }
            let part = String(remaining.prefix(count))
            let partHeight = height(part)
            y += spacing
            (part as NSString).draw(in: CGRect(x: left, y: y, width: width, height: partHeight), withAttributes: attributes)
            y += partHeight
            remaining.removeFirst(count)
            spacing = 0
            if !remaining.isEmpty { newPage(Loc.t("Continued")) }
        }
    }

    func reserve(_ height: CGFloat) {
        if y + height > bottom { newPage(Loc.t("Continued")) }
    }

    func section(_ title: String) {
        reserve(150)
        text(title, size: 20, bold: true, gap: 20)
    }

    func heading(_ title: String) {
        if y + 70 > bottom { newPage(Loc.t("Continued")) }
        text(title, size: 14, bold: true, gap: 16)
    }

    func row(_ title: String, _ value: String) { text(title + ": " + value) }
    func rule() {
        if y + 12 > bottom { newPage(Loc.t("Continued")) }
        y += 8
        let path = UIBezierPath(); path.move(to: CGPoint(x: left, y: y)); path.addLine(to: CGPoint(x: left + width, y: y))
        UIColor.lightGray.setStroke(); path.lineWidth = 0.4; path.stroke(); y += 4
    }
}
