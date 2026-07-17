import SwiftUI

enum BTFont {
    // Space Grotesk (variable font)
    static func display(size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Bold", size: size, relativeTo: .title)
    }

    static func displayMedium(size: CGFloat) -> Font {
        .custom("SpaceGrotesk-Medium", size: size, relativeTo: .title2)
    }

    // Inter
    static func body(size: CGFloat) -> Font {
        .custom("Inter-Regular", size: size, relativeTo: .body)
    }

    static func bodyMedium(size: CGFloat) -> Font {
        .custom("Inter-Medium", size: size, relativeTo: .body)
    }

    static func bodySemibold(size: CGFloat) -> Font {
        .custom("Inter-SemiBold", size: size, relativeTo: .body)
    }

    static func bodyBold(size: CGFloat) -> Font {
        .custom("Inter-Bold", size: size, relativeTo: .body)
    }

    // JetBrains Mono (variable font)
    static func mono(size: CGFloat) -> Font {
        .custom("JetBrainsMono-Medium", size: size, relativeTo: .caption)
    }

    static func monoBold(size: CGFloat) -> Font {
        .custom("JetBrainsMono-Bold", size: size, relativeTo: .caption)
    }
}

struct FontRegistration {
    static func registerFonts() {
        // Variable fonts - each file contains all weights
        let fontFiles = [
            "SpaceGrotesk-Bold",   // Variable: contains Light through Bold
            "SpaceGrotesk-Medium", // Same variable font
            "Inter-Regular",       // Variable: contains Thin through Black
            "Inter-Medium",
            "Inter-SemiBold",
            "Inter-Bold",
            "JetBrainsMono-Medium", // Variable: contains Thin through ExtraBold
            "JetBrainsMono-Bold",
        ]

        for name in fontFiles {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                print("Warning: Font \(name).ttf not found in bundle")
                continue
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                if let error = error?.takeRetainedValue() {
                    print("Font registration error for \(name): \(error)")
                }
            }
        }
    }
}
