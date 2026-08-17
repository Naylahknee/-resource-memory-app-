# iOS Share Extension setup

Resource Memory already handles incoming shared URLs, text, and images in Flutter. This branch adds the native Share Extension source files so the remaining work in Xcode is configuration rather than writing the extension from scratch.

## Required Xcode steps

1. Open `ios/Runner.xcworkspace` in Xcode.
2. File → New → Target → Share Extension. Name it `Share Extension`.
3. Replace the target-generated `Info.plist` and `ShareViewController.swift` with the files already committed in `ios/Share Extension/`.
4. Make the Share Extension deployment target match Runner (iOS 13+).
5. Enable Swift Package Manager for Flutter if needed: `flutter config --enable-swift-package-manager`.
6. In the Share Extension target → General → Frameworks and Libraries, add the `FlutterGeneratedPluginSwiftPackage` product that exposes `receive_sharing_intent`.
7. In Signing & Capabilities, add App Groups to both Runner and Share Extension. Use the same group for both targets.
8. Add the user-defined build setting `CUSTOM_GROUP_ID` to both targets and set it to that App Group identifier.
9. In Runner Build Phases, ensure `Embed Foundation Extension` is above `Thin Binary`.
10. Build on a physical iPhone and test Share → Resource Memory from Safari/Threads/YouTube and from Photos.

## Behavior

The extension auto-redirects into Resource Memory. Flutter receives the shared item through `receive_sharing_intent`, saves it with `IncomingShareService`, and opens the Library.

## Important

`receive_sharing_intent` 1.9.x uses Swift Package Manager on iOS and requires the UIScene lifecycle on current Flutter/iOS toolchains. The Share Extension target and App Group must be created/configured in Xcode because those are Xcode project/signing capabilities, not Dart settings.
