# Settle 📊

A SwiftUI app for polls & decisions with voting, sharing, and recommendations.

## Features
- Create polls with images + text (PhotosPicker)
- Double‑tap to vote with haptics
- Ranking (interest + friends + location + recency)
- Share polls via native share sheet
- iOS dark & light mode

## Dev
- SwiftUI + Combine
- Firebase-ready (not wired in this demo)
- Fastlane for TestFlight + screenshots
- GitHub Actions CI/CD

## Build locally
1. Install Xcode 15+
2. Open the project:
   - Option A (recommended): use XcodeGen
     - `brew install xcodegen`
     - `cd settle-app && xcodegen generate`
     - Open `Settle.xcodeproj`
   - Option B: open the workspace if present
3. Run the app on iOS 16+ simulator

## Permissions
- Photo Library (to attach images)
- Location When In Use (to rank nearby polls)
