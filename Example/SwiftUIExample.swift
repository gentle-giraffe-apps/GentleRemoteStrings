/// Example showing GentleRemoteStrings in a SwiftUI view.
/// This is illustrative — adapt to your app's architecture.

import SwiftUI
import Observation
import GentleRemoteStrings

// MARK: - View Model

@MainActor
@Observable
final class ContentViewModel {
    var continueText = ""
    var continueLabel = ""
    var logoutText = ""

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
    @State private var viewModel: ContentViewModel

    init(strings: RemoteStringsService) {
        _viewModel = State(wrappedValue: ContentViewModel(strings: strings))
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
