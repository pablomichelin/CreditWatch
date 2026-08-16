import SwiftUI
import WebKit

struct ConnectProviderView: View {
    let kind: ProviderKind
    @EnvironmentObject private var store: UsageStore
    @Environment(\.dismiss) private var dismiss
    @State private var webView = WKWebView()
    @State private var status = "Faça login; o CreditWatch atualiza ao abrir o painel."

    init(kind: ProviderKind) {
        self.kind = kind
        if kind == .antigravity {
            _status = State(initialValue: "Leitura automática ativa enquanto o Antigravity estiver aberto.")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Conectar \(kind.rawValue)").font(.title3).fontWeight(.semibold)
                    Text("A sessão fica salva somente neste Mac.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button("Fechar", action: { dismiss() })
            }
            .padding()
            Divider()
            if kind == .antigravity {
                VStack(spacing: 16) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 42))
                        .foregroundStyle(kind.color)
                    Text("O uso do Antigravity fica no aplicativo local")
                        .font(.title3).fontWeight(.semibold)
                    Text("O CreditWatch lê automaticamente os quatro limites reais enquanto o Antigravity estiver aberto. O AI Studio não é mais usado como fonte desses números.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: 480)
                    Button("Abrir Antigravity") {
                        NSWorkspace.shared.openApplication(
                            at: URL(fileURLWithPath: "/Applications/Antigravity IDE.app"),
                            configuration: .init()
                        )
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProviderWebView(webView: webView, url: kind.usageURL) { readVisiblePage() }
            }
            Divider()
            HStack {
                Text(status).font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button("Atualizar agora") {
                    if kind == .antigravity { store.refreshNow() }
                    else { readVisiblePage() }
                }
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 860, height: 650)
    }

    private func readVisiblePage() {
        webView.evaluateJavaScript(VisiblePageSnapshot.script) { result, error in
            if error != nil { status = "Não foi possível ler esta página ainda."; return }
            let snapshot = result as? String ?? "{}"
            status = store.importVisibleUsage(VisiblePageSnapshot.text(from: snapshot), for: kind)
        }
    }
}

struct ProviderWebView: NSViewRepresentable {
    let webView: WKWebView
    let url: URL?
    let pageDidLoad: () -> Void

    final class Coordinator: NSObject, WKNavigationDelegate {
        let pageDidLoad: () -> Void
        init(pageDidLoad: @escaping () -> Void) { self.pageDidLoad = pageDidLoad }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            for delay in [1.0, 3.0, 7.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { self.pageDidLoad() }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(pageDidLoad: pageDidLoad) }

    func makeNSView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        if url?.host == "grok.com" {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Safari/605.1.15"
        }
        if let url { webView.load(URLRequest(url: url)) }
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
