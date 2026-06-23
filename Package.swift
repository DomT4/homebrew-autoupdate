// swift-tools-version: 5.7

import PackageDescription

let package = Package(
  name: "homebrew-autoupdate",
  platforms: [
    .macOS(.v11),
  ],
  products: [
    .executable(
      name: "brew-autoupdate-notifier",
      targets: ["BrewAutoupdateNotifier"]
    ),
  ],
  targets: [
    .executableTarget(
      name: "BrewAutoupdateNotifier",
      path: "notifier",
      exclude: [
        "README.md",
        "applet.icns",
        "brew-autoupdate.app",
        "build.sh",
        "notify.sh",
      ],
      sources: ["notifier.swift"]
    ),
  ]
)
