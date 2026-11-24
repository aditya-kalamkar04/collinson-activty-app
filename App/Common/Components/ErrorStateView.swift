import SwiftUI

struct ErrorStateView: View {
    let message: String
    let retry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            if let retry {
                Button("Try again", action: retry)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

#Preview {
    ErrorStateView(message: "You seem to be offline. Check your connection and try again.", retry: {})
}
