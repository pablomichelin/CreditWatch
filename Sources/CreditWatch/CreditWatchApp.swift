import SwiftUI
import AppKit

@MainActor
final class CreditWatchAppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification, object: nil
        )
        statusBarEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseDown) { event in
            let hasVisibleMainWindow = NSApp.windows.contains { self.isMainWindow($0) && $0.isVisible }
            guard event.clickCount == 2, !hasVisibleMainWindow else { return event }
            NSApp.setActivationPolicy(.regular)
            NotificationCenter.default.post(name: .creditWatchOpenSettings, object: nil)
            return nil
        }
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, isMainWindow(window) else { return }
        NSApp.setActivationPolicy(.regular)
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, isMainWindow(window) else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let hasVisibleWindow = NSApp.windows.contains { self.isMainWindow($0) && $0.isVisible }
            if !hasVisibleWindow { NSApp.setActivationPolicy(.accessory) }
        }
    }

    private func isMainWindow(_ window: NSWindow) -> Bool {
        // Detecta pelo identifier da janela ao invés do título localizado,
        // para não quebrar caso o macOS localize o título em versões futuras.
        if let id = window.identifier?.rawValue {
            return id.contains("CreditWatch")
        }
        // Fallback: títulos conhecidos em pt-BR e en
        let knownTitles = ["CreditWatch", "CreditWatch Settings", "Configurações"]
        return knownTitles.contains(window.title)
    }
}

@main
struct CreditWatchApp: App {
    @NSApplicationDelegateAdaptor(CreditWatchAppDelegate.self) private var appDelegate
    @StateObject private var store = UsageStore()

    var body: some Scene {
        WindowGroup("CreditWatch") {
            DashboardView()
                .environmentObject(store)
                .onOpenURL { url in store.importUsage(from: url) }
        }

        MenuBarExtra {
            UsageMenu()
                .environmentObject(store)
        } label: {
            CreditWatchMenuBarLabel(title: store.menuBarTitle)
                .onAppear { store.startAutoRefresh() }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
