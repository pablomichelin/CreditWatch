// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CreditWatch",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "CreditWatch", targets: ["CreditWatch"])],
    targets: [.executableTarget(name: "CreditWatch")]
)
