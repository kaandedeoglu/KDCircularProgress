// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "KDCircularProgress",
    products: [
        .library(name: "KDCircularProgress", targets: ["KDCircularProgress"])
    ],
    targets: [
        .target(
            name: "KDCircularProgress",
            path: "KDCircularProgress"
        )
    ]
)
