import SwiftUI
import AppKit
import ServiceManagement

enum AppInfo {
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    static let projectURL = URL(string: "https://github.com/pablomichelin/CreditWatch")!
    static var reportErrorURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "pablo@systemup.inf.br"
        components.queryItems = [
            URLQueryItem(name: "subject", value: "CreditWatch v\(version) — relato de erro"),
            URLQueryItem(name: "body", value: "Olá Pablo,\n\nDescreva aqui o erro encontrado:\n\n")
        ]
        return components.url!
    }

    static func openReportEmail() {
        let workspace = NSWorkspace.shared
        if workspace.urlForApplication(withBundleIdentifier: "com.microsoft.Outlook") != nil {
            let opener = Process()
            opener.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            opener.arguments = ["-b", "com.microsoft.Outlook", reportErrorURL.absoluteString]
            if (try? opener.run()) != nil { return }
        }
        workspace.open(reportErrorURL)
    }
}

extension Notification.Name {
    static let creditWatchOpenSettings = Notification.Name("CreditWatchOpenSettings")
}

struct CreditWatchMenuBarLabel: View {
    let title: String
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Label(title, systemImage: "gauge.with.dots.needle.33percent")
            .onReceive(NotificationCenter.default.publisher(for: .creditWatchOpenSettings)) { _ in
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
    }
}

struct UsageMenu: View {
    @EnvironmentObject private var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .clipShape(.rect(cornerRadius: 6))
                VStack(alignment: .leading, spacing: 1) {
                    Text("CreditWatch").font(.headline)
                    Text("Seus limites de IA, em um lugar")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if store.providers.filter(\.enabled).isEmpty {
                Text("Nenhum provedor ativo").foregroundStyle(.secondary)
            }
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(store.providers.filter(\.enabled)) { provider in
                        ProviderRow(provider: provider, compact: true)
                    }
                }
            }
            .frame(height: 300)
            HStack(spacing: 6) {
                Text(store.refreshStatus)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Button(action: { store.refreshNow() }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Atualizar agora")
            }
            Divider()
            HStack(spacing: 14) {
                SettingsLink { Label("Configurar", systemImage: "gearshape") }
                Button(action: AppInfo.openReportEmail) {
                    Label("Reportar", systemImage: "exclamationmark.bubble")
                }
                Spacer()
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                }
                .help("Sair")
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .foregroundStyle(.secondary)
            Link(destination: AppInfo.projectURL) {
                HStack(spacing: 4) {
                    Text("CreditWatch v\(AppInfo.version)")
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(12)
        .frame(width: 320)
        .onAppear { store.refreshNow() }
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: UsageStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 14) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().frame(width: 54, height: 54).clipShape(.rect(cornerRadius: 14))
                VStack(alignment: .leading, spacing: 3) {
                    Text("CreditWatch").font(.largeTitle).fontWeight(.bold)
                    Text("Uso e renovação das suas IAs").foregroundStyle(.secondary)
                }
                Spacer()
                SettingsLink { Label("Configurar", systemImage: "gearshape") }
            }
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(store.providers.filter(\.enabled)) { provider in
                        ProviderRow(provider: provider)
                            .padding(12)
                            .background(.quaternary, in: .rect(cornerRadius: 12))
                    }
                }
            }
            Link(destination: AppInfo.projectURL) {
                HStack(spacing: 4) {
                    Text("CreditWatch v\(AppInfo.version) · Ver no GitHub")
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                }
            }
            .font(.caption).foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(minWidth: 580, minHeight: 480)
        .onAppear { store.startAutoRefresh() }
    }
}

struct ProviderRow: View {
    let provider: ProviderUsage
    var compact = false

    private var isUsageValue: Bool { provider.unit.contains("usado") }
    private var available: Int? {
        guard provider.remaining >= 0 else { return nil }
        return isUsageValue ? max(0, 100 - provider.remaining) : min(100, provider.remaining)
    }
    private var valueText: String {
        guard let available else { return provider.detail ?? "Ainda não atualizado" }
        if isUsageValue { return "\(available)% restante · \(provider.remaining)% usado" }
        return "\(available)% restante"
    }
    private var resetText: String {
        if let resetLabel = provider.resetLabel { return resetLabel }
        guard let resetsAt = provider.resetsAt else { return "Conecte para ver a renovação" }
        if resetsAt <= .now { return "renovação pendente" }
        return "volta a 100% " + resetsAt.formatted(.relative(presentation: .named))
    }

    private var compactValueText: String {
        guard available == nil else { return valueText }
        guard let detail = provider.detail else { return "Não atualizado" }
        return detail.components(separatedBy: " · ").first ?? detail
    }

