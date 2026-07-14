import WidgetKit
import SwiftUI

/// Entrée de timeline : marées du port + instant de rendu.
struct TideEntry: TimelineEntry {
    let date: Date
    let port: Port
    let extremes: [Tide]
    let error: Bool

    var nextTide: Tide? { TideMath.next(after: date, in: extremes) }
    var isRising: Bool? { TideMath.isRising(at: date, in: extremes) }
    var currentHeight: Double? { TideMath.height(at: date, in: extremes) }
    var coefficient: Int? {
        if let n = nextTide, n.type == .high, let c = n.coef { return c }
        return extremes.filter { $0.type == .high }.compactMap { $0.coef }.first
    }
}

struct TideProvider: TimelineProvider {

    func placeholder(in context: Context) -> TideEntry {
        TideEntry(date: Date(), port: SharedStore.defaultPort, extremes: Self.sample, error: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (TideEntry) -> Void) {
        let port = SharedStore.selectedPort
        if context.isPreview {
            completion(TideEntry(date: Date(), port: port, extremes: Self.sample, error: false))
            return
        }
        Task {
            let entry = await Self.loadEntry(port: port, date: Date())
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TideEntry>) -> Void) {
        let port = SharedStore.selectedPort
        Task {
            let base = await Self.loadEntry(port: port, date: Date())

            // Une entrée par heure sur les 6 prochaines heures pour animer la progression,
            // puis rafraîchissement réseau.
            var entries: [TideEntry] = []
            for hour in 0..<6 {
                let date = Calendar.current.date(byAdding: .hour, value: hour, to: Date()) ?? Date()
                entries.append(TideEntry(date: date, port: port,
                                         extremes: base.extremes, error: base.error))
            }
            let refresh = Calendar.current.date(byAdding: .hour, value: 3, to: Date()) ?? Date()
            completion(Timeline(entries: entries, policy: .after(refresh)))
        }
    }

    // MARK: Chargement

    private static func loadEntry(port: Port, date: Date) async -> TideEntry {
        do {
            let extremes = try await MeteoConsultAPI.fetchTideExtremes(lat: port.lat, lon: port.lon)
            return TideEntry(date: date, port: port, extremes: extremes, error: false)
        } catch {
            return TideEntry(date: date, port: port, extremes: [], error: true)
        }
    }

    // MARK: Données de prévisualisation

    static let sample: [Tide] = {
        let now = Date()
        func iso(_ offset: TimeInterval) -> String {
            DateParsing.iso.string(from: now.addingTimeInterval(offset))
        }
        return [
            Tide(datetime: iso(-3600), type: .low, hauteur: 2.7, coef: nil),
            Tide(datetime: iso(2 * 3600), type: .high, hauteur: 10.8, coef: 76),
            Tide(datetime: iso(8 * 3600), type: .low, hauteur: 2.6, coef: nil),
            Tide(datetime: iso(14 * 3600), type: .high, hauteur: 11.3, coef: 81),
        ]
    }()
}
