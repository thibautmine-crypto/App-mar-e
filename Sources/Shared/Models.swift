import Foundation

// MARK: - Type de marée

/// Type d'étale : Basse Mer (BM) ou Pleine Mer (PM).
enum TideType: String, Codable, Hashable {
    case low = "BM"   // Basse mer
    case high = "PM"  // Pleine mer

    var label: String {
        switch self {
        case .low: return "Basse mer"
        case .high: return "Pleine mer"
        }
    }

    var shortLabel: String {
        switch self {
        case .low: return "BM"
        case .high: return "PM"
        }
    }

    var symbolName: String {
        switch self {
        case .low: return "arrow.down.to.line"
        case .high: return "arrow.up.to.line"
        }
    }
}

// MARK: - Port

/// Un site/port renvoyé par la recherche Météo Consult Marine.
struct Port: Codable, Identifiable, Hashable {
    let id: Int
    let nom: String
    let lat: Double
    let lon: Double
    let timeZone: String?
    let presenceMaree: Bool?

    enum CodingKeys: String, CodingKey {
        case id, nom, lat, lon
        case timeZone = "time_zone"
        case presenceMaree = "presence_maree"
    }

    /// Fuseau horaire du port, avec repli sur Europe/Paris.
    var timeZoneValue: TimeZone {
        if let tz = timeZone, let value = TimeZone(identifier: tz) {
            return value
        }
        return TimeZone(identifier: "Europe/Paris") ?? .current
    }
}

/// Réponse brute de l'endpoint de recherche.
struct SearchResponse: Codable {
    let contenu: [Port]
}

// MARK: - Étale (extremum de marée)

/// Un extremum de marée (pleine ou basse mer) à un instant donné.
struct Tide: Codable, Identifiable, Hashable {
    let datetime: String
    let type: TideType
    let hauteur: Double
    let coef: Int?

    enum CodingKeys: String, CodingKey {
        case datetime
        case type = "type_etale"
        case hauteur
        case coef
    }

    var id: String { datetime + type.rawValue }

    /// Date parsée depuis la chaîne ISO 8601 fournie par l'API (avec décalage).
    var date: Date {
        DateParsing.iso.date(from: datetime) ?? Date.distantPast
    }
}

/// Marées d'une journée pour un lieu.
struct TideDay: Codable, Hashable {
    let datetime: String
    let lieu: String
    let etales: [Tide]
}

/// Bloc `contenu` de l'endpoint des prévisions.
struct SpotContent: Codable {
    let marees: [TideDay]
}

/// Réponse brute de l'endpoint des prévisions.
struct SpotResponse: Codable {
    let contenu: SpotContent
}

// MARK: - Parsing des dates

enum DateParsing {
    /// Formatteur ISO 8601 gérant les décalages type `2026-07-13T01:05:00+02:00`.
    static let iso: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}
