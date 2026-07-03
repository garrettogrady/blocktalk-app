// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BlockTalk",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "BlockTalk",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
            ],
            path: "BlockTalk"
        ),
    ]
)
