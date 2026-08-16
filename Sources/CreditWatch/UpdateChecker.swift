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
                let downloadsDir = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)[0]
                let destURL = downloadsDir.appendingPathComponent(downloadURL.lastPathComponent)

                try? FileManager.default.removeItem(at: destURL)
                try FileManager.default.moveItem(at: tempURL, to: destURL)

                NSWorkspace.shared.open(destURL)
                self.isDownloading = false
            } catch {
                self.downloadError = error.localizedDescription
                self.isDownloading = false
                NSWorkspace.shared.open(downloadURL)
            }
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
