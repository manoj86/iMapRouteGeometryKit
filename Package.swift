// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iMapRouteGeometryKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "iMapRouteGeometryKit",
            targets: ["iMapRouteGeometryKit"]
        )
    ],
    targets: [
        .target(
            name: "iMapRouteGeometryKit"
        ),
        .testTarget(
            name: "iMapRouteGeometryKitTests",
            dependencies: ["iMapRouteGeometryKit"]
        )
    ]
)
