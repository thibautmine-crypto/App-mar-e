import Foundation

/// Stockage partagé entre l'app et le widget via un App Group.
///
/// Le port sélectionné dans l'app est écrit ici pour que l'extension widget
/// (processus séparé) puisse le lire. En l'absence de sélection, un port par
/// défaut est proposé afin que le widget affiche des données dès l'installation.
enum SharedStore {

    /// ⚠️ À faire correspondre à l'App Group configuré dans les entitlements
    /// (Signing & Capabilities) des deux cibles.
    static let appGroupID = "group.com.thibautmine.appmaree"

    private static let selectedPortKey = "selectedPort"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// Port par défaut (Saint-Malo) tant qu'aucun n'a été choisi.
    static let defaultPort = Port(
        id: 17,
        nom: "Saint-Malo",
        lat: 48.6539,
        lon: -2.01563,
        timeZone: "Europe/Paris",
        presenceMaree: true
    )

    static var selectedPort: Port {
        get {
            guard let data = defaults.data(forKey: selectedPortKey),
                  let port = try? JSONDecoder().decode(Port.self, from: data)
            else { return defaultPort }
            return port
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: selectedPortKey)
            }
        }
    }
}
