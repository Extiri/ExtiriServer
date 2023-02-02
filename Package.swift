// swift-tools-version:5.5
import PackageDescription

let package = Package(
  name: "ExtiriServer",
  platforms: [
    .macOS(.v12)
  ],
  dependencies: [
    .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
    .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.0.0"),
    .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
    .package(url: "https://github.com/wiktorwojcik112/vapor-queues-fluent-driver.git", from: "1.0.0"),
    .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
    .package(url: "https://github.com/wiktorwojcik112/gatekeeper.git", from: "4.0.0"),
    .package(url: "https://github.com/wiktorwojcik112/graphql-kit", from: "2.0.0"),
    .package(name: "GraphiQLVapor", url: "https://github.com/alexsteinerde/graphiql-vapor.git", from: "2.0.0"),
    .package(url: "https://github.com/IBM-Swift/OpenSSL.git", from: "2.2.2"),
    .package(url: "https://github.com/Kitura/Swift-SMTP", .upToNextMinor(from: "5.1.0"))
  ],
  targets: [
    .target(
      name: "App",
      dependencies: [
        .product(name: "SwiftSMTP", package: "Swift-SMTP"),
        .product(name: "Fluent", package: "fluent"),
        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
        .product(name: "Vapor", package: "vapor"),
        .product(name: "Leaf", package: "leaf"),
        .product(name: "QueuesFluentDriver", package: "vapor-queues-fluent-driver"),
        .product(name: "JWT", package: "jwt"),
        .product(name: "Gatekeeper", package: "gatekeeper"),
        .product(name: "GraphQLKit", package: "graphql-kit"),
        .product(name: "GraphiQLVapor", package: "GraphiQLVapor"),
        "OpenSSL"
      ],
      swiftSettings: [
        .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release))
      ]
    ),
    .executableTarget(name: "Run", dependencies: [.target(name: "App")]),
    .testTarget(name: "AppTests", dependencies: [
      .target(name: "App"),
      .product(name: "XCTVapor", package: "vapor"),
    ])
  ]
)
