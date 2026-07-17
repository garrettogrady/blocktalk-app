import SwiftUI

// Single tap handler shared by every gate surface (§17). Re-checks live
// permission first, then:
//   - granted     → no-op (gate disappears on next render)
//   - denied      → deep-link to iOS Settings
//   - undetermined → branded pre-frame sheet
@MainActor
func locationGateTap(_ location: LocationService, showPreFrame: Binding<Bool>) {
    location.checkPermission()
    switch location.permissionState {
    case .granted:
        break
    case .denied:
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    default:
        showPreFrame.wrappedValue = true
    }
}

// MARK: - Gate Bar (compose-bar replacement)

/// Bottom-of-screen replacement for compose bars on Feed / Post Detail /
/// Pin Detail / Daily Prompt Feed when location isn't granted. Echoes the
/// compose bar's footprint so the layout doesn't jump.
struct LocationGateBar: View {
    @Environment(LocationService.self) private var location
    var label: String?
    @Binding var showPreFrame: Bool

    private var text: String {
        if let label { return label }
        return location.permissionState == .denied
            ? "Location is off. Open Settings to enable."
            : "Enable location to join the conversation"
    }

    var body: some View {
        Button {
            locationGateTap(location, showPreFrame: $showPreFrame)
        } label: {
            HStack(spacing: BTSpacing.sm) {
                HStack(spacing: BTSpacing.sm) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.btWarn)
                    Text(text)
                        .font(BTFont.bodySemibold(size: 12))
                        .foregroundStyle(Color.btText)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .frame(height: 38)
                .padding(.horizontal, BTSpacing.md)
                .background(Color.btSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: BTRadius.lg)
                        .stroke(Color.btWarn.opacity(0.35), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))

                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.btOnAccent)
                    .frame(width: 38, height: 38)
                    .background(Color.btWarn)
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg))
            }
            .padding(.horizontal, BTSpacing.md)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            // Opaque base that runs through the home-indicator strip so feed
            // content can't show through the bar or peek out beneath it.
            .background {
                Color.btBg.overlay(Color.btWarn.opacity(0.08))
                    .ignoresSafeArea(.container, edges: .bottom)
            }
            .overlay(alignment: .top) {
                Rectangle().fill(Color.btWarn.opacity(0.45)).frame(height: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Gate Banner (thin Feed-top strip)

struct LocationGateBanner: View {
    @Environment(LocationService.self) private var location
    @Binding var showPreFrame: Bool

    var body: some View {
        if location.permissionState != .granted {
            Button {
                locationGateTap(location, showPreFrame: $showPreFrame)
            } label: {
                HStack(spacing: BTSpacing.xs) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 11))
                    Text(location.permissionState == .denied
                         ? "location is off · viewing only · tap to open Settings"
                         : "location is off · viewing only · tap to enable")
                        .font(BTFont.bodyBold(size: 10.5))
                        .tracking(0.5)
                }
                .foregroundStyle(Color.btWarn)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, BTSpacing.lg)
                .padding(.vertical, 7)
                .background(Color.btWarn.opacity(0.1))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Pre-Frame Sheet

/// Branded bottom sheet shown before iOS's system permission dialog. Sets the
/// tone in BlockTalk's voice. Present via `.sheet(isPresented:)`.
struct LocationPreFrameSheet: View {
    @Environment(LocationService.self) private var location
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Icon — centered hero
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.btLime.opacity(0.12))
                    .frame(width: 68, height: 68)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.btLime.opacity(0.35), lineWidth: 1)
                    )
                Image(systemName: "location.fill")
                    .font(.system(size: 27))
                    .foregroundStyle(Color.btLime)
            }
            .padding(.top, BTSpacing.xl)
            .padding(.bottom, BTSpacing.lg)

            // Heading + subheading — centered
            Text("Turn on location to post")
                .font(BTFont.display(size: 24))
                .tracking(-0.5)
                .foregroundStyle(Color.btText)
                .multilineTextAlignment(.center)
            Text("BlockTalk is neighborhood-locked — here's how it works.")
                .font(BTFont.body(size: 13.5))
                .foregroundStyle(Color.btText2)
                .multilineTextAlignment(.center)
                .padding(.top, BTSpacing.xs)
                .padding(.horizontal, BTSpacing.sm)
                .padding(.bottom, BTSpacing.xl)

            // Benefit rows — icon badge + title + subtitle
            VStack(spacing: BTSpacing.md) {
                benefitRow("mappin.and.ellipse", "Post & reply where you are",
                           "Only from inside the neighborhood")
                benefitRow("eye.fill", "Browse & vote anywhere",
                           "No location needed to read along")
                benefitRow("lock.fill", "Your exact spot stays private",
                           "Never shown to anyone, ever")
            }

            Spacer(minLength: BTSpacing.lg)

            // Primary + secondary actions
            Button {
                dismiss()
                Task {
                    try? await Task.sleep(for: .milliseconds(220))
                    location.checkPermission()
                    if location.permissionState != .granted {
                        location.requestPermission()
                    }
                }
            } label: {
                Text("Enable Location")
                    .font(BTFont.bodyBold(size: 15))
                    .tracking(0.2)
                    .foregroundStyle(Color.btOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.btLime)
                    .clipShape(RoundedRectangle(cornerRadius: BTRadius.lg, style: .continuous))
            }
            .buttonStyle(.plain)

            Button { dismiss() } label: {
                Text("Not now")
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btText3)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, BTSpacing.xs)
        }
        .padding(.horizontal, BTSpacing.xl)
        .padding(.bottom, BTSpacing.lg)
        .frame(maxWidth: .infinity)
        .background(Color.btBg)
        .presentationDetents([.height(540)])
        .presentationDragIndicator(.visible)
    }

    private func benefitRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundStyle(Color.btLime)
                .frame(width: 40, height: 40)
                .background(Color.btLime.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.btLime.opacity(0.22), lineWidth: 1)
                )
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(BTFont.bodySemibold(size: 14))
                    .foregroundStyle(Color.btText)
                Text(subtitle)
                    .font(BTFont.body(size: 12))
                    .foregroundStyle(Color.btText3)
            }
            Spacer(minLength: 0)
        }
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack {
            LocationGateBanner(showPreFrame: .constant(false))
            Spacer()
            LocationGateBar(showPreFrame: .constant(false))
        }
    }
    .environment(LocationService())
}
