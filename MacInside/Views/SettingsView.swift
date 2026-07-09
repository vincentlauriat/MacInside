import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings

        Form {
            Section("Apparence") {
                Picker("Apparence", selection: $settings.appearanceRaw) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Rafraîchissement") {
                Slider(value: $settings.refreshInterval, in: 0.5...5, step: 0.5) {
                    Text("Intervalle")
                } minimumValueLabel: {
                    Text("0.5s")
                } maximumValueLabel: {
                    Text("5s")
                }
                Text("Toutes les \(settings.refreshInterval, specifier: "%.1f") s")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("À propos") {
                Text("MacInside — tableau de bord système macOS.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 320)
    }
}
