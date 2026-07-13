import SwiftUI

/// Feuille de recherche et de sélection d'un port.
struct PortSearchView: View {
    @ObservedObject var viewModel: TideViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var results: [Port] = []
    @State private var isSearching = false
    @State private var error: String?
    @State private var task: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            List {
                if let error {
                    Text(error)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                }

                if isSearching {
                    HStack { ProgressView(); Text("Recherche…").foregroundStyle(.secondary) }
                }

                ForEach(results) { port in
                    Button {
                        viewModel.select(port)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "water.waves")
                                .foregroundStyle(Theme.ocean)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(port.nom).foregroundStyle(.primary)
                                Text("\(port.lat, specifier: "%.3f"), \(port.lon, specifier: "%.3f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if port.id == viewModel.port.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Theme.ocean)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choisir un port")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Saint-Malo, Brest, La Rochelle…")
            .onChange(of: query) { _, newValue in scheduleSearch(newValue) }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func scheduleSearch(_ text: String) {
        task?.cancel()
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 2 else {
            results = []
            return
        }
        task = Task {
            // Petit debounce pour éviter une requête par frappe.
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await performSearch(trimmed)
        }
    }

    private func performSearch(_ text: String) async {
        isSearching = true
        error = nil
        do {
            let found = try await MeteoConsultAPI.searchPorts(text)
            if !Task.isCancelled { results = found }
        } catch {
            if !Task.isCancelled {
                self.error = (error as? LocalizedError)?.errorDescription ?? "Recherche impossible."
            }
        }
        isSearching = false
    }
}
