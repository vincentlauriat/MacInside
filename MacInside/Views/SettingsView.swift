import SwiftUI

/// Fenêtre de Réglages en onglets plutôt qu'un unique `Form` qui empile toutes
/// les sections : avec 7 sections (Apparence, Rafraîchissement, Démarrage,
/// Cartes du dashboard, Barre de menu, Alertes batterie, À propos), la version
/// précédente calculait une hauteur de fenêtre qui dépassait 1200pt — chaque
/// nouvelle sous-phase de la Phase 3 l'a fait grandir un peu plus. Ici, une
/// seule taille de fenêtre fixe suffit puisqu'un seul onglet est visible à la
/// fois (même principe que les Préférences Xcode ou Réglages Système).
struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            GeneralSettingsPane()
                .tabItem { Label("Général", systemImage: "gearshape") }

            DashboardSettingsPane()
                .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }

            MenuBarSettingsPane()
                .tabItem { Label("Barre de menu", systemImage: "menubar.rectangle") }

            if model.battery.isPresent {
                BatterySettingsPane()
                    .tabItem { Label("Batterie", systemImage: "battery.100") }
            }

            AboutSettingsPane()
                .tabItem { Label("À propos", systemImage: "info.circle") }
        }
        .frame(width: 480, height: 460)
    }
}

private struct GeneralSettingsPane: View {
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

            Section("Démarrage") {
                Toggle("Démarrer à l'ouverture de session", isOn: $settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
    }
}

private struct DashboardSettingsPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Cartes du dashboard") {
                ForEach(visibleCardKinds) { kind in
                    Toggle(kind.label, isOn: cardVisibilityBinding(for: kind))
                }
            }
        }
        .formStyle(.grouped)
    }

    /// Mêmes règles de visibilité conditionnelle que le dashboard lui-même
    /// (ex. Batterie absente sur un Mac de bureau) — pas de toggle pour une
    /// carte qui ne s'affichera de toute façon jamais.
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
}

private struct MenuBarSettingsPane: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Style") {
                Picker("Style", selection: $settings.menuBarModeRaw) {
                    ForEach(MenuBarMode.allCases) { mode in
                        Text(mode.label).tag(mode.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            if settings.menuBarMode == .separate {
                Section("Icônes affichées") {
                    Toggle("CPU", isOn: $settings.showCPUMenuExtra)
                    Toggle("Mémoire", isOn: $settings.showMemoryMenuExtra)
                    Toggle("Réseau", isOn: $settings.showNetworkMenuExtra)
                    Toggle("Disque", isOn: $settings.showDiskMenuExtra)
                    Toggle("Batterie", isOn: $settings.showBatteryMenuExtra)
                    Toggle("GPU", isOn: $settings.showGPUMenuExtra)
                }
            }
        }
        .formStyle(.grouped)
    }
}

private struct BatterySettingsPane: View {
    @Environment(AppSettings.self) private var settings
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section("Alertes batterie") {
                Toggle("Alerte batterie faible", isOn: $settings.lowBatteryAlertEnabled)
                    .onChange(of: settings.lowBatteryAlertEnabled) { _, enabled in
                        if enabled { model.requestBatteryAlertAuthorization() }
                    }
                if settings.lowBatteryAlertEnabled {
                    thresholdRow("Seuil bas", value: $settings.lowBatteryAlertThreshold, in: 5...50)
                }

                Toggle("Alerte batterie chargée", isOn: $settings.highBatteryAlertEnabled)
                    .onChange(of: settings.highBatteryAlertEnabled) { _, enabled in
                        if enabled { model.requestBatteryAlertAuthorization() }
                    }
                if settings.highBatteryAlertEnabled {
                    thresholdRow("Seuil haut", value: $settings.highBatteryAlertThreshold, in: 50...100)
                }
            }
        }
        .formStyle(.grouped)
    }

    /// Curseur avec la valeur affichée en ligne (label + pourcentage), plutôt
    /// que le `Stepper` + légende séparée précédents : un seul geste direct
    /// pour ajuster, sans flèches +/- à répéter, et le pourcentage courant
    /// reste visible pendant le glissement.
    private func thresholdRow(_ label: LocalizedStringKey, value: Binding<Int>, in range: ClosedRange<Int>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.callout)
                Spacer()
                Text(Formatters.percent(Double(value.wrappedValue)))
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(
                value: Binding(
                    get: { Double(value.wrappedValue) },
                    set: { value.wrappedValue = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 5
            )
        }
        .padding(.vertical, 2)
    }
}

private struct AboutSettingsPane: View {
    var body: some View {
        Form {
            Section("À propos") {
                Text("MacInside — tableau de bord système macOS.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                // Signature volontairement non localisée (pas une chaîne UI,
                // un crédit fixe demandé tel quel par Vincent).
                Link("Design with love by Vincent Lauriat", destination: URL(string: "http://lauriat.fr")!)
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
    }
}
