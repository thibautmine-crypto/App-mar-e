import Foundation

/// Client de l'API publique Météo Consult Marine (données SHOM, sans clé).
///
/// Deux endpoints sont utilisés :
///  - Recherche de ports :   `.../recherche.php?rech=<texte>`
///  - Prévisions de marées : `.../previsionsSpot.php?lat=<lat>&lon=<lon>`
enum MeteoConsultAPI {

    enum APIError: LocalizedError {
        case badURL
        case http(Int)
        case decoding(Error)

        var errorDescription: String? {
            switch self {
            case .badURL: return "URL invalide."
            case .http(let code): return "Erreur réseau (code \(code))."
            case .decoding: return "Réponse illisible du serveur."
            }
        }
    }

    private static let searchBase =
        "https://ws.meteoconsult.fr/meteoconsultmarine/android/100/fr/v30/recherche.php"
    private static let spotBase =
        "https://ws.meteoconsult.fr/meteoconsultmarine/androidtab/115/fr/v30/previsionsSpot.php"

    /// En-tête utilisé par le client officiel ; certains WAF filtrent les requêtes sans User-Agent.
    private static let userAgent =
        "Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36 (KHTML, like Gecko) " +
        "Chrome/146.0.0.0 Mobile Safari/537.36"

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": userAgent]
        config.timeoutIntervalForRequest = 20
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }()

    // MARK: Recherche de ports

    static func searchPorts(_ query: String) async throws -> [Port] {
        var comps = URLComponents(string: searchBase)
        comps?.queryItems = [URLQueryItem(name: "rech", value: query)]
        guard let url = comps?.url else { throw APIError.badURL }

        let data = try await fetch(url)
        do {
            let response = try JSONDecoder().decode(SearchResponse.self, from: data)
            // On privilégie les sites disposant de données de marée.
            return response.contenu.filter { $0.presenceMaree ?? true }
        } catch {
            throw APIError.decoding(error)
        }
    }

    // MARK: Prévisions de marées (15 jours)

    static func fetchTides(lat: Double, lon: Double) async throws -> [TideDay] {
        var comps = URLComponents(string: spotBase)
        comps?.queryItems = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
        ]
        guard let url = comps?.url else { throw APIError.badURL }

        let data = try await fetch(url)
        do {
            let response = try JSONDecoder().decode(SpotResponse.self, from: data)
            return response.contenu.marees
        } catch {
            throw APIError.decoding(error)
        }
    }

    /// Renvoie la liste à plat de tous les extremums de marée, triés par date.
    static func fetchTideExtremes(lat: Double, lon: Double) async throws -> [Tide] {
        let days = try await fetchTides(lat: lat, lon: lon)
        return days
            .flatMap { $0.etales }
            .sorted { $0.date < $1.date }
    }

    // MARK: Réseau

    private static func fetch(_ url: URL) async throws -> Data {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.http(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.http(http.statusCode)
        }
        return data
    }
}
