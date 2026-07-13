import Foundation
import SwiftUI
import WidgetKit

/// Modèle observable qui charge les marées du port sélectionné.
@MainActor
final class TideViewModel: ObservableObject {
    @Published var port: Port = SharedStore.selectedPort
    @Published var extremes: [Tide] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Instant courant rafraîchi périodiquement pour animer l'état « maintenant ».
    @Published var now = Date()

    private var ticker: Timer?

    init() {
        startTicker()
    }

    func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.now = Date() }
        }
    }

    /// Sélectionne un port, le persiste (App Group) et recharge.
    func select(_ port: Port) {
        self.port = port
        SharedStore.selectedPort = port
        WidgetCenter.shared.reloadAllTimelines()
        Task { await load() }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            extremes = try await MeteoConsultAPI.fetchTideExtremes(lat: port.lat, lon: port.lon)
            now = Date()
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Chargement impossible."
        }
        isLoading = false
    }

    // MARK: Valeurs dérivées

    var nextTide: Tide? { TideMath.next(after: now, in: extremes) }

    var previousTide: Tide? { TideMath.surrounding(now, in: extremes).previous }

    var isRising: Bool? { TideMath.isRising(at: now, in: extremes) }

    var currentHeight: Double? { TideMath.height(at: now, in: extremes) }

    var progress: Double { TideMath.progress(at: now, in: extremes) ?? 0 }

    /// Coefficient courant : celui de la prochaine (ou dernière) pleine mer.
    var coefficient: Int? {
        if let n = nextTide, n.type == .high, let c = n.coef { return c }
        let highs = extremes.filter { $0.type == .high && $0.coef != nil }
        return highs.min(by: { abs($0.date.timeIntervalSince(now)) < abs($1.date.timeIntervalSince(now)) })?.coef
    }

    /// Marées du jour courant (dans le fuseau du port).
    var todayTides: [Tide] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = port.timeZoneValue
        return extremes.filter { cal.isDate($0.date, inSameDayAs: now) }
    }

    /// Marées regroupées par jour pour la liste défilante.
    var groupedByDay: [(day: Date, tides: [Tide])] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = port.timeZoneValue
        let groups = Dictionary(grouping: extremes) { cal.startOfDay(for: $0.date) }
        return groups.keys.sorted().map { (day: $0, tides: groups[$0]!.sorted { $0.date < $1.date }) }
    }
}
