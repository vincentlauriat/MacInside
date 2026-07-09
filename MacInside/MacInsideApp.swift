import SwiftUI

@main
struct MacInsideApp: App {
    @State private var settings = AppSettings()
    @State private var model: AppModel

    init() {
        let settings = AppSettings()
        _settings = State(initialValue: settings)
        _model = State(initialValue: AppModel(settings: settings))
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(settings)
                .environment(model)
                .preferredColorScheme(settings.appearance.colorScheme)
                .onAppear { model.start() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1180, height: 760)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }

        MenuBarExtra {
            MenuBarView()
                .environment(settings)
                .environment(model)
                .onAppear { model.start() }
        } label: {
            MenuBarLabel()
                .environment(model)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(settings)
        }
    }
}
