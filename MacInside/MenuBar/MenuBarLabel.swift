import SwiftUI

/// Contenu compact affiché dans la barre de menu (icône + %CPU).
struct MenuBarLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "cpu")
            Text(Formatters.percent(model.cpu.totalPercent))
                .monospacedDigit()
        }
    }
}
