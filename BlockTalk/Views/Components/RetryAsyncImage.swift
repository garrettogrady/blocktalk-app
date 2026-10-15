import SwiftUI

struct RetryAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let maxRetries: Int
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder

    @State private var attempt = 0
    @State private var failed = false

    init(
        url: URL?,
        maxRetries: Int = 3,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.maxRetries = maxRetries
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        AsyncImage(url: url, transaction: .init(animation: .easeIn(duration: 0.15))) { phase in
            switch phase {
            case .success(let image):
                content(image)
            case .failure:
                if attempt < maxRetries {
                    placeholder()
                        .onAppear { scheduleRetry() }
                } else {
                    placeholder()
                }
            default:
                placeholder()
            }
        }
        .id(attempt)
    }

    private func scheduleRetry() {
        let delay = Double(attempt + 1) * 1.5
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            attempt += 1
        }
    }
}
