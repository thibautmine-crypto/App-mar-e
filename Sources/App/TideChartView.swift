import SwiftUI
import Charts

/// Courbe de marée (hauteur d'eau) sur une fenêtre glissante, avec repère « maintenant ».
struct TideChartView: View {
    let extremes: [Tide]
    let now: Date
    let timeZone: TimeZone

    private var window: (start: Date, end: Date) {
        (now.addingTimeInterval(-3 * 3600), now.addingTimeInterval(9 * 3600))
    }

    private var points: [CurvePoint] {
        TideMath.curve(from: window.start, to: window.end, step: 600, in: extremes)
            .map { CurvePoint(date: $0.date, height: $0.height) }
    }

    private var extremesInWindow: [Tide] {
        extremes.filter { $0.date >= window.start && $0.date <= window.end }
    }

    private var currentHeight: Double? {
        TideMath.height(at: now, in: extremes)
    }

    var body: some View {
        Chart {
            ForEach(points) { p in
                AreaMark(x: .value("Heure", p.date), y: .value("Hauteur", p.height))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Theme.surf.opacity(0.55), Theme.ocean.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                LineMark(x: .value("Heure", p.date), y: .value("Hauteur", p.height))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Theme.surf)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
            }

            ForEach(extremesInWindow) { tide in
                PointMark(x: .value("Heure", tide.date), y: .value("Hauteur", tide.hauteur))
                    .foregroundStyle(.white)
                    .symbolSize(60)
                    .annotation(position: tide.type == .high ? .top : .bottom) {
                        Text(tide.hauteur.metresString)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
            }

            RuleMark(x: .value("Maintenant", now))
                .foregroundStyle(.white.opacity(0.55))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 4]))

            if let h = currentHeight {
                PointMark(x: .value("Maintenant", now), y: .value("Hauteur", h))
                    .foregroundStyle(.white)
                    .symbolSize(120)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(date.heure(timeZone))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(.white.opacity(0.08))
                AxisValueLabel().foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(height: 200)
    }
}

private struct CurvePoint: Identifiable {
    let id = UUID()
    let date: Date
    let height: Double
}
