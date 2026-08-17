import AppKit
import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var downloadURL: URL?
    @Published var isDownloading = false
    @Published var downloadError: String?

    private let repoAPI = "https://api.github.com/repos/pablomichelin/CreditWatch/releases/latest"

    func checkForUpdates() {
        guard let url = URL(string: repoAPI) else { return }
        var request = URLRequest(url: url)
        request.setValue("CreditWatch-App", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        Task {
            guard let (data, response) = try? await URLSession.shared.data(for: request),
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else { return }

            let latest = tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
            let current = AppInfo.version

            if isNewer(latest: latest, current: current) {
                self.latestVersion = latest
                self.updateAvailable = true

                if let assets = json["assets"] as? [[String: Any]] {
                    if let dmgAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".dmg") == true }),
                       let browserURL = dmgAsset["browser_download_url"] as? String,
                       let target = URL(string: browserURL) {
                        self.downloadURL = target
                    } else if let zipAsset = assets.first(where: { ($0["name"] as? String)?.hasSuffix(".zip") == true }),
                              let browserURL = zipAsset["browser_download_url"] as? String,
                              let target = URL(string: browserURL) {
                        self.downloadURL = target
                    }
                }
                if self.downloadURL == nil {
                    self.downloadURL = URL(string: "https://github.com/pablomichelin/CreditWatch/releases/latest")
                }
            }
        }
    }

    func downloadAndInstall() {
        guard let downloadURL else {
            NSWorkspace.shared.open(AppInfo.projectURL.appendingPathComponent("releases/latest"))
            return
        }

        if !downloadURL.lastPathComponent.hasSuffix(".dmg") && !downloadURL.lastPathComponent.hasSuffix(".zip") {
            NSWorkspace.shared.open(downloadURL)
            return
        }

        isDownloading = true
        downloadError = nil

        Task {
            do {
                let (tempURL, _) = try await URLSession.shared.download(from: downloadURL)
                try await performAutoUpdate(downloadedFile: tempURL, originalFileName: downloadURL.lastPathComponent)
            } catch {
                self.downloadError = error.localizedDescription
                self.isDownloading = false
                // Fallback: abrir página de releases ou link direto
                NSWorkspace.shared.open(downloadURL)
            }
        }
    }

    private nonisolated func performAutoUpdate(downloadedFile: URL, originalFileName: String) async throws {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory.appendingPathComponent("CreditWatchUpdate-\(UUID().uuidString)")
        try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let archiveURL = tempDir.appendingPathComponent(originalFileName)
        if fileManager.fileExists(atPath: archiveURL.path) {
            try? fileManager.removeItem(at: archiveURL)
        }
        try fileManager.moveItem(at: downloadedFile, to: archiveURL)

        // Também salva uma cópia na pasta Downloads para conveniência do usuário
        let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
        let userDownloadCopy = downloadsDir.appendingPathComponent(originalFileName)
        try? fileManager.removeItem(at: userDownloadCopy)
        try? fileManager.copyItem(at: archiveURL, to: userDownloadCopy)

        var stagedAppURL: URL? = nil
        var mountPointURL: URL? = nil

        if originalFileName.hasSuffix(".dmg") {
            let mountDir = tempDir.appendingPathComponent("volume")
            try fileManager.createDirectory(at: mountDir, withIntermediateDirectories: true)

            let attachProcess = Process()
            attachProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
            attachProcess.arguments = ["attach", archiveURL.path, "-mountpoint", mountDir.path, "-nobrowse", "-quiet", "-noautoopen"]
            try attachProcess.run()
            attachProcess.waitUntilExit()

            if attachProcess.terminationStatus == 0 {
                mountPointURL = mountDir
                let appInMount = mountDir.appendingPathComponent("CreditWatch.app")
                if fileManager.fileExists(atPath: appInMount.path) {
                    let staged = tempDir.appendingPathComponent("CreditWatch.app")
                    try? fileManager.removeItem(at: staged)
                    try fileManager.copyItem(at: appInMount, to: staged)
                    stagedAppURL = staged
                }
            }
        } else if originalFileName.hasSuffix(".zip") {
            let extractDir = tempDir.appendingPathComponent("extracted")
            try fileManager.createDirectory(at: extractDir, withIntermediateDirectories: true)

            let unzipProcess = Process()
            unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            unzipProcess.arguments = ["-xk", archiveURL.path, extractDir.path]
            try unzipProcess.run()
            unzipProcess.waitUntilExit()

            let appInZip = extractDir.appendingPathComponent("CreditWatch.app")
            if fileManager.fileExists(atPath: appInZip.path) {
                stagedAppURL = appInZip
            }
        }

        guard let validStagedApp = stagedAppURL, fileManager.fileExists(atPath: validStagedApp.path) else {
            // Desmonta caso tenha montado
            if let mp = mountPointURL {
                let detachProcess = Process()
                detachProcess.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                detachProcess.arguments = ["detach", mp.path, "-force", "-quiet"]
                try? detachProcess.run()
                detachProcess.waitUntilExit()
            }
            // Abre o DMG baixado na pasta Downloads para o usuário instalar manualmente com o atalho
            await MainActor.run {
                NSWorkspace.shared.open(userDownloadCopy)
                self.isDownloading = false
            }
            return
        }

        // Determina destino do aplicativo
        let currentBundle = Bundle.main.bundlePath
        let targetAppPath: String
        if currentBundle.hasSuffix(".app") && !currentBundle.contains("/.build/") {
            targetAppPath = currentBundle
        } else {
            targetAppPath = "/Applications/CreditWatch.app"
        }

        let pid = ProcessInfo.processInfo.processIdentifier
        let updaterScriptURL = tempDir.appendingPathComponent("updater.sh")
        let detachCmd = mountPointURL != nil ? "/usr/bin/hdiutil detach \"\(mountPointURL!.path)\" -force 2>/dev/null || true" : ""

        let parentDir = (targetAppPath as NSString).deletingLastPathComponent
        let targetEscaped = targetAppPath
        let stagedEscaped = validStagedApp.path
        let script = """
        #!/bin/bash
        # Aguarda o app atual finalizar
        while kill -0 \(pid) 2>/dev/null; do
            sleep 0.1
        done
        sleep 0.3

        # Substitui a versão antiga pela nova
        mkdir -p "\(parentDir)"
        rm -rf "\(targetEscaped)"
        cp -R "\(stagedEscaped)" "\(targetEscaped)"
        xattr -cr "\(targetEscaped)" 2>/dev/null || true

        # Desmonta o volume do DMG caso esteja montado
        \(detachCmd)

        # Inicia a versão atualizada
        /usr/bin/open "\(targetEscaped)"

        # Limpa os arquivos temporários
        (sleep 5 && rm -rf "\(tempDir.path)") &
        """

        try script.write(to: updaterScriptURL, atomically: true, encoding: String.Encoding.utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: updaterScriptURL.path)

        // Lança o script de atualização desanexado em segundo plano
        let launcher = Process()
        launcher.executableURL = URL(fileURLWithPath: "/bin/bash")
        launcher.arguments = [updaterScriptURL.path]
        try launcher.run()

        // Encerra imediatamente a instância atual do CreditWatch
        await MainActor.run {
            NSApplication.shared.terminate(nil)
        }
    }

    private func isNewer(latest: String, current: String) -> Bool {
        let lParts = latest.split(separator: ".").compactMap { Int($0) }
        let cParts = current.split(separator: ".").compactMap { Int($0) }
        let maxCount = max(lParts.count, cParts.count)
        for i in 0..<maxCount {
            let l = i < lParts.count ? lParts[i] : 0
            let c = i < cParts.count ? cParts[i] : 0
            if l > c { return true }
            if l < c { return false }
        }
        return false
    }
}
