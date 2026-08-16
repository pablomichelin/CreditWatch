import Foundation
import SwiftUI
import WebKit

enum ProviderKind: String, CaseIterable, Codable, Identifiable {
    case codex = "Codex"
    case chatgpt = "ChatGPT"
    case claude = "Claude"
    case cursor = "Cursor"
    case gemini = "Gemini"
    case antigravity = "Antigravity"
    case grok = "Grok"
    case custom = "Outro"

    var id: String { rawValue }
    static var supportedCases: [ProviderKind] { allCases.filter { $0 != .custom } }

    var color: Color {
        switch self {
        case .codex: .green
        case .chatgpt: .teal
        case .claude: .orange
        case .cursor: .blue
        case .gemini: .red
        case .antigravity: .purple
        case .grok: .indigo
        case .custom: .gray
        }
    }

    var usageURL: URL? {
        switch self {
        case .cursor: URL(string: "https://cursor.com/dashboard/billing")
        case .codex: URL(string: "https://chatgpt.com/codex/settings/usage")
        case .chatgpt: URL(string: "https://chatgpt.com/")
        case .claude: URL(string: "https://claude.ai/new#settings/billing")
        case .gemini: URL(string: "https://aistudio.google.com/rate-limit?timeRange=last-28-days")
        case .antigravity: nil
        case .grok: URL(string: "https://grok.com/?_s=usage")
        case .custom: nil
        }
    }
}

struct ProviderUsage: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var kind: ProviderKind
    /// -1 significa que o provedor ainda não foi consultado.
    var remaining: Int
    var unit: String
    var resetsAt: Date?
    var detail: String? = nil
    var resetLabel: String? = nil
    var lastUpdatedAt: Date? = nil
    var enabled = true

    static let defaults: [ProviderUsage] = [
        .init(name: "Codex · limite semanal", kind: .codex, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Codex · créditos", kind: .codex, remaining: -1, unit: "créditos", resetsAt: nil),
        .init(name: "ChatGPT", kind: .chatgpt, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Claude", kind: .claude, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Cursor · Models", kind: .cursor, remaining: -1, unit: "% usado", resetsAt: nil),
        .init(name: "Cursor · Other Models", kind: .cursor, remaining: -1, unit: "% usado", resetsAt: nil),
        .init(name: "Cursor · On-Demand", kind: .cursor, remaining: -1, unit: "% usado", resetsAt: nil),
        .init(name: "Gemini · RPM", kind: .gemini, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Gemini · TPM", kind: .gemini, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Gemini · RPD", kind: .gemini, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Antigravity · Gemini semanal", kind: .antigravity, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Antigravity · Gemini 5h", kind: .antigravity, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Antigravity · Claude/GPT semanal", kind: .antigravity, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Antigravity · Claude/GPT 5h", kind: .antigravity, remaining: -1, unit: "% restante", resetsAt: nil),
        .init(name: "Grok · limite semanal", kind: .grok, remaining: -1, unit: "% restante", resetsAt: nil)
    ]
}

@MainActor
final class UsageStore: ObservableObject {
    @Published var providers: [ProviderUsage] { didSet { save() } }
    @Published private(set) var isRefreshing = false

    private let storageURL: URL
    private var refreshController: UsageRefreshController?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("CreditWatch", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        storageURL = directory.appendingPathComponent("usage.json")
        providers = Self.normalized(Self.load(from: storageURL) ?? ProviderUsage.defaults)
    }

    var menuBarTitle: String {
        let active = providers.filter(\.enabled)
        guard !active.isEmpty else { return "IA" }
        return active.contains(where: { ($0.resetsAt ?? .distantFuture) <= .now }) ? "IA !" : "IA \(active.count)"
    }

    var lastUpdatedAt: Date? {
        providers.compactMap(\.lastUpdatedAt).max()
    }

    var refreshStatus: String {
        if isRefreshing { return "Atualizando…" }
        guard let lastUpdatedAt else { return "Aguardando primeira leitura" }
        return "Atualizado " + lastUpdatedAt.formatted(.relative(presentation: .named))
    }

    func startAutoRefresh() {
        guard refreshController == nil else { return }
        let controller = UsageRefreshController(store: self)
        refreshController = controller
        controller.start()
    }

    func refreshNow() {
        startAutoRefresh()
        refreshController?.refreshAll()
    }

    func setRefreshing(_ refreshing: Bool) {
        isRefreshing = refreshing
    }

