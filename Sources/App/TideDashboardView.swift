import SwiftUI

/// Écran principal : état courant, prochaine marée, courbe et marées du jour.
struct TideDashboardView: View {
    @ObservedObject var viewModel: TideViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                if !viewModel.extremes.isEmpty {
                    chartCard
                    todayCard
                    upcomingCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
        }
    }

    // MARK: Carte héro (état courant)

    private var heroCard: some View {
        GlassCard {
            VStack(spacing: 16) {
                if let rising = viewModel.isRising {
                    Label(rising ? "Marée montante" : "Marée descendante",
                          systemImage: rising ? "arrow.up.right" : "arrow.down.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text(viewModel.currentHeight.map { String(format: "%.2f", $0).replacingOccurrences(of: ".", with: ",") } ?? "—")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("m")
                        .font(.title2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                    if let coef = viewModel.coefficient {
                        VStack(spacing: 2) {
                            Text("\(coef)")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            Text("coef.")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                }

                if let next = viewModel.nextTide {
                    Divider().overlay(.white.opacity(0.2))
                    HStack {
                        Image(systemName: next.type.symbolName)
                            .font(.title3)
                            .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Prochaine \(next.type.label.lowercased())")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.75))
                            Text("\(next.date.heure(viewModel.port.timeZoneValue)) · \(next.hauteur.metresString)")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        Spacer()
                        Text("dans \(next.date.timeIntervalSince(viewModel.now).compactDuration)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(.white.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.tideGradient.opacity(0.9))
                .shadow(color: Theme.ocean.opacity(0.4), radius: 20, y: 12)
        )
    }

    // MARK: Courbe

    private var chartCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Hauteur d'eau")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                TideChartView(extremes: viewModel.extremes,
                              now: viewModel.now,
                              timeZone: viewModel.port.timeZoneValue)
            }
        }
    }

    // MARK: Marées du jour

    private var todayCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Aujourd'hui")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                ForEach(viewModel.todayTides) { tide in
                    TideRow(tide: tide, tz: viewModel.port.timeZoneValue, now: viewModel.now)
                }
            }
        }
    }

    // MARK: Prochains jours

    private var upcomingCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Jours suivants")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.9))
                ForEach(viewModel.groupedByDay.dropFirst().prefix(5), id: \.day) { group in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(group.day.jourCourt(viewModel.port.timeZoneValue))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.8))
                        ForEach(group.tides) { tide in
                            TideRow(tide: tide, tz: viewModel.port.timeZoneValue, now: viewModel.now)
                        }
                    }
                    if group.day != viewModel.groupedByDay.dropFirst().prefix(5).last?.day {
                        Divider().overlay(.white.opacity(0.12))
                    }
                }
            }
        }
    }
}

/// Ligne d'une marée (type, heure, hauteur, coefficient).
struct TideRow: View {
    let tide: Tide
    let tz: TimeZone
    let now: Date

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tide.type.symbolName)
                .font(.body.weight(.semibold))
                .foregroundStyle(tide.type == .high ? Theme.surf : Theme.sand)
                .frame(width: 26)
            Text(tide.type.label)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            if let coef = tide.coef {
                Text("\(coef)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            Text(tide.hauteur.metresString)
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 64, alignment: .trailing)
            Text(tide.date.heure(tz))
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
                .frame(width: 52, alignment: .trailing)
        }
        .opacity(tide.date < now ? 0.45 : 1)
    }
}
