import SwiftUI

extension Color {
    static let btBg = Color(hex: 0x000000)
    static let btSurface = Color(hex: 0x0E0E11)
    static let btSurface2 = Color(hex: 0x16161B)
    static let btElev = Color(hex: 0x1C1C22)
    static let btLine = Color(hex: 0x26262E)
    static let btLine2 = Color(hex: 0x33333D)
    static let btText = Color(hex: 0xF5F5F7)
    static let btText2 = Color(hex: 0x9A9AA3)
    static let btText3 = Color(hex: 0x7A7A82)
    static let btMuted = Color(hex: 0x3D3D46)
    static let btLime = Color(hex: 0xD8FF3D)
    static let btLimeDim = Color(hex: 0x9CB82A)
    static let btPink = Color(hex: 0xFF3D6E)
    static let btPinkDim = Color(hex: 0xA82747)
    static let btHouse = Color(hex: 0x7CD9FF)
    static let btWarn = Color(hex: 0xFFB13D)
    static let btOnAccent = Color(hex: 0x0A0A0C)

    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
