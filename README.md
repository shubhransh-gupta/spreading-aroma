# 🌿 Spreading Aroma (`XibToSwiftUI`)

**Spreading Aroma** is a native macOS Xcode & SwiftUI application that infuses Interface Builder `.xib` files (uploaded singly or inside `.zip` archives) head-to-head into clean, zero-bloat SwiftUI views — built and continuously enhanced using **[PR Forge](https://github.com/shubhransh-gupta/pr-forge)** (`shubhransh-gupta/pr-forge@v1` on GitHub Marketplace).

## Features
- **Zip & XIB Drop / Upload**: Extracts `.zip` archives natively (`/usr/bin/unzip`, skipping `__MACOSX`), filters screens via `.searchable`, and converts multiple XIBs in one pass.
- **Head-to-Head XIB AST → SwiftUI Generator**: Converts `UIStackView`, `UILabel`, `UIButton`, `UITextField`, `UITextView`, `UIImageView`, `UISwitch`, `UISlider`, `UISegmentedControl`, `UIScrollView`, `UITableView`, `UICollectionView`, `UIProgressView`, `UIActivityIndicatorView`, and `UIVisualEffectView` (Liquid Glass `.glassEffect`), including fonts, colors, `numberOfLines`, `textAlignment`, `alpha`, `hidden`, `contentMode`, and `@State` bindings.
- **3-Pane Live Preview + Code Inspector**: Switch between **Live SwiftUI Preview**, **Parsed XIB Hierarchy**, and **Raw XML** alongside generated SwiftUI code.
- **Export Ready**: 1-click Copy, Export All `.swift` files to a folder, or Export as a `.zip` bundle (`SpreadingAroma-SwiftUI.zip`).

## Build & Test

```bash
# Run SwiftPM unit tests
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test

# Build & test native macOS app via Xcode
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project SpreadingAroma.xcodeproj -scheme SpreadingAroma -destination 'platform=macOS' build test
```

## Direct PR Forge Integration
This repository integrates **[PR Forge](https://github.com/shubhransh-gupta/pr-forge)** directly via [`.github/workflows/pr-forge.yml`](.github/workflows/pr-forge.yml) and [`.github/PULL_REQUEST_TEMPLATE.md`](.github/PULL_REQUEST_TEMPLATE.md). Comment `/forge` or add the `pr-forge` label on any PR to run autonomous PRD + Figma + Xcode 27 skill implementation.
