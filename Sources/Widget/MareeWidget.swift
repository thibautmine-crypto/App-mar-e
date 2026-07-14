import WidgetKit
import SwiftUI

struct MareeWidget: Widget {
    let kind = "MareeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TideProvider()) { entry in
            MareeWidgetView(entry: entry)
        }
        .configurationDisplayName("Marées")
        .description("Prochaine marée, hauteur d'eau et coefficient pour votre port.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

@main
struct MareeWidgetBundle: WidgetBundle {
    var body: some Widget {
        MareeWidget()
    }
}
