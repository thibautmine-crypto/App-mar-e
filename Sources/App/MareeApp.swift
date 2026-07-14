import SwiftUI

@main
struct MareeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// Racine : fond océan, en-tête, dashboard, recherche de port.
struct RootView: View {
    @StateObject private var viewModel = TideViewModel()
    @Environment(\.colorScheme) private var scheme
    @State private var showingSearch = false

    var body: some View {
        ZStack {
            Theme.background(scheme).ignoresSafeArea()

            VStack(spacing: 0) {
                header
                if let error = viewModel.errorMessage, viewModel.extremes.isEmpty {
                    errorState(error)
                } else if viewModel.extremes.isEmpty && viewModel.isLoading {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else {
                    TideDashboardView(viewModel: viewModel)
                }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .sheet(isPresented: $showingSearch) {
            PortSearchView(viewModel: viewModel)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Marées")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.white)
                Button {
                    showingSearch = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                        Text(viewModel.port.nom)
                        Image(systemName: "chevron.down").font(.caption2)
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                }
            }
            Spacer()
            if viewModel.isLoading && !viewModel.extremes.isEmpty {
                ProgressView().tint(.white)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 44))
                .foregroundStyle(.white.opacity(0.8))
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal, 40)
            Button("Réessayer") { Task { await viewModel.load() } }
                .buttonStyle(.borderedProminent)
                .tint(.white.opacity(0.2))
            Spacer()
        }
    }
}
