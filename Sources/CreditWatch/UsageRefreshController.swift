import AppKit
import Foundation
import WebKit

enum VisiblePageSnapshot {
    static let script = #"""
    JSON.stringify({
      lines: (document.body ? document.body.innerText.split('\n') : [])
        .map(x => x.trim())
        .filter(x => /usage|uso|billing|cobrança|plan|free|gratuito|limit|weekly|semanal|rate|reset|remaining|restante|redefini|renova|auto renew|included usage|extra usage|credits|créditos|balance|saldo|chatgpt|plus|pro|grok|supergrok|imagine|voice|build|cursor models|other models|on-demand|gemini|rpm|tpm|rpd|%|(?:R\$|US\$|\$|€)|^[0-9]+(?:\.[0-9]+)?[KMB]?$|^[0-9.]+[KMB]?\s*\/$|^[0-9.]+[KMB]?\s*\/\s*[0-9.]+[KMB]?$/i.test(x)),
      meters: Array.from(document.querySelectorAll('progress,[role="progressbar"]')).map(x => ({
        value: x.value ?? x.getAttribute('aria-valuenow'),
        max: x.max ?? x.getAttribute('aria-valuemax'),
        label: x.getAttribute('aria-label') || x.textContent || ''
      }))
    })
    """#

    static func text(from snapshot: String) -> String {
        guard let data = snapshot.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let lines = object["lines"] as? [String]
        else { return "" }
        return lines.joined(separator: "\n")
    }
}

@MainActor
final class UsageRefreshController: NSObject, WKNavigationDelegate {
    private weak var store: UsageStore?
    private var webViews: [ProviderKind: WKWebView] = [:]
    private var timer: Timer?
    private var observers: [NSObjectProtocol] = []

    init(store: UsageStore) {
        self.store = store
        super.init()
    }

    func start() {
        guard timer == nil else { return }
        refreshAll()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        }
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        observers.append(workspaceCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        })
        observers.append(NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.refreshAll() }
        })
    }

    func refreshAll() {
        guard let store else { return }
        store.setRefreshing(true)
        let enabledKinds = Set(store.providers.filter(\.enabled).map(\.kind))
        for kind in enabledKinds where kind != .antigravity {
            guard let url = kind.usageURL else { continue }
            let webView = webView(for: kind)
            var request = URLRequest(url: url)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.timeoutInterval = 25
            webView.load(request)
        }
        if enabledKinds.contains(.antigravity) {
            Task { [weak self] in
                guard let self, let data = await AntigravityUsageClient.fetch() else { return }
                _ = self.store?.importAntigravityUsage(data)
            }
        }
        Task { @MainActor [weak store] in
            try? await Task.sleep(for: .seconds(12))
            store?.setRefreshing(false)
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let kind = webViews.first(where: { $0.value === webView })?.key else { return }
        for delay in [0.5, 1.5, 3.5, 6.0, 10.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak webView] in
                guard let self, let webView else { return }
                self.read(webView, for: kind)
            }
        }
    }

    private func webView(for kind: ProviderKind) -> WKWebView {
        if let existing = webViews[kind] { return existing }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
        webView.navigationDelegate = self
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"
        webViews[kind] = webView
        return webView
    }

    private func read(_ webView: WKWebView, for kind: ProviderKind) {
        webView.evaluateJavaScript(VisiblePageSnapshot.script) { [weak self] result, error in
            guard error == nil, let snapshot = result as? String else { return }
            Task { @MainActor in
                guard let self else { return }
                _ = self.store?.importVisibleUsage(VisiblePageSnapshot.text(from: snapshot), for: kind)
            }
        }
    }
}

/// Lê a mesma resposta local usada por Models & Usage no Antigravity.
/// O token efêmero é usado somente em memória e nunca é persistido.
enum AntigravityUsageClient {
    private struct LocalService {
        let pid: Int
        let csrfToken: String
    }

    static func fetch() async -> Data? {
        for service in discoverServices() {
            for port in listeningPorts(for: service.pid) {
                guard let url = URL(string: "http://127.0.0.1:\(port)/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary") else { continue }
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.timeoutInterval = 3
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("1", forHTTPHeaderField: "Connect-Protocol-Version")
                request.setValue(service.csrfToken, forHTTPHeaderField: "x-codeium-csrf-token")
                request.httpBody = Data(#"{"forceRefresh":true}"#.utf8)
                guard let (data, response) = try? await URLSession.shared.data(for: request),
                      (response as? HTTPURLResponse)?.statusCode == 200,
                      data.range(of: Data(#""groups""#.utf8)) != nil else { continue }
                return data
            }
        }
        return nil
    }

    private static func discoverServices() -> [LocalService] {
        guard let output = run("/bin/ps", ["-axo", "pid=,command="]) else { return [] }
        let candidates = output.split(separator: "\n").map(String.init).filter {
            ($0.contains("language_server_macos_arm") || $0.contains("language_server_macos_x64") || $0.contains("language_server_macos"))
                && $0.contains("--csrf_token")
        }.sorted { lhs, rhs in
            lhs.contains("--enable_lsp") == false && rhs.contains("--enable_lsp")
        }
        let pattern = #"^\s*([0-9]+)\s+.*--csrf_token\s+([^\s]+)"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        return candidates.compactMap { line in
            guard let match = expression.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)),
                  let pidRange = Range(match.range(at: 1), in: line),
                  let tokenRange = Range(match.range(at: 2), in: line),
                  let pid = Int(line[pidRange]) else { return nil }
            return LocalService(pid: pid, csrfToken: String(line[tokenRange]))
        }
    }

    private static func listeningPorts(for pid: Int) -> [Int] {
        guard let output = run("/usr/sbin/lsof", ["-nP", "-a", "-p", String(pid), "-iTCP", "-sTCP:LISTEN"]) else { return [] }
        let pattern = #"127\.0\.0\.1:([0-9]+) \(LISTEN\)"#
        guard let expression = try? NSRegularExpression(pattern: pattern) else { return [] }
        return expression.matches(in: output, range: NSRange(output.startIndex..., in: output)).compactMap { match in
            guard let range = Range(match.range(at: 1), in: output) else { return nil }
            return Int(output[range])
        }
    }

    private static func run(_ executable: String, _ arguments: [String]) -> String? {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        guard (try? process.run()) != nil else { return nil }
        // Leia o pipe enquanto o processo está ativo. Esperar antes pode
        // bloquear quando `ps` produz mais dados que o buffer do pipe.
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
