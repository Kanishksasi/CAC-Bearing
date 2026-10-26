import XCTest
import SwiftUI
@testable import Bearing

final class DesignContrastTests: XCTestCase {
    @MainActor
    func testTextPaletteMeetsContrastInBothAppearances() throws {
        for appearance in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: appearance)
            let accent = try XCTUnwrap(UIColor(named: "AccentColor", in: .main, compatibleWith: traits))
                .resolvedColor(with: traits)
            let surfaces = [BearingStyle.paper, BearingStyle.surface, BearingStyle.wash]
            for foreground in [BearingStyle.ink, BearingStyle.muted, BearingStyle.danger] {
                for background in surfaces {
                    XCTAssertGreaterThanOrEqual(ratio(resolve(foreground, traits), resolve(background, traits)), 4.5)
                }
            }
            XCTAssertGreaterThanOrEqual(ratio(resolve(BearingStyle.onAccent, traits), accent), 4.5)
            for background in surfaces {
                XCTAssertGreaterThanOrEqual(ratio(accent, resolve(background, traits)), 4.5)
            }
        }
    }

    private func resolve(_ color: Color, _ traits: UITraitCollection) -> UIColor {
        UIColor(color).resolvedColor(with: traits)
    }

    private func ratio(_ first: UIColor, _ second: UIColor) -> Double {
        let values = [luminance(first), luminance(second)].sorted()
        return (values[1] + 0.05) / (values[0] + 0.05)
    }

    private func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &alpha)
        func linear(_ channel: CGFloat) -> Double {
            let value = Double(channel)
            return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }
}
