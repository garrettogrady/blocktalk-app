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
            .background(Color.btWarn.opacity(0.08))
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
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 22))
                .foregroundStyle(Color.btLime)
                .frame(width: 52, height: 52)
                .background(Color.btLime.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.btLime.opacity(0.4), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.bottom, BTSpacing.lg)

            Text("Turn on location to post or reply.")
                .font(BTFont.display(size: 22))
                .foregroundStyle(Color.btText)
                .tracking(-0.5)
            Text("BlockTalk is location-locked. Here's why we ask.")
                .font(BTFont.body(size: 13))
                .foregroundStyle(Color.btText2)
                .padding(.top, 6)

            Rectangle().fill(Color.btLine).frame(height: 1)
                .padding(.top, BTSpacing.lg)

            VStack(alignment: .leading, spacing: 10) {
                bullet("Posting + replying", "needs presence in the neighborhood")
                bullet("Viewing + voting", "works from anywhere")
                bullet("Your exact location", "never shown to anyone")
            }
            .padding(.top, BTSpacing.lg)
            .padding(.bottom, BTSpacing.xl)

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
                    .font(BTFont.bodyBold(size: 14))
                    .tracking(0.3)
                    .foregroundStyle(Color.btOnAccent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.btLime)
                    .cornerRadius(BTRadius.lg)
            }
            .buttonStyle(.plain)

            Button { dismiss() } label: {
                Text("Maybe later")
                    .font(BTFont.bodyMedium(size: 13))
                    .foregroundStyle(Color.btText2)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, BTSpacing.sm)
        }
        .padding(.horizontal, 22)
        .padding(.top, BTSpacing.xl)
        .padding(.bottom, BTSpacing.xxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.btOnAccent.ignoresSafeArea())
        .presentationDetents([.height(430)])
        .presentationDragIndicator(.visible)
    }

    private func bullet(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(Color.btLime)
                .frame(width: 5, height: 5)
                .padding(.top, 7)
            (Text(label).font(BTFont.bodySemibold(size: 12.5)).foregroundColor(.btText)
             + Text(" — \(value)").font(BTFont.body(size: 12.5)).foregroundColor(.btText2))
                .fixedSize(horizontal: false, vertical: true)
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
