import SwiftUI

struct LinkPreviewCard: View {
    let url: URL
    var source: String = ""
    var title: String = ""
    var snippet: String = ""
    var thumbnailUrl: String?

    var body: some View {
        Button {
            UIApplication.shared.open(url)
        } label: {
            HStack(spacing: BTSpacing.md) {
                // Thumbnail area
                if let thumbnailUrl, let imageUrl = URL(string: thumbnailUrl) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 72, height: 72)
                                .clipped()
                        default:
                            thumbnailPlaceholder
                        }
                    }
                    .cornerRadius(BTRadius.sm)
                } else {
                    thumbnailPlaceholder
                }

                // Text content
                VStack(alignment: .leading, spacing: BTSpacing.xs) {
                    if !source.isEmpty {
                        Text(source.uppercased())
                            .font(BTFont.mono(size: 9))
                            .foregroundStyle(Color.btText3)
                    }

                    if !title.isEmpty {
                        Text(title)
                            .font(BTFont.bodySemibold(size: 14))
                            .foregroundStyle(Color.btText)
                            .lineLimit(2)
                    }

                    if !snippet.isEmpty {
                        Text(snippet)
                            .font(BTFont.body(size: 12))
                            .foregroundStyle(Color.btText2)
                            .lineLimit(2)
                    }
                }

                Spacer()
            }
            .padding(BTSpacing.md)
            .background(Color.btSurface)
            .cornerRadius(BTRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: BTRadius.md)
                    .stroke(Color.btLine, lineWidth: 1)
            )
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: BTRadius.sm)
            .fill(Color.btSurface2)
            .frame(width: 72, height: 72)
            .overlay(
                Image(systemName: "link")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.btText3)
            )
    }
}

#Preview {
    ZStack {
        Color.btBg.ignoresSafeArea()
        LinkPreviewCard(
            url: URL(string: "https://example.com")!,
            source: "ny times",
            title: "New Subway Extension Opens in Lower Manhattan",
            snippet: "The long-awaited extension brings service to underserved neighborhoods..."
        )
        .padding()
    }
}
