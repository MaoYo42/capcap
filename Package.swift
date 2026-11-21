// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "capcap",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "capcap", targets: ["capcap"]),
        .executable(name: "CapcapShareExtension", targets: ["CapcapShareExtension"])
    ],
    targets: [
        .target(
            name: "SystemSettingsKit",
            path: "ThirdParty/PermissionFlow/Sources/SystemSettingsKit"
        ),
        .target(
            name: "PermissionFlow",
            dependencies: ["SystemSettingsKit"],
            path: "ThirdParty/PermissionFlow/Sources/PermissionFlow",
            // PermissionFlowButton.swift is a SwiftUI convenience wrapper that
            // capcap never instantiates, and it relies on the `@StateObject`
            // macro. That macro's plugin (libSwiftUIMacros.dylib) only ships
            // with a full Xcode install, so building with Command Line Tools
            // alone fails on it. Dropping the unused file keeps the package
            // buildable without Xcode.
            exclude: ["PermissionFlowButton.swift"],
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "capcap",
            dependencies: [
                "PermissionFlow"
            ],
            path: "capcap",
            exclude: ["App/Info.plist"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("AVKit"),
                .linkedFramework("ScreenCaptureKit"),
                .linkedFramework("Vision"),
                .linkedFramework("VisionKit"),
                .linkedFramework("CoreImage"),
                .linkedFramework("ImageIO"),
                .linkedFramework("QuickLookThumbnailing"),
                .linkedFramework("QuickLookUI"),
                .linkedFramework("UniformTypeIdentifiers"),
                .linkedFramework("Carbon"),
                .linkedFramework("VideoToolbox"),
                .linkedLibrary("z"),
            ]
        ),
        .executableTarget(
            name: "CapcapShareExtension",
            path: "capcap-share-extension",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("UniformTypeIdentifiers"),
            ]
        ),
        .testTarget(
            name: "capcapTests",
            dependencies: ["capcap"],
            path: "Tests/capcapTests"
        )
    ]
)
