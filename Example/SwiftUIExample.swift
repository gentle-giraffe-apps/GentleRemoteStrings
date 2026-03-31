/// Example showing GentleRemoteStrings in a SwiftUI view.
/// This is illustrative — adapt to your app's architecture.

import SwiftUI
import GentleRemoteStrings

// MARK: - View Model

@MainActor
final class ContentViewModel: ObservableObject {
    @Published var continueText = ""
    @Published var continueLabel = ""
    @Published var logoutText = ""

    private let strings: RemoteStringsService

    init(strings: RemoteStringsService) {
        self.strings = strings
    }

    func load() async {
        // Return cached/bundled values immediately
        await updateStrings()

        // Then refresh in background — next load will pick up changes
        await strings.refresh()
        await updateStrings()
    }

    private func updateStrings() async {
        let continueValue = await strings.string(for: "checkout.continue")
        continueText = continueValue.text
        continueLabel = continueValue.labelOrDefault

        let logoutValue = await strings.string(for: "profile.logout")
        logoutText = logoutValue.text
    }
}

// MARK: - View

struct ContentView: View {
    @StateObject private var viewModel: ContentViewModel

    init(strings: RemoteStringsService) {
        _viewModel = StateObject(wrappedValue: ContentViewModel(strings: strings))
    }

    var body: some View {
        VStack(spacing: 24) {
            Button(viewModel.continueText) {
                // action
            }
            .accessibilityLabel(viewModel.continueLabel)

            Button(viewModel.logoutText) {
                // action
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
