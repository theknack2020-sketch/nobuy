import SwiftUI
import Testing
import UIKit
@testable import NoBuy

@Suite("White-on-fill contrast (WCAG AA)")
struct ColorContrastTests {
    private func contrastWithWhite(_ color: UIColor, dark: Bool) -> Double {
        let traits = UITraitCollection(userInterfaceStyle: dark ? .dark : .light)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
        func lin(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        let luminance = 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
        return 1.05 / (luminance + 0.05)
    }

    @Test("Calendar fills carry white body text at ≥4.5:1 in both appearances")
    func calendarFillsMeetAA() {
        let fills: [(String, UIColor)] = [
            ("noBuyGreen", UIColor(Color.noBuyGreen)),
            ("spendRed", UIColor(Color.spendRed)),
            ("mandatoryAmber", UIColor(Color.mandatoryAmber)),
            ("freezeBlue", UIColor(Color.freezeBlue)),
        ]
        for (name, fill) in fills {
            #expect(contrastWithWhite(fill, dark: false) >= 4.5, "\(name) light fails AA")
            #expect(contrastWithWhite(fill, dark: true) >= 4.5, "\(name) dark fails AA")
        }
    }
}