    func addAccount(kind: ProviderKind) {
        let metrics = ProviderUsage.defaults.filter { $0.kind == kind }
        if !metrics.isEmpty {
            providers.append(contentsOf: metrics)
            return
        }
        let name = kind == .custom ? "Nova IA" : kind.rawValue
        providers.append(.init(name: name, kind: kind, remaining: -1, unit: "% restante", resetsAt: nil))
    }

    func remove(at offsets: IndexSet) { providers.remove(atOffsets: offsets) }
    func remove(id: UUID) { providers.removeAll { $0.id == id } }
    func removeAccount(kind: ProviderKind) { providers.removeAll { $0.kind == kind } }

    /// Compatibilidade com versões antigas que usavam um conector externo.
    func importUsage(from url: URL) {
        guard url.scheme == "creditwatch", url.host == "update",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        let query = Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        switch query["provider"] {
        case "cursor":
            update(name: "Cursor · Models", remaining: Int(query["models"] ?? "") ?? 0, unit: "% usado")
            update(name: "Cursor · Other Models", remaining: Int(query["other"] ?? "") ?? 0, unit: "% usado")
            update(name: "Cursor · On-Demand", remaining: Int(query["onDemand"] ?? "") ?? 0, unit: "% usado")
            if let days = Double(query["resetDays"] ?? "") {
                setReset(for: .cursor, at: .now.addingTimeInterval(days * 86_400))
            }
        case "codex":
            update(name: "Codex · limite semanal", remaining: Int(query["weekly"] ?? "") ?? 0, unit: "% restante")
            if let text = query["resetText"], let date = parsePortugueseDate(text) {
                setReset(for: .codex, at: date)
            }
        case "gemini":
            update(name: "Gemini · RPD", remaining: Int(query["usage"] ?? "") ?? 0, unit: "% restante")
        case "claude":
            update(name: "Claude", remaining: Int(query["usage"] ?? "") ?? 0, unit: "% usado")
        default: return
        }
    }

