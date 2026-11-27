# XibToSwiftUI — Native macOS Zip / XIB → SwiftUI Converter

A native macOS Xcode & SwiftUI application that takes a `.zip` archive of Interface Builder `.xib` files (or individual `.xib` files) and converts them head-to-head into clean SwiftUI views.

## Features
- **Zip & XIB Upload / Drag-and-Drop**: Extracts `.zip` archives natively (`/usr/bin/unzip`, skipping `__MACOSX`) and collects all `.xib` screens.
- **Head-to-Head XIB AST → SwiftUI Generator**: Converts `UIStackView`, `UILabel`, `UIButton`, `UITextField`, `UITextView`, `UIImageView`, `UISwitch`, `UISlider`, `UISegmentedControl`, `UIScrollView`, `UITableView`, `UICollectionView`, `UIProgressView`, `UIActivityIndicatorView`, and `UIVisualEffectView` (Liquid Glass `.glassEffect`) with `@State` bindings, fonts, colors, and `#Preview`.
- **Native macOS UI**: Side-by-side parsed XIB hierarchy / raw XML inspector and live generated SwiftUI code viewer, 1-click Copy, Export All `.swift`, and built-in Sample XIB loader.
- **Xcode Project + SwiftPM**: Open `XibToSwiftUI.xcodeproj` directly in Xcode 27 or run `swift test`.

## Build & Test

```bash
# Run unit tests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test

# Build & test native macOS app via Xcode
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project XibToSwiftUI.xcodeproj -scheme XibToSwiftUI -destination 'platform=macOS' build test
```

## PR Forge Integration
This repository integrates [`shubhransh-gupta/pr-forge@v1`](https://github.com/shubhransh-gupta/pr-forge) via `.github/workflows/pr-forge.yml` and `.github/PULL_REQUEST_TEMPLATE.md`.
