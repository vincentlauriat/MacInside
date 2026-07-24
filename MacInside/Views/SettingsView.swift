import SwiftUI

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppModel.self) private var model

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

            Section("Démarrage") {
                Toggle("Démarrer à l'ouverture de session", isOn: $settings.launchAtLogin)
            }

            Section("Cartes du dashboard") {
                ForEach(visibleCardKinds) { kind in
                    Toggle(kind.label, isOn: cardVisibilityBinding(for: kind))
                }
            }

            Section("Barre de menu") {
                Picker("Style", selection: $settings.menuBarModeRaw) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if settings.menuBarMode == .separate {
                    Toggle("CPU", isOn: $settings.showCPUMenuExtra)
                    Toggle("Mémoire", isOn: $settings.showMemoryMenuExtra)
                    Toggle("Réseau", isOn: $settings.showNetworkMenuExtra)
                    Toggle("Disque", isOn: $settings.showDiskMenuExtra)
                    Toggle("Batterie", isOn: $settings.showBatteryMenuExtra)
                    Toggle("GPU", isOn: $settings.showGPUMenuExtra)
                }
            }

            if model.battery.isPresent {
                Section("Alertes batterie") {
                    Toggle("Alerte batterie faible", isOn: $settings.lowBatteryAlertEnabled)
                        .onChange(of: settings.lowBatteryAlertEnabled) { _, enabled in
                            if enabled { model.requestBatteryAlertAuthorization() }
                        }
                    if settings.lowBatteryAlertEnabled {
                        Stepper(value: $settings.lowBatteryAlertThreshold, in: 5...50, step: 5) {
                            Text("Seuil bas")
                        }
                        Text(Formatters.percent(Double(settings.lowBatteryAlertThreshold)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Alerte batterie chargée", isOn: $settings.highBatteryAlertEnabled)
                        .onChange(of: settings.highBatteryAlertEnabled) { _, enabled in
                            if enabled { model.requestBatteryAlertAuthorization() }
                        }
                    if settings.highBatteryAlertEnabled {
                        Stepper(value: $settings.highBatteryAlertThreshold, in: 50...100, step: 5) {
                            Text("Seuil haut")
                        }
                        Text(Formatters.percent(Double(settings.highBatteryAlertThreshold)))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("À propos") {
                Text("MacInside — tableau de bord système macOS.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420, height: windowHeight)
    }

    /// Cartes proposées dans « Cartes du dashboard » : mêmes règles de
    /// visibilité conditionnelle que le dashboard lui-même (ex. Batterie
    /// absente sur un Mac de bureau) — pas de toggle pour une carte qui ne
    /// s'affichera de toute façon jamais.
    private var visibleCardKinds: [DashboardCardKind] {
        settings.dashboardCardOrder.filter { $0 != .battery || model.battery.isPresent }
    }

    private func cardVisibilityBinding(for kind: DashboardCardKind) -> Binding<Bool> {
        Binding(
            get: { !settings.hiddenDashboardCards.contains(kind) },
            set: { isVisible in
                var hidden = settings.hiddenDashboardCards
                if isVisible { hidden.remove(kind) } else { hidden.insert(kind) }
                settings.hiddenDashboardCards = hidden
            }
        )
    }

    private var windowHeight: CGFloat {
        var height: CGFloat = 340
        if settings.menuBarMode == .separate { height += 220 }
        if model.battery.isPresent {
            height += 150
            if settings.lowBatteryAlertEnabled { height += 70 }
            if settings.highBatteryAlertEnabled { height += 70 }
        }
        height += 90 // Section « Démarrage »
        height += 60 + CGFloat(visibleCardKinds.count) * 34 // Section « Cartes du dashboard »
        return height
    }
}
