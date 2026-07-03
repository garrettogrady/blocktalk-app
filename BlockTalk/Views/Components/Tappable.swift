import SwiftUI

/// A button style that applies 0.6 opacity on press.
struct TappableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    /// Wraps the view in a Button with the Tappable press effect (0.6 opacity on press).
    func tappable(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            self
        }
        .buttonStyle(TappableButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack(spacing: BTSpacing.xl) {
            Text("Tap me")
                .font(BTFont.bodySemibold(size: 16))
                .foregroundStyle(Color.btText)
                .padding()
                .background(Color.btSurface)
                .cornerRadius(BTRadius.md)
                .tappable { }

            Button("Button Style") { }
                .buttonStyle(TappableButtonStyle())
                .font(BTFont.bodySemibold(size: 16))
                .foregroundStyle(Color.btBg)
                .padding()
                .background(Color.btLime)
                .cornerRadius(BTRadius.md)
        }
    }
}