    /// Atualiza somente campos que aparecem de forma clara no texto mostrado
    /// pelo painel ao qual o próprio usuário fez login.
    func importVisibleUsage(_ text: String, for kind: ProviderKind) -> String {
        switch kind {
        case .cursor:
            let matches: [(String, String)] = [
                ("Cursor · Models", "Cursor Models"),
                ("Cursor · Other Models", "Other Models")
            ]
            var updates = 0
            for (name, heading) in matches {
                if let used = percentage(after: heading, in: text, marker: "%") {
                    update(name: name, remaining: max(0, 100 - used), unit: "% restante")
                    updates += 1
                }
            }
            if let money = moneyUsage(after: "On-Demand", in: text) {
                let available = max(0, money.limit - money.used)
                let remaining = Int((available / money.limit * 100).rounded())
                update(name: "Cursor · On-Demand", remaining: remaining, unit: "% restante",
                       resetLabel: "\(currency(available)) disponíveis de \(currency(money.limit))")
                setReset(names: ["Cursor · On-Demand"], at: nil)
                updates += 1
            }
            if let reset = resetDate(in: text) {
                setReset(names: ["Cursor · Models", "Cursor · Other Models"], at: reset)
            }
            return updates == 0 ? "Abra Plan & Usage para atualizar." : "Cursor atualizado."
        case .codex:
            let remaining = percentage(after: "Limite de uso semanal", in: text, marker: "% restante")
                ?? percentage(after: "Weekly usage limit", in: text, marker: "%")
                ?? percentage(after: "Weekly limit", in: text, marker: "% remaining")
            var updated = false
            if let remaining {
                update(name: "Codex · limite semanal", remaining: remaining, unit: "% restante")
                if let reset = resetDate(in: text) { setReset(names: ["Codex · limite semanal"], at: reset) }
                updated = true
            }
            if let balance = creditBalance(in: text) {
                update(name: "Codex · créditos", remaining: -1, unit: "créditos",
                       detail: balance, resetLabel: "saldo disponível")
                updated = true
            }
            return updated ? "Codex atualizado." : "Abra Uso e cobrança para atualizar."
        case .chatgpt:
            let plan = chatGPTPlan(in: text)
            let remaining = percentage(after: "ChatGPT", in: text, marker: "% restante")
                ?? percentage(after: "ChatGPT", in: text, marker: "% remaining")
            if let remaining {
                update(name: "ChatGPT", remaining: remaining, unit: "% restante",
                       detail: plan, resetLabel: nil)
                if let reset = resetDate(in: text) { setReset(for: .chatgpt, at: reset) }
            } else {
                update(name: "ChatGPT", remaining: -1, unit: "% restante",
                       detail: "\(plan) · limites variam por recurso",
                       resetLabel: "O ChatGPT não publica um saldo único")
            }
            return "ChatGPT conectado."
        case .claude:
            if text.range(of: "Free plan", options: .caseInsensitive) != nil
                || text.range(of: "Plano gratuito", options: .caseInsensitive) != nil {
                update(name: "Claude", remaining: -1, unit: "% restante",
                       detail: "Plano Free · percentual não informado",
                       resetLabel: "O Claude não publica reset para este plano")
                return "Claude conectado · plano Free."
            }
            if text.range(of: "Max plan", options: .caseInsensitive) != nil
                || text.range(of: "Pro plan", options: .caseInsensitive) != nil {
                update(name: "Claude", remaining: -1, unit: "% restante",
                       detail: "Plano conectado · percentual não informado",
                       resetLabel: "Abra Usage se o plano publicar limites")
                return "Claude conectado."
            }
            return "Abra Billing ou Usage para atualizar."
        case .gemini:
            var updated = false
            let modelHeadings = ["Gemini 2.5 Flash", "Gemini 2.0 Flash", "Gemini 1.5 Flash", "Gemini 3.6 Flash", "Gemini Flash", "Gemini"]
            for heading in modelHeadings {
                if let ratios = quotaRatios(in: text, after: heading), ratios.count >= 3 {
                    let tier = text.range(of: "Nível gratuito", options: .caseInsensitive) != nil
                        ? "Nível gratuito" : "Projeto conectado"
                    updateQuotaMetrics(prefix: "Gemini", kind: .gemini, ratios: ratios, detailPrefix: tier)
                    updated = true
                    break
                }
            }
            guard updated else {
                return "Abra Rate limits para atualizar."
            }
            return "Google AI Studio atualizado."
        case .antigravity:
            return "O Antigravity é atualizado diretamente pelo aplicativo local."
        case .grok:
            let plan = grokPlan(in: text)
            let used = percentage(after: "Weekly SuperGrok Limit", in: text, marker: "%")
                ?? percentage(after: "Limite semanal do SuperGrok", in: text, marker: "%")
                ?? percentage(after: "Uso semanal", in: text, marker: "%")
            if let used {
                update(name: "Grok · limite semanal", remaining: max(0, 100 - used), unit: "% restante",
                       detail: "\(plan) · \(used)% usado", resetLabel: nil)
                if let reset = resetDate(in: text) { setReset(for: .grok, at: reset) }
                return "Grok atualizado."
            }
            update(name: "Grok · limite semanal", remaining: -1, unit: "% restante",
                   detail: "\(plan) · percentual não informado",
                   resetLabel: plan == "Plano Free"
                       ? "O plano Free usa limites separados"
                       : "Abra Settings → Usage para atualizar")
            return "Grok conectado; abra Usage para ler o limite."
        case .custom:
            return "Este provedor ainda não possui leitura automática."
        }
    }

    private func update(name: String, remaining: Int, unit: String,
                        detail: String? = nil, resetLabel: String? = nil) {
        guard let index = providers.firstIndex(where: { $0.name == name }) else { return }
        providers[index].remaining = remaining
        providers[index].unit = unit
        providers[index].detail = detail
        providers[index].resetLabel = resetLabel
        providers[index].lastUpdatedAt = .now
    }

