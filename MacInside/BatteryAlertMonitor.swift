import Foundation
import UserNotifications

/// Surveille le pourcentage de batterie à chaque rafraîchissement et déclenche
/// une notification locale à chaque franchissement de seuil (bas ou haut),
/// sans répéter tant que le seuil reste franchi — même logique que Juicy.
@MainActor
final class BatteryAlertMonitor {
    private var isBelowLowThreshold = false
    private var isAboveHighThreshold = false
    private var hasEvaluatedOnce = false

    func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func evaluate(battery: BatteryStats, settings: AppSettings) {
        guard battery.isPresent else { return }

        let isLow = settings.lowBatteryAlertEnabled
            && !battery.isCharging
            && battery.percentage <= settings.lowBatteryAlertThreshold
        let isHigh = settings.highBatteryAlertEnabled
            && battery.percentage >= settings.highBatteryAlertThreshold

        // Le premier passage n'est qu'une mesure de référence : on ne notifie
        // jamais dès le lancement de l'app, seulement lors d'un vrai franchissement.
        if hasEvaluatedOnce {
            if isLow, !isBelowLowThreshold {
                notifyLow(percentage: battery.percentage)
            }
            if isHigh, !isAboveHighThreshold {
                notifyHigh(percentage: battery.percentage)
            }
        }

        isBelowLowThreshold = isLow
        isAboveHighThreshold = isHigh
        hasEvaluatedOnce = true
    }

    private func notifyLow(percentage: Int) {
        let percentText = Formatters.percent(Double(percentage))
        notify(title: String(localized: "Batterie faible"),
               body: String(localized: "\(percentText) restants."))
    }

    private func notifyHigh(percentage: Int) {
        let percentText = Formatters.percent(Double(percentage))
        notify(title: String(localized: "Batterie chargée"),
               body: String(localized: "\(percentText) — vous pouvez débrancher le chargeur."))
    }

    private func notify(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        UNUserNotificationCenter.current().add(
            UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
