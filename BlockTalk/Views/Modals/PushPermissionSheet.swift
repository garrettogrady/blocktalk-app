import SwiftUI

struct PushPermissionSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: BTSpacing.xl) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.btLime)

            VStack(spacing: BTSpacing.sm) {
                Text("Want to know when\npeople reply?")
                    .font(BTFont.display(size: 24))
                    .foregroundStyle(Color.btText)
                    .multilineTextAlignment(.center)

                Text("We'll only notify you about posts you follow — never spam.")
                    .font(BTFont.body(size: 14))
                    .foregroundStyle(Color.btText2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BTSpacing.xl)
            }

            Spacer()

            VStack(spacing: BTSpacing.md) {
                Button {
                    pushManager.requestPermission()
                    Analytics.pushSoftAskAccepted()
                    dismiss()
                } label: {
                    Text("Turn on")
                        .font(BTFont.bodyBold(size: 16))
                        .foregroundStyle(Color.btOnAccent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.btLime)
                        .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
                }
                .buttonStyle(.plain)

                Button {
                    Analytics.pushSoftAskDeclined()
                    dismiss()
                } label: {
                    Text("Not now")
                        .font(BTFont.bodyMedium(size: 14))
                        .foregroundStyle(Color.btText2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, BTSpacing.xl)
            .padding(.bottom, BTSpacing.xxxl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.btBg.ignoresSafeArea())
        .onAppear {
            Analytics.pushSoftAskShown()
        }
    }
}

#Preview {
    PushPermissionSheet()
        .preferredColorScheme(.dark)
}
