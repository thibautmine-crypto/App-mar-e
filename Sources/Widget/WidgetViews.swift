import WidgetKit
import SwiftUI

/// Dégradé océan partagé par les vues du widget.
private let oceanGradient = LinearGradient(
    colors: [Color(red: 0.06, green: 0.40, blue: 0.66),
             Color(red: 0.02, green: 0.20, blue: 0.38)],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

// MARK: - Vue principale (route selon la famille)

struct MareeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: TideEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall: SmallTideView(entry: entry)
            case .systemMedium: MediumTideView(entry: entry)
            default: LargeTideView(entry: entry)
            }
        }
        .containerBackground(for: .widget) { oceanGradient }
    }
}

// MARK: - Small

struct SmallTideView: View {
    let entry: TideEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "water.waves").font(.caption2)
                Text(entry.port.nom)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer()

            if let next = entry.nextTide {
                Image(systemName: next.type.symbolName)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(next.type == .high ? Color(red: 0.4, green: 0.85, blue: 1) : Color(red: 0.98, green: 0.9, blue: 0.7))
                Text(next.type.label)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.85))
                Text(next.date.heure(entry.port.timeZoneValue))
                    .font(.title.weight(.bold).monospacedDigit())
                    .foregroundStyle(.white)
                Text(next.hauteur.metresString)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.75))
            } else {
                Text(entry.error ? "Hors ligne" : "—")
                    .foregroundStyle(.white.opacity(0.8))
            }

            Spacer()

            if let coef = entry.coefficient {
                Text("Coef. \(coef)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Medium

struct MediumTideView: View {
    let entry: TideEntry

    private var todayExtremes: [Tide] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = entry.port.timeZoneValue
        return entry.extremes.filter { cal.isDate($0.date, inSameDayAs: entry.date) }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "water.waves").font(.caption2)
                    Text(entry.port.nom).font(.caption.weight(.semibold)).lineLimit(1)
                }
                .foregroundStyle(.white.opacity(0.85))

                Spacer()

                if let rising = entry.isRising {
                    Label(rising ? "Montante" : "Descendante",
                          systemImage: rising ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
                if let h = entry.currentHeight {
                    Text(h.metresString)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                if let next = entry.nextTide {
                    Text("\(next.type.shortLabel) à \(next.date.heure(entry.port.timeZoneValue))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                if let coef = entry.coefficient {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.stars.fill").font(.caption2)
                        Text("Coef. \(coef)").font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.white)
                }
                ForEach(todayExtremes.prefix(4)) { tide in
                    HStack(spacing: 6) {
                        Image(systemName: tide.type.symbolName)
                            .font(.caption2)
                            .foregroundStyle(tide.type == .high ? Color(red: 0.4, green: 0.85, blue: 1) : Color(red: 0.98, green: 0.9, blue: 0.7))
                            .frame(width: 14)
                        Text(tide.date.heure(entry.port.timeZoneValue))
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(.white)
                        Spacer()
                        Text(tide.hauteur.metresString)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.white.opacity(0.75))
                    }
                    .opacity(tide.date < entry.date ? 0.45 : 1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Large

struct LargeTideView: View {
    let entry: TideEntry

    private var todayExtremes: [Tide] {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = entry.port.timeZoneValue
        return entry.extremes.filter { cal.isDate($0.date, inSameDayAs: entry.date) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(entry.port.nom, systemImage: "water.waves")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                if let coef = entry.coefficient {
                    Text("Coef. \(coef)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(.white.opacity(0.18), in: Capsule())
                }
            }

            if let h = entry.currentHeight, let rising = entry.isRising {
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text(h.metresString)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Label(rising ? "Montante" : "Descendante",
                          systemImage: rising ? "arrow.up.right" : "arrow.down.right")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Divider().overlay(.white.opacity(0.2))

            ForEach(todayExtremes) { tide in
                HStack(spacing: 10) {
                    Image(systemName: tide.type.symbolName)
                        .foregroundStyle(tide.type == .high ? Color(red: 0.4, green: 0.85, blue: 1) : Color(red: 0.98, green: 0.9, blue: 0.7))
                        .frame(width: 20)
                    Text(tide.type.label)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    if let coef = tide.coef {
                        Text("\(coef)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.65))
                    }
                    Text(tide.hauteur.metresString)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 64, alignment: .trailing)
                    Text(tide.date.heure(entry.port.timeZoneValue))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 52, alignment: .trailing)
                }
                .opacity(tide.date < entry.date ? 0.45 : 1)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
