import Foundation

/// Calculs dérivés à partir des extremums de marée (pleines / basses mers).
///
/// L'API ne fournit que les extremums. Entre deux extremums consécutifs, on
/// approxime la hauteur d'eau par une demi-sinusoïde (modèle de marée usuel),
/// ce qui donne une courbe lisse et une position « maintenant » réaliste.
enum TideMath {

    /// Étale précédent et suivant encadrant l'instant `date`.
    static func surrounding(_ date: Date, in tides: [Tide]) -> (previous: Tide?, next: Tide?) {
        let sorted = tides.sorted { $0.date < $1.date }
        let next = sorted.first { $0.date > date }
        let previous = sorted.last { $0.date <= date }
        return (previous, next)
    }

    /// Prochain extremum après `date`.
    static func next(after date: Date, in tides: [Tide]) -> Tide? {
        tides.sorted { $0.date < $1.date }.first { $0.date > date }
    }

    /// Hauteur d'eau interpolée à l'instant `date` (mètres), si encadrée.
    static func height(at date: Date, in tides: [Tide]) -> Double? {
        let (prev, next) = surrounding(date, in: tides)
        guard let a = prev, let b = next else { return nil }
        let span = b.date.timeIntervalSince(a.date)
        guard span > 0 else { return a.hauteur }
        let t = date.timeIntervalSince(a.date) / span            // 0 → 1
        // Interpolation cosinus : lisse aux extremums (dérivée nulle).
        let phase = (1 - cos(.pi * t)) / 2                        // 0 → 1
        return a.hauteur + (b.hauteur - a.hauteur) * phase
    }

    /// La marée est-elle montante à cet instant ?
    static func isRising(at date: Date, in tides: [Tide]) -> Bool? {
        guard let next = next(after: date, in: tides) else { return nil }
        return next.type == .high
    }

    /// Fraction écoulée [0,1] entre l'étale précédent et le suivant.
    static func progress(at date: Date, in tides: [Tide]) -> Double? {
        let (prev, next) = surrounding(date, in: tides)
        guard let a = prev, let b = next else { return nil }
        let span = b.date.timeIntervalSince(a.date)
        guard span > 0 else { return 0 }
        return min(1, max(0, date.timeIntervalSince(a.date) / span))
    }

    /// Points échantillonnés (date, hauteur) pour tracer la courbe sur une fenêtre.
    static func curve(from start: Date, to end: Date, step: TimeInterval = 600,
                      in tides: [Tide]) -> [(date: Date, height: Double)] {
        guard end > start else { return [] }
        var points: [(Date, Double)] = []
        var t = start
        while t <= end {
            if let h = height(at: t, in: tides) {
                points.append((t, h))
            }
            t = t.addingTimeInterval(step)
        }
        return points.map { (date: $0.0, height: $0.1) }
    }
}

// MARK: - Formatage

extension Date {
    func heure(_ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.timeZone = tz
        f.dateFormat = "HH:mm"
        return f.string(from: self)
    }

    func jourCourt(_ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "fr_FR")
        f.timeZone = tz
        f.dateFormat = "EEEE d MMM"
        return f.string(from: self).capitalizedFirst
    }
}

extension TimeInterval {
    /// Durée compacte type « 2 h 14 » ou « 43 min ».
    var compactDuration: String {
        let total = Int(max(0, self))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h) h \(String(format: "%02d", m))" }
        return "\(m) min"
    }
}

extension Double {
    /// Hauteur formatée « 10,76 m ».
    var metresString: String {
        String(format: "%.2f m", self).replacingOccurrences(of: ".", with: ",")
    }
}

extension String {
    var capitalizedFirst: String {
        guard let first else { return self }
        return first.uppercased() + dropFirst()
    }
}
