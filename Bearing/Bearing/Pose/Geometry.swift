import CoreGraphics
import Foundation

enum Geometry {
    // Use pixel coordinates so the image aspect ratio does not distort the angle.
    static func angleDegrees(vertex: CGPoint, a: CGPoint, b: CGPoint) -> Double? {
        let v1 = CGVector(dx: a.x - vertex.x, dy: a.y - vertex.y)
        let v2 = CGVector(dx: b.x - vertex.x, dy: b.y - vertex.y)
        let magnitude = hypot(v1.dx, v1.dy) * hypot(v2.dx, v2.dy)
        guard magnitude.isFinite, magnitude > 0 else { return nil }
        let cosine = (v1.dx * v2.dx + v1.dy * v2.dy) / magnitude
        return acos(max(-1.0, min(1.0, Double(cosine)))) * 180.0 / .pi
    }

    // Pixel coordinates have Y pointing up.
    static func leanFromVerticalDegrees(top: CGPoint, bottom: CGPoint) -> Double {
        let dx = Double(top.x - bottom.x)
        let dy = Double(top.y - bottom.y)
        return abs(atan2(dx, dy)) * 180.0 / .pi
    }

    static func midpoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    static func pixelPoint(_ normalized: CGPoint, size: CGSize) -> CGPoint {
        CGPoint(x: normalized.x * size.width, y: normalized.y * size.height)
    }

    static func displayPoint(_ pixel: CGPoint, image: CGSize, view: CGSize, mirrored: Bool = true) -> CGPoint {
        CGPoint(x: (mirrored ? 1 - pixel.x / image.width : pixel.x / image.width) * view.width,
                y: (1 - pixel.y / image.height) * view.height)
    }

    static func median(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        let s = values.sorted()
        let mid = s.count / 2
        return s.count % 2 == 0 ? (s[mid - 1] + s[mid]) / 2 : s[mid]
    }
}
