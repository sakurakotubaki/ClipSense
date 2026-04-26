# ClipSense

ClipSense is a native macOS clipboard history app built with SwiftUI, AppKit, SwiftData, and NSPasteboard.

It runs from the menu bar, stays out of the Dock, watches text clipboard changes, filters sensitive-looking content, and stores useful clipboard history locally with SwiftData.

## Features

- Menu bar resident macOS app using `NSStatusItem` and `NSPopover`
- Dock-hidden app behavior via `LSUIElement`
- Text clipboard monitoring with `NSPasteboard`
- Image clipboard monitoring for copied screenshots and image files
- Local persistence with SwiftData
- PNG image storage in Application Support with SwiftData metadata
- Searchable clipboard history
- Pinned items shown above recent history
- Copy, pin, unpin, and delete actions per item
- Click or press Return to copy a selected item back to the clipboard
- Keyboard navigation for history selection
- Security filter for sensitive-looking clipboard content
- Global hot key registration for opening the clipboard history with `Command + Shift + V`
- Copy feedback sound using `ClipSense/BGM/cursor-bgm.mp3`

## Security Filtering

ClipSense intentionally skips storing clipboard content that looks sensitive or low-value:

- Empty or whitespace-only text
- Credit-card-like numbers that pass a Luhn check
- 6-8 digit one-time passcodes
- Long random-looking strings such as tokens or secrets
- Consecutive duplicate copies

The filtering logic is centralized in `ClipboardSecurityFilter` so future exclusions can be added for apps, password managers, private browsing contexts, or automatic retention policies.

## Architecture

ClipSense uses a simple Model-View architecture:

- `@Model ClipboardItem` defines the SwiftData record.
- `@Observable` model types own app and screen state.
- SwiftUI views render state and forward user actions.
- `ClipboardRepository` owns SwiftData mutations and pasteboard write-back.
- `ClipboardImageStore` writes copied images as PNG files under Application Support and keeps only metadata in SwiftData.
- `PasteboardMonitor` watches `NSPasteboard` with Swift Concurrency.
- `StatusBarController` owns the menu bar item and popover presentation.
- `GlobalHotKeyManager` registers the default global shortcut with Carbon hot key APIs.
- `ClipboardSoundPlayer` plays bundled copy feedback audio after a successful clipboard save or recopy.

The project avoids new `ObservableObject`, `@StateObject`, `@ObservedObject`, and `@Published` code. New state should use Swift Observation with `@Observable` and `@Bindable`.

## Shortcut

The default shortcut is:

```text
Command + Shift + V
```

This shortcut is registered globally by `GlobalHotKeyManager`. When pressed, ClipSense toggles the clipboard history popover from the menu bar using `NSStatusItem` and `NSPopover`.

## Development

Open the project in Xcode:

```sh
open ClipSense.xcodeproj
```

Run tests from the command line:

```sh
xcodebuild test -scheme ClipSense -destination platform=macOS
```

SwiftLint is wired into the Xcode build as an optional Run Script phase. If `swiftlint` is installed, it runs during builds. If it is not installed, the build prints a warning and continues.

## Project Layout

```text
ClipSense/
  ClipSenseApp.swift
  Models/
    ClipboardItem.swift
    ClipboardHistoryModel.swift
    ClipSenseAppModel.swift
  Data/
    ClipboardRepository.swift
  Services/
    PasteboardMonitor.swift
    ClipboardSecurityFilter.swift
    SourceApplicationResolver.swift
    GlobalHotKeyManager.swift
    ClipboardSoundPlayer.swift
    StatusBarController.swift
    ClipboardImageStore.swift
    PasteboardImageReader.swift
  BGM/
    cursor-bgm.mp3
  Views/
    ClipboardHistoryView.swift
    ClipboardItemRowView.swift
    EmptyHistoryView.swift
```

## License

ClipSense is released under the MIT License. See [LICENSE](LICENSE).
