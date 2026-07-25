# PRD — MacInside

**Statut** : v1.0.0 publiée ; Phases 3.1–3.8 implémentées sur `feature/phase-3-battery-improvements` (non mergée) ; 3.9 et 3.R non démarrées.
**Dernière mise à jour** : 2026-07-24

## 1. Résumé exécutif

MacInside est un tableau de bord système macOS natif (fenêtre + barre de menu) qui affiche en temps réel l'identité machine, le CPU, la mémoire, le stockage, le réseau, les capteurs matériels (température/ventilateurs), le GPU et la batterie — sans shell-out vers `top`/`iostat`, en parlant directement à `host_statistics`, IOKit (`AppleSMC`, `IOAccelerator`, `IOBlockStorageDriver`) et `libproc`.

Objectif produit (formulé par Vincent, 2026-07-24) : **dépasser iStat Menus** sur la couverture générale, et **égaler Juicy** — référence du genre — sur la partie batterie.

## 2. Problème

macOS n'offre pas de vue unifiée de l'état du système : Activity Monitor pour les process, Réglages Système pour la santé batterie, rien du tout pour les ventilateurs ou les températures SMC. Les outils existants couvrent une partie du besoin chacun :
- **Activity Monitor** (Apple, gratuit) : process/CPU/mémoire/disque/réseau, pas de capteurs ni de batterie détaillée.
- **iStat Menus** (payant, ~12 €) : couverture large (CPU/mémoire/disque/réseau/capteurs/batterie/GPU), interface dense, pas d'actions sur les process, pas de limitation de charge.
- **Juicy** (payant, dédié batterie) : santé/cycles/température/tension, limitation de charge 50–100 % (« Sailing Mode »), batteries des accessoires connectés, énergie par app avec historique 24h/7j/30j, alertes personnalisées — mais ne couvre pas le reste du système.
- **Stats.app** (open-source, gratuit) : couverture large façon iStat Menus, pas d'équivalent Juicy sur la batterie.