    private var compactSecondaryText: String {
        if available == nil, let detail = provider.detail {
            let parts = detail.components(separatedBy: " · ")
            if parts.count > 1 {
                return parts.dropFirst().joined(separator: " · ")
            }
        }
        return resetText
    }

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Circle().fill(provider.kind.color)
                            .frame(width: 7, height: 7)
                        Text(provider.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(compactValueText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    if let available {
                        ProgressView(value: Double(available), total: 100)
                            .tint(provider.kind.color)
                            .controlSize(.mini)
                    }
                    Text(compactSecondaryText)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
                .padding(.vertical, 5)
            } else {
                HStack(alignment: .top) {
                    Circle().fill(provider.kind.color)
                        .frame(width: 9, height: 9)
                        .padding(.top, 5)
                    VStack(alignment: .leading, spacing: 5) {
                        HStack {
                            Text(provider.name)
                                .font(.body)
                                .fontWeight(.semibold)
                            Spacer()
                            Text(valueText)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        if let available {
                            ProgressView(value: Double(available), total: 100)
                                .tint(provider.kind.color)
                                .controlSize(.regular)
                        }
                        Text(resetText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: UsageStore
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @State private var launchError: String?
    @State private var connecting: ProviderKind?

    var body: some View {
        Form {
            Section("Contas conectadas") {
                List {
                    ForEach(ProviderKind.supportedCases) { kind in
                        let metrics = store.providers.filter { $0.kind == kind }
                        if !metrics.isEmpty {
                            AccountEditor(
                                kind: kind,
                                metrics: metrics,
                                onConnect: { connecting = kind },
                                onDelete: { store.removeAccount(kind: kind) }
                            )
                        }
                    }
                }
                .frame(minHeight: 270)
                HStack {
                    Menu("Adicionar IA") {
                        ForEach(ProviderKind.supportedCases) { kind in
                            Button(kind.rawValue) { store.addAccount(kind: kind) }
                        }
                    }
                    Text("Use Conectar para entrar na conta e atualizar os números.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Section("Aplicativo") {
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        Image(systemName: "power.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Iniciar com o Mac")
                                .fontWeight(.medium)
                            Text("Mantém o CreditWatch disponível na barra de menus")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $launchAtLogin)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: launchAtLogin) { _, enabled in
                                do {
                                    if enabled { try SMAppService.mainApp.register() }
                                    else { try SMAppService.mainApp.unregister() }
                                    launchError = nil
                                } catch {
                                    launchError = "Não foi possível alterar a inicialização automática. Instale o app em Aplicativos e tente novamente."
                                    launchAtLogin = false
                                }
                            }
                    }
                    .padding(12)

                    Divider().padding(.leading, 46)

                    Button(action: AppInfo.openReportEmail) {
                        HStack(spacing: 12) {
                            Image(systemName: "exclamationmark.bubble")
                                .font(.system(size: 16))
                                .foregroundStyle(.secondary)
                                .frame(width: 22)
                            Text("Reportar um problema")
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                        .padding(12)
                    }
                    .buttonStyle(.plain)
                }
                .background(.quaternary.opacity(0.45), in: .rect(cornerRadius: 11))
                .overlay {
                    RoundedRectangle(cornerRadius: 11)
                        .stroke(.quaternary, lineWidth: 1)
                }
                if let launchError { Text(launchError).font(.caption).foregroundStyle(.red) }
                Link(destination: AppInfo.projectURL) {
                    HStack(spacing: 4) {
                        Text("CreditWatch v\(AppInfo.version) · Projeto no GitHub")
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 8))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
            }
        }
        .padding()
        .frame(width: 620, height: 500)
        .sheet(item: $connecting) { kind in
            ConnectProviderView(kind: kind).environmentObject(store)
        }
        .onAppear { store.startAutoRefresh() }
    }
}

struct AccountEditor: View {
    let kind: ProviderKind
    let metrics: [ProviderUsage]
    let onConnect: () -> Void
    let onDelete: () -> Void

    private var isConnected: Bool {
        metrics.contains(where: { $0.remaining >= 0 || $0.detail != nil || $0.lastUpdatedAt != nil })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 10) {
                Circle().fill(kind.color).frame(width: 12, height: 12)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.rawValue).fontWeight(.semibold)
                    HStack(spacing: 4) {
                        if isConnected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                        Text(statusText).font(.caption).foregroundStyle(.secondary)
                    }
                }
                if metrics.count > 1 {
                    Text(metricSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Button(isConnected ? "Reconectar" : "Conectar", action: onConnect)
                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .help("Remover a conta \(kind.rawValue)")
            }
        }
    }

    private var metricSummary: String {
        metrics.map(\.name)
            .map { $0.replacingOccurrences(of: "\(kind.rawValue) · ", with: "") }
            .joined(separator: " · ")
    }

    private var statusText: String {
        isConnected ? "Conectado" : "Conecte sua conta"
    }
}
