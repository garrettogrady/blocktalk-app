import SwiftUI

struct LocationGate: View {
    @Environment(LocationService.self) private var locationService

    var label: String = "Enable location to join the conversation"

    var body: some View {
        if locationService.permissionState == .granted {
            EmptyView()
        } else {
            HStack(spacing: BTSpacing.md) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.btWarn)

                Text(label)
                    .font(BTFont.bodyMedium(size: 13))
                    .foregroundStyle(Color.btText)

                Spacer()

                Button {
                    handleLocationAction()
                } label: {
                    Text(locationService.permissionState == .denied ? "Settings" : "Enable")
                        .font(BTFont.bodySemibold(size: 13))
                        .foregroundStyle(Color.btBg)
                        .padding(.horizontal, BTSpacing.md)
                        .padding(.vertical, BTSpacing.sm)
                        .background(Color.btWarn)
                        .cornerRadius(BTRadius.full)
                }
            }
            .padding(.horizontal, BTSpacing.lg)
            .padding(.vertical, BTSpacing.md)
            .background(Color.btWarn.opacity(0.12))
        }
    }

    private func handleLocationAction() {
        if locationService.permissionState == .denied {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        } else {
            locationService.requestPermission()
        }
    }
}

/// Banner variant for the top of the feed
struct LocationGateBanner: View {
    @Environment(LocationService.self) private var locationService

    var body: some View {
        if locationService.permissionState != .granted {
            Button {
                if locationService.permissionState == .denied {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } else {
                    locationService.requestPermission()
                }
            } label: {
                HStack(spacing: BTSpacing.sm) {
                    Image(systemName: "location.slash")
                        .font(.system(size: 11))
                    Text("location is off · viewing only · tap to enable")
                        .font(BTFont.body(size: 12))
                    Spacer()
                }
                .foregroundStyle(Color.btWarn)
                .padding(.horizontal, BTSpacing.lg)
                .padding(.vertical, BTSpacing.sm)
                .background(Color.btWarn.opacity(0.08))
            }
        }
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        VStack {
            LocationGate()
            LocationGateBanner()
        }
    }
    .environment(LocationService())
}