Aucun outil ne combine couverture système large **et** profondeur batterie façon Juicy, dans une seule app native, gratuite et non-sandboxée (donc capable d'actions que les apps App Store ne peuvent pas faire, comme terminer un process).

## 3. Utilisateurs cibles

- **Utilisateur principal** : Vincent (développeur, power user macOS), qui utilise l'app quotidiennement sur son propre matériel (MacBook Air M-series) et pilote directement les priorités produit.
- **Utilisateurs secondaires** : power users macOS francophones/anglophones cherchant un remplaçant gratuit à iStat Menus, distribué en Developer ID (pas de compte App Store nécessaire), avec auto-update Sparkle.

## 4. Objectifs & non-objectifs

### Objectifs
- Une seule fenêtre + barre de menu personnalisable couvrant l'ensemble des métriques système pertinentes pour un power user.
- Sur la batterie spécifiquement : égaler la profondeur de Juicy (santé, cycles, température, alertes, accessoires, éventuellement limitation de charge et énergie par app).
- Rester une app légère, non-sandboxée en Developer ID — permet des capacités qu'une variante App Store n'aurait jamais (actions sur les process, futures écritures SMC).
- Localisation FR/EN complète, cohérente avec le fait que Vincent développe et communique en français.

### Non-objectifs (pour l'instant)
- Pas de version App Store (le sandbox interdirait plusieurs fonctionnalités déjà livrées : lecture SMC, actions sur les process).
- Pas de télémétrie/analytics utilisateur.
- Pas de support Intel legacy au-delà de ce que macOS 14+ couvre nativement.
- Pas d'objectif de monétisation actuellement (app gratuite).

## 5. Périmètre fonctionnel

### 5.1 Déjà livré (v1.0.0, release publique 2026-07-11)
- Dashboard « masonry » (grille auto-adaptative, cartes réordonnables par glisser-déposer) : Identité système, CPU, Mémoire, Stockage (volume système + volumes externes), Réseau (identité + débit), Capteurs (température/ventilateurs/alimentation), GPU, Batterie.
- Barre de menu : mode Combiné (un seul dropdown) ou Icônes séparées par métrique (CPU/Mémoire/Réseau/Disque/Batterie/GPU), chacune configurable indépendamment.
- Localisation FR/EN complète (String Catalog), langue système par défaut.
- Auto-update Sparkle (clé EdDSA dédiée, vérification manuelle ou automatique).
- Distribution Developer ID signée + notarisée, DMG, `Scripts/release.sh` reproductible.
- Réglages : apparence (système/clair/sombre), intervalle de rafraîchissement, style de barre de menu.

### 5.2 Phase 3 — en cours sur branche, pas encore mergée dans `main`

| Sous-phase | Fonctionnalité | Statut |
|---|---|---|
| 3.1 | Carte Batterie enrichie (température, puissance) | ✅ |
| 3.2 | Alertes de seuil batterie personnalisées (bas/haut, notifications) | ✅ |
| 3.3 | Historique & mini-graphes (CPU/Mémoire/GPU/Température) | ✅ |
| 3.4 | Débit I/O disque (lecture/écriture, agrégé) | ✅ |
| 3.5 | Batteries des accessoires Bluetooth connectés (AirPods, HID) | ✅ |
| 3.6 | Démarrage au login, réglages granulaires par carte dashboard | ✅ |
| 3.7 | Actions sur les process (terminer/forcer l'arrêt/baisser la priorité) | ✅ |
| 3.8 | Tests unitaires (`Formatters`, `SafeDelta`) | ✅ |
| — | Correctif fenêtre Réglages (refonte en onglets) | ✅ |
| 3.9 | Énergie par app avec historique 24h/7j/30j | ⏸ à cadrer séparément |
| 3.R | R&D limitation de charge batterie (écriture SMC, façon AlDente/Juicy) | ⏸ gelée, feu vert explicite requis |

Détail technique complet de chaque sous-phase (décisions, vérifications, pièges évités) dans `PLAN.md` et `MEMORY.md`.

### 5.3 Backlog non cadré (au-delà de la Phase 3)
- Tension batterie : recherché, aucune clé SMC documentée trouvée — non implémenté par principe (pas de clé devinée).
- Extension `temperatureKeys` pour les efficiency cores 5/6 Apple Silicon — même principe de prudence, non fait.

## 6. Contraintes techniques

- **Cible unique macOS 14+**, app non-sandboxée, distribution Developer ID (`KFLACS69T9`) + notarisation, jamais Mac App Store tant que les fonctionnalités actuelles (lecture SMC, kill process) sont dans le périmètre.
- **SwiftUI + Observation** (`@Observable`/`@MainActor`), un seul timer de rafraîchissement central (`AppModel`), intervalle configurable 0.5–5 s.
- **Sources de données** : `host_processor_info`/`vm_statistics64` (CPU/mémoire), IOKit `AppleSMC` (température/ventilateurs/alimentation), IOKit `IOAccelerator` (GPU), IOKit `IOBlockStorageDriver` (débit disque, agrégé — pas de ventilation fiable par volume APFS), `getifaddrs` (réseau), `libproc` (process), `system_profiler -json SPBluetoothDataType` (accessoires Bluetooth — IOKit/IOBluetooth privé testés et rejetés, voir `MEMORY.md`), `SMAppService` (démarrage au login).
- **Aucune clé SMC ou API privée non documentée n'est utilisée sans vérification empirique préalable** (`ioreg`, recherche communautaire) — principe déjà appliqué plusieurs fois (tension batterie, accessoires Bluetooth).
- **Localisation** : String Catalog (`Localizable.xcstrings`), source FR, traduction EN systématique pour toute nouvelle chaîne UI.

## 7. Risques

| Risque | Mitigation |
|---|---|
| Clés SMC non documentées, instables entre puces/générations | Dégradation propre (section masquée), jamais de valeur devinée |
| API privées (IOBluetooth) peu fiables selon le contexte de process | Préférer une source publique/stable (`system_profiler`) même si techniquement moins « élégante » |
| Actions destructives (kill process, futur SMC write) | Confirmation avant toute action destructive ; R&D limitation de charge explicitement gelée sans feu vert |
| Régression d'UX au fil des ajouts (ex. fenêtre Réglages devenue trop haute) | Revoir la structure (onglets) dès qu'un pattern d'empilement simple ne passe plus à l'échelle, plutôt que de compenser par du calcul de hauteur |
| Automatisation de vérification (AppleScript/System Events) pouvant avoir des effets de bord réels sur la machine de test | Toujours revérifier l'état système après une action interactive automatisée (`sfltool`, `defaults read`), ne pas supposer qu'un clic « sans erreur » a fait ce qui était prévu |

## 8. Definition of Done (par fonctionnalité)

Reprend la discipline déjà appliquée sur toutes les sous-phases de la Phase 3 :
1. Recherche/vérification préalable du mécanisme technique (`ioreg`, doc, test isolé) avant d'écrire le code de production.
2. Build vérifié (`xcodegen generate` + `xcodebuild build`) après chaque changement.
3. Vérification fonctionnelle réelle — pas seulement compilation : test numérique isolé quand l'UI n'est pas automatisable, ou capture d'écran avec données réelles sinon.
4. Chaînes UI ajoutées en FR **et** EN.
5. Documentation à jour dans le même tour (`CHANGES.md`, `MEMORY.md`, `TODOS.md`, `PLAN.md`).
6. Commit dédié sur une branche feature, jamais direct sur `main`.

## 9. Prochaines décisions à prendre avec Vincent

- Merger `feature/phase-3-battery-improvements` dans `main` (9 commits prêts, tous vérifiés).
- Cadrer la Phase 3.9 (énergie par app) : viabilité de `proc_pid_rusage` sur Apple Silicon + conception du stockage persistant (hors périmètre des buffers mémoire actuels).
- Décider si/quand lancer le spike de faisabilité de la Phase 3.R (limitation de charge) — actuellement gelée.
