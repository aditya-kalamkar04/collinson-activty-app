import SwiftUI
import LocationActivitiesKit

/// Renders any `ViewState` the same way across the app. Screens only describe the
/// idle and loaded content; loading, empty, and error look identical everywhere.
struct LoadableView<Value: Sendable, Idle: View, Content: View>: View {
    private let state: ViewState<Value>
    private let loadingMessage: String
    private let emptyTitle: String
    private let retry: (() -> Void)?
    private let idle: () -> Idle
    private let content: (Value) -> Content

    init(
        state: ViewState<Value>,
        loadingMessage: String,
        emptyTitle: String = "Nothing found",
        retry: (() -> Void)? = nil,
        @ViewBuilder idle: @escaping () -> Idle,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.state = state
        self.loadingMessage = loadingMessage
        self.emptyTitle = emptyTitle
        self.retry = retry
        self.idle = idle
        self.content = content
    }

    var body: some View {
        switch state {
        case .idle:
            idle()
        case .loading:
            ProgressView(loadingMessage)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .empty(let message):
            ContentUnavailableView(emptyTitle, systemImage: "magnifyingglass", description: Text(message))
        case .failed(let message):
            ErrorStateView(message: message, retry: retry)
        case .loaded(let value):
            content(value)
        }
    }
}

extension LoadableView where Idle == EmptyView {
    init(
        state: ViewState<Value>,
        loadingMessage: String,
        emptyTitle: String = "Nothing found",
        retry: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Value) -> Content
    ) {
        self.init(
            state: state,
            loadingMessage: loadingMessage,
            emptyTitle: emptyTitle,
            retry: retry,
            idle: { EmptyView() },
            content: content
        )
    }
}
