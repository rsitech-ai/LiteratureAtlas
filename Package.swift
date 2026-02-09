// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "LiteratureAtlas",
    platforms: [
        .macOS("26.0"),
        .iOS("26.0")
    ],
    products: [
        .executable(name: "LiteratureAtlas", targets: ["LiteratureAtlas"])
    ],
    targets: [
        .systemLibrary(
            name: "AtlasFFIClib",
            path: "analytics/ffi/include",
            pkgConfig: nil,
            providers: []
        ),
        .executableTarget(
            name: "LiteratureAtlas",
            dependencies: [
                .target(name: "AtlasFFIClib")
            ],
            path: "Sources/LiteratureAtlas"
        ),
        .testTarget(
            name: "LiteratureAtlasTests",
            dependencies: ["LiteratureAtlas"],
            path: "Tests/LiteratureAtlasTests"
        )
    ]
)
