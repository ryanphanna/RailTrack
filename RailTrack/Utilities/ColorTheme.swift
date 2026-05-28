import SwiftUI

// MARK: - Color Palette

enum ColorTheme {
    // Brand
    static let accent       = Color("AccentBlue")       // Primary interactive
    static let accentGreen  = Color("AccentGreen")      // On-time indicator
    static let accentAmber  = Color("AccentAmber")      // Delay warning
    static let accentRed    = Color("AccentRed")        // Cancellation / error

    // Surfaces
    static let background   = Color("Background")       // App background
    static let surface      = Color("Surface")          // Cards
    static let surfaceHigh  = Color("SurfaceHigh")      // Elevated cards

    // Text
    static let textPrimary   = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let textTertiary  = Color("TextTertiary")

    // Operator brand colours (hex fallbacks)
    static let via    = Color(hex: "#005DAA")
    static let amtrak = Color(hex: "#004B87")
    static let go     = Color(hex: "#00A651")

    static func operatorColor(for op: String) -> Color {
        switch op {
        case "VIA":    return via
        case "Amtrak": return amtrak
        case "GO":     return go
        default:       return textSecondary
        }
    }
}

// MARK: - Hex Initialiser

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Typography

extension Font {
    // Display
    static let rtTitle    = Font.system(size: 28, weight: .bold, design: .rounded)
    static let rtHeadline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let rtSubhead  = Font.system(size: 16, weight: .medium, design: .rounded)
    static let rtBody     = Font.system(size: 15, weight: .regular, design: .rounded)
    static let rtCaption  = Font.system(size: 12, weight: .medium, design: .rounded)
    static let rtMono     = Font.system(size: 14, weight: .semibold, design: .monospaced)
}
