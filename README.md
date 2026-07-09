# MacInside

Tableau de bord système pour macOS — fenêtre dashboard + icône menu bar, façon iStat Menus / Stats. Affiche en temps réel l'identité de la machine, le CPU, la mémoire, le réseau, le stockage et les capteurs matériels (température, ventilateurs).

## Features

| Feature | Statut |
|---|:---:|
| Identité machine (modèle, puce, OS, série, uptime, état thermique) | ✅ |
| CPU (charge système/utilisateur, cœurs perf/efficiency, top process) | ✅ |
| Mémoire (wired/active/compressed/available, top process) | ✅ |
| Stockage (volume système + volumes externes) | ✅ |
| Réseau (IP locale/publique, débit down/up) | ✅ |
| Capteurs (température, ventilateurs via SMC) | ✅ |
| Batterie (si présente) | ✅ |
| Fenêtre dashboard | ✅ |
| Icône menu bar (résumé + accès dashboard) | ✅ |

## Build

Prérequis : Xcode 15+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate          # génère MacInside.xcodeproj
open MacInside.xcodeproj   # scheme MacInside
```

> App Sandbox désactivé (`MacInside/MacInside.entitlements`) : nécessaire pour l'accès SMC (capteurs) et l'énumération des process. Distribution Developer ID + notarisation, pas de Mac App Store.

## Release (macOS)

```bash
./Scripts/release.sh 1.0.0   # build → sign Developer ID → DMG → notarize → staple
```

## Project layout

```
MacInside/
├── MacInsideApp.swift        # @main — WindowGroup (dashboard) + MenuBarExtra + Settings
├── AppModel.swift            # agrégation des providers, boucle de rafraîchissement
├── Formatters.swift          # formatage bytes/pourcentage/uptime/température
├── Models/Metrics.swift      # structs de données (CPUStats, MemoryStats, ...)
├── Providers/                # accès système bas niveau (host_statistics, IOKit, SMC, libproc...)
├── Settings/AppSettings.swift
├── Views/                    # DashboardView + cartes (CPU, Mémoire, Réseau, Capteurs...)
├── Views/Components/         # anneau de charge, mini-graphiques, carte réutilisable
└── MenuBar/                  # contenu de l'icône et du dropdown menu bar
Scripts/                      # release.sh, make-app-icon.swift, make-dmg-background.swift
project.yml                   # config XcodeGen
```

## Licence

MIT — voir [`LICENSE`](LICENSE).
