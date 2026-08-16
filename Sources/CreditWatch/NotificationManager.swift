import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    // Chaves para UserDefaults — sobrevivem a relaunches
    private let lowKey = "cw.notifiedLow"
    private let prevKey = "cw.previousRemaining"

    private var notifiedLow: Set<String> {
        get { Set(UserDefaults.standard.stringArray(forKey: lowKey) ?? []) }
        set { UserDefaults.standard.set(Array(newValue), forKey: lowKey) }
    }

    private var previousRemaining: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: prevKey) as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: prevKey) }
    }

    private init() {
        requestAuthorization()
    }

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func checkAndNotify(providers: [ProviderUsage]) {
        var prev = previousRemaining
        var low = notifiedLow

        for provider in providers where provider.enabled && provider.remaining >= 0 {
            let key = provider.name
            let remaining = provider.remaining
            let prevValue = prev[key] ?? remaining

            // Alerta de cota crítica (<= 10% restante) — só dispara na transição de cruzamento
            if remaining <= 10 && prevValue > 10 && !low.contains(key) {
                sendNotification(
                    title: "⚠️ Cota Baixa: \(provider.name)",
                    body: "Resta apenas \(remaining)\(provider.unit) disponível."
                )
                low.insert(key)
            } else if remaining > 15 {
                low.remove(key)
            }

            // Alerta de cota renovada (voltou para >= 95% vindo de cota baixa)
            if remaining >= 95 && prevValue <= 20 {
                sendNotification(
                    title: "🎉 Limite Renovado: \(provider.name)",
                    body: "Seu limite foi restaurado para \(remaining)%."
                )
            }

            prev[key] = remaining
        }

        previousRemaining = prev
        notifiedLow = low
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
