# Architecture

Application SwiftUI **macOS uniquement** (macOS 14+). Pas de cible iOS : l'app dépend d'API bas niveau (IOKit/SMC, `libproc`, `host_statistics`) sans équivalent iOS.

## Vue d'ensemble

```
                    ┌─────────────────────────┐
                    │      MacInsideApp       │  @main — Scene(s)
                    │  WindowGroup + MenuBarExtra + Settings │
                    └────────────┬────────────┘
                                 │ .environment(AppSettings)
                                 │ .environment(AppModel)
                    ┌────────────▼────────────┐        ┌──────────────────┐
                    │      DashboardView       │        │   MenuBarView    │
                    │  Header + grille de cartes│        │  résumé compact  │
                    └────────────┬─────────────┘        └──────────────────┘
                                 │ lit
                    ┌────────────▼────────────┐
                    │        AppModel          │  @Observable @MainActor
                    │  identity/cpu/memory/... │  boucle de rafraîchissement (Task)
                    └────────────┬─────────────┘
                                 │ interroge à chaque tick
              ┌──────────────────┼───────────────────────────┐
              │                  │                            │
    ┌─────────▼────────┐ ┌───────▼────────┐        ┌──────────▼──────────┐
    │ SystemIdentity    │ │ CPUMonitor      │        │ SensorMonitor       │
    │ CPUMonitor        │ │ MemoryMonitor   │  ...   │ (client SMC IOKit)  │
    │ ProcessMonitor     │ │ NetworkMonitor  │        │ BatteryMonitor      │
    └───────────────────┘ └────────────────┘        └─────────────────────┘
```

## Couches

| Couche | Rôle | Fichiers |
|---|---|---|
| **App** | Scènes (fenêtre, menu bar, réglages), injection de `AppSettings`/`AppModel` | `MacInsideApp.swift` |
| **AppModel** | Agrégation de tous les providers sur une seule boucle de rafraîchissement | `AppModel.swift` |
| **Providers** | Accès système bas niveau, un type par domaine | `Providers/*.swift` |
| **Models** | Structs de données publiées par les providers (pas de logique) | `Models/Metrics.swift` |
| **Views** | SwiftUI pur — dashboard + cartes | `Views/*.swift`, `Views/Components/*.swift` |
| **MenuBar** | Contenu de l'icône et du dropdown menu bar | `MenuBar/*.swift` |
| **Settings** | Apparence + intervalle de rafraîchissement, persistés en `UserDefaults` | `Settings/AppSettings.swift` |

## Décisions clés

- **App Sandbox désactivé** (`MacInside.entitlements`) : requis pour la lecture SMC (température/ventilateurs) et l'énumération des process via `libproc`. Distribution Developer ID + notarisation, pas de Mac App Store (cohérent avec les autres apps macOS du repo).
- **Un seul timer de rafraîchissement** dans `AppModel` (intervalle réglable, 1s par défaut) plutôt qu'un timer par provider — évite les rafraîchissements désynchronisés et simplifie le throttling.
- **Providers synchrones et rapides**, sauf la résolution IP publique/pays (`PublicAddressLookup`, `actor`) qui est asynchrone, mise en cache 5 min, et ne bloque jamais le tick local en cas d'échec réseau.
- **`SensorMonitor`** ouvre la connexion SMC une seule fois (pas de coût d'ouverture à chaque tick) et dégrade proprement (`SensorStats.available = false`) si le service SMC est indisponible ou si le Mac n'a pas de ventilateur — l'UI masque alors la carte plutôt que d'afficher des zéros.
- **Identité machine** résolue via `system_profiler SPHardwareDataType -json` (une fois, mis en cache) : c'est le seul moyen public fiable d'obtenir un nom marketing ("Mac Studio (2022)", "Apple M1 Max") plutôt qu'un identifiant brut (`Mac13,1`).
- **Observation** (`@Observable`, Swift 5.9) plutôt que `ObservableObject`.
- **Ouverture de la fenêtre dashboard depuis le menu bar** : `openWindow()` sans `id` n'existe pas dans ce SDK (seul `openWindow(id:)`, et le `WindowGroup` de `MacInsideApp.swift` n'a pas d'id dédié). `MenuBarView` utilise donc `NSApp.activate(ignoringOtherApps:)` + récupération de la première fenêtre non-`NSPanel` via `NSApp.windows`.
- **Pas de carte "Carte graphique"** dans `HeaderView` : `SystemIdentity` n'expose pas de champ GPU dédié (pas de source fiable distincte de `chipName` sur Apple Silicon où CPU/GPU partagent le même SoC) — omis plutôt qu'inventé.
- **Build** : projet Xcode généré par XcodeGen (`project.yml`), `.xcodeproj` non versionné. Régénérer avec `xcodegen generate`.
- **Signature/notarisation** : gérées manuellement dans `release.sh` (Developer ID + Hardened Runtime + timestamp avec retry), car `xcodebuild` en Release échoue souvent sur les xattrs `com.apple.provenance`.

## Ajouter un domaine de métrique

1. Ajoute la struct de données dans `Models/Metrics.swift`.
2. Crée `Providers/MonDomaine.swift` avec une méthode `snapshot() -> MaStruct` synchrone et rapide.
3. Branche-le dans `AppModel.refresh()`.
4. Crée la carte SwiftUI correspondante dans `Views/`, en réutilisant `Views/Components/` et `Formatters`.
