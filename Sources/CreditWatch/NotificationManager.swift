import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private var previousRemaining: [String: Int] = [:]
    private var notifiedLow: Set<String> = []

    private init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func checkAndNotify(providers: [ProviderUsage]) {
        for provider in providers where provider.enabled && provider.remaining >= 0 {
            let key = provider.name
            let remaining = provider.remaining
            let prev = previousRemaining[key] ?? remaining

            // Alerta de cota crítica (<= 10% restante)
            if remaining <= 10 && prev > 10 && !notifiedLow.contains(key) {
                sendNotification(
                    title: "⚠️ Cota Baixa: \(provider.name)",
                    body: "Resta apenas \(remaining)\(provider.unit) disponível."
                )
                notifiedLow.insert(key)
            } else if remaining > 15 {
                notifiedLow.remove(key)
            }

            // Alerta de cota renovada (voltou para >= 95% vindo de cota baixa)
            if remaining >= 95 && prev <= 20 {
                sendNotification(
                    title: "🎉 Limite Renovado: \(provider.name)",
                    body: "Seu limite foi restaurado para \(remaining)%."
                )
            }

            previousRemaining[key] = remaining
        }
    }

    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