    func importAntigravityUsage(_ data: Data) -> Bool {
        struct Envelope: Decodable {
            struct Response: Decodable {
                struct Group: Decodable {
                    struct Bucket: Decodable {
                        let bucketId: String
                        let remainingFraction: Double?
                        let resetTime: String?
                    }
                    let displayName: String
                    let buckets: [Bucket]
                }
                let groups: [Group]
            }
            let response: Response
        }

        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data) else { return false }
        let names = [
            "gemini-weekly": "Antigravity · Gemini semanal",
            "gemini-5h": "Antigravity · Gemini 5h",
            "3p-weekly": "Antigravity · Claude/GPT semanal",
            "3p-5h": "Antigravity · Claude/GPT 5h"
        ]
        var count = 0
        for group in envelope.response.groups {
            for bucket in group.buckets {
                guard let name = names[bucket.bucketId], let fraction = bucket.remainingFraction else { continue }
                update(name: name, remaining: Int((fraction * 100).rounded()), unit: "% restante",
                       detail: group.displayName, resetLabel: nil)
                if let value = bucket.resetTime, let date = ISO8601DateFormatter().date(from: value) {
                    setReset(names: [name], at: date)
                }
                count += 1
            }
        }
        return count == 4
    }

    private func updateQuotaMetrics(
        prefix: String,
        kind: ProviderKind,
        ratios: [(used: Double, limit: Double, original: String)],
        detailPrefix: String
    ) {
        let metrics = [
            ("\(prefix) · RPM", ratios[0], "renova a cada minuto"),
            ("\(prefix) · TPM", ratios[1], "renova a cada minuto"),
            ("\(prefix) · RPD", ratios[2], "renova diariamente")
        ]
        for (name, ratio, resetLabel) in metrics where providers.contains(where: { $0.kind == kind && $0.name == name }) {
            let remaining = ratio.limit > 0
                ? Int((max(0, ratio.limit - ratio.used) / ratio.limit * 100).rounded()) : 0
            update(name: name, remaining: remaining, unit: "% restante",
                   detail: "\(detailPrefix) · \(ratio.original)", resetLabel: resetLabel)
        }
    }

    private func setReset(for kind: ProviderKind, at date: Date) {
        for index in providers.indices where providers[index].kind == kind {
            providers[index].resetsAt = date
        }
    }

    private func setReset(names: Set<String>, at date: Date?) {
        for index in providers.indices where names.contains(providers[index].name) {
            providers[index].resetsAt = date
        }
    }

    private func parsePortugueseDate(_ text: String) -> Date? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let formats = [
            "d 'de' MMM. 'de' yyyy, HH:mm",
            "d 'de' MMM 'de' yyyy, HH:mm",
            "d 'de' MMMM 'de' yyyy, HH:mm",
            "d 'de' MMM. 'de' yyyy",
            "d 'de' MMM 'de' yyyy",
            "d 'de' MMMM 'de' yyyy"
        ]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        for format in formats {
            formatter.dateFormat = format
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }

    private func percentage(after heading: String, in text: String, marker: String = "% used") -> Int? {
        guard let range = text.range(of: heading, options: .caseInsensitive) else { return nil }
        return percentage(in: String(text[range.lowerBound...]), marker: marker)
    }

    private func percentage(in text: String, marker: String) -> Int? {
        let pattern = #"([0-9]{1,3}(?:\.[0-9]+)?)\s*"# + NSRegularExpression.escapedPattern(for: marker)
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let range = Range(match.range(at: 1), in: text) else { return nil }
        return Double(text[range]).map { Int($0.rounded()) }
    }

    private func moneyUsage(after heading: String, in text: String) -> (used: Double, limit: Double)? {
        guard let range = text.range(of: heading, options: .caseInsensitive) else { return nil }
        let suffix = String(text[range.lowerBound...])
        let pattern = #"(?:US)?\$\s*([0-9]+(?:\.[0-9]+)?)\s*/\s*(?:US)?\$\s*([0-9]+(?:\.[0-9]+)?)"#
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let match = expression.firstMatch(in: suffix, range: NSRange(suffix.startIndex..., in: suffix)),
              let first = Range(match.range(at: 1), in: suffix),
              let second = Range(match.range(at: 2), in: suffix),
              let used = Double(suffix[first]), let limit = Double(suffix[second]), limit > 0 else { return nil }
        return (used, limit)
    }

    private func creditBalance(in text: String) -> String? {
        let patterns = [
            #"(?:Saldo de créditos|Credit balance|Balance)[\s\S]{0,180}?((?:R\$|US\$|\$|€)\s*[0-9][0-9.,]*)"#,
            #"(?:Saldo de créditos|Credit balance|Balance)[\s\S]{0,180}?([0-9]+(?:[.,][0-9]+)?\s*(?:créditos|credits))"#
        ]
        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else { continue }
            return String(text[range])
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }

    private func currency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "US$ %.2f", value)
    }

    private func chatGPTPlan(in text: String) -> String {
        let lines = text.split(separator: "\n").map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        if lines.contains(where: { $0 == "pro" || $0.hasSuffix(" pro") || $0.contains("chatgpt pro") }) {
            return "Plano Pro"
        }
        if lines.contains(where: { $0 == "plus" || $0.hasSuffix(" plus") || $0.contains("chatgpt plus") }) {
            return "Plano Plus"
        }
        if lines.contains(where: { $0 == "go" || $0.hasSuffix(" go") || $0.contains("chatgpt go") }) {
            return "Plano Go"
        }
        if lines.contains("chatgpt free") || lines.contains("free") || lines.contains("gratuito") {
            return "Plano Free"
        }
        return "Plano conectado"
    }

    private func grokPlan(in text: String) -> String {
        let lower = text.lowercased()
        if lower.contains("supergrok heavy") { return "SuperGrok Heavy" }
        if lower.contains("supergrok lite") { return "SuperGrok Lite" }
        if lower.contains("supergrok") { return "SuperGrok" }
        if lower.contains("free") || lower.contains("gratuito") { return "Plano Free" }
        return "Plano conectado"
    }

    private func resetDate(in text: String) -> Date? {
        let patterns = [
            #"Redefinição\s+([0-9]{1,2}\s+de\s+\w+\.?\s+de\s+[0-9]{4},\s*[0-9]{1,2}:[0-9]{2})"#,
            #"resets?\s+(?:on\s+)?([A-Za-z]{3,9}\s+[0-9]{1,2},\s+[0-9]{4}(?:\s+(?:at\s+)?[0-9]{1,2}:[0-9]{2}\s*(?:[AP]M)?)?)"#,
            #"renews?\s+(?:on\s+)?([A-Za-z]{3,9}\s+[0-9]{1,2},\s+[0-9]{4}(?:\s+(?:at\s+)?[0-9]{1,2}:[0-9]{2}\s*(?:[AP]M)?)?)"#,
            #"auto renew on\s+([0-9]{1,2}\s+[A-Za-z]{3,9}\s+[0-9]{4})"#
        ]
        for pattern in patterns {
            guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
                  let match = expression.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
                  let range = Range(match.range(at: 1), in: text) else { continue }
            let value = String(text[range])
            if let exact = parsePortugueseDate(value) { return exact }
            let formats = [
                "MMM d, yyyy h:mm a",
                "MMM d, yyyy 'at' h:mm a",
                "MMMM d, yyyy h:mm a",
                "MMMM d, yyyy 'at' h:mm a",
                "d MMMM yyyy",
                "MMM d, yyyy",
                "MMMM d, yyyy"
            ]
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: value) { return date }
            }
        }
        return nil
    }

    private func quotaRatios(in text: String, after heading: String) -> [(used: Double, limit: Double, original: String)]? {
        let relevant: String
        if let range = text.range(of: heading, options: .caseInsensitive) {
            relevant = String(text[range.lowerBound...])
        } else {
            return nil
        }
        let pattern = #"([0-9]+(?:\.[0-9]+)?[KMB]?)\s*/\s*([0-9]+(?:\.[0-9]+)?[KMB]?)"#
        guard let expression = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        let matches = expression.matches(in: relevant, range: NSRange(relevant.startIndex..., in: relevant)).prefix(3)
        let values = matches.compactMap { match -> (Double, Double, String)? in
            guard let first = Range(match.range(at: 1), in: relevant),
                  let second = Range(match.range(at: 2), in: relevant),
                  let whole = Range(match.range(at: 0), in: relevant),
                  let used = humanNumber(String(relevant[first])),
                  let limit = humanNumber(String(relevant[second])) else { return nil }
            return (used, limit, String(relevant[whole]))
        }
        return values.count == 3 ? values : nil
    }

    private func humanNumber(_ value: String) -> Double? {
        let upper = value.uppercased()
        let multiplier: Double = upper.hasSuffix("K") ? 1_000 : upper.hasSuffix("M") ? 1_000_000 : upper.hasSuffix("B") ? 1_000_000_000 : 1
        let number = upper.trimmingCharacters(in: CharacterSet(charactersIn: "KMB"))
        return Double(number).map { $0 * multiplier }
    }

    private static func load(from url: URL) -> [ProviderUsage]? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode([ProviderUsage].self, from: data)
    }

    private static func normalized(_ existing: [ProviderUsage]) -> [ProviderUsage] {
        var result = existing
        // Migração da primeira interface, que expunha campos manuais e criava
        // linhas incompletas. Os dados anteriores eram todos demonstrativos.
        if result.contains(where: { $0.name == "Cursor" || $0.name == "Codex" }) {
            return ProviderUsage.defaults
        }
        result.removeAll {
            $0.kind == .custom || $0.name == "Gemini"
                || ($0.kind == .antigravity && ["Antigravity · RPM", "Antigravity · TPM", "Antigravity · RPD"].contains($0.name))
        }
        for index in result.indices where result[index].detail != nil {
            result[index].detail = result[index].detail?
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        for required in ProviderUsage.defaults where !result.contains(where: { $0.name == required.name }) {
            result.append(required)
        }
        let canonicalOrder = ProviderUsage.defaults.map(\.name)
        result.sort {
            (canonicalOrder.firstIndex(of: $0.name) ?? canonicalOrder.count)
                < (canonicalOrder.firstIndex(of: $1.name) ?? canonicalOrder.count)
        }
        return result
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(providers) else { return }
        try? data.write(to: storageURL, options: [.atomic])
    }
}
