# Agent instructions

## Project overview

Calendr is a **macOS menu bar calendar application** built in Swift. It displays events and reminders from the system calendar, upcoming events and reminders as separate items in the menu bar, and fullscreen notifications.

## Building and Testing

The app supports both Xcode and SPM build systems.
There's a convenience `assemble.sh` script to build and package the app bundle without Xcode.
Testing with SPM is as simple as running `swift test`.

## Architecture

The project follows **MVVM (Model-View-ViewModel)** with **RxSwift** for reactive bindings.

- **Models** – Plain data structures in `Calendr/Models/` (e.g. `CalendarModel`, `EventModel`)
- **ViewModels** – Reactive state/logic classes named `*ViewModel` (e.g. `CalendarViewModel`, `EventViewModel`)
- **ViewControllers / Views** – AppKit `NSViewController` / `NSView` subclasses for UI, with some SwiftUI components
- **Providers** – Service abstractions named `*Provider` in `Calendr/Providers/` (e.g. `CalendarServiceProvider`, `WeatherServiceProvider`)
- **Mocks** – Test doubles prefixed with `Mock` and stored in `Calendr/Mocks/`

## Key dependencies

| Package | Purpose |
|---------|---------|
| RxSwift / RxCocoa | Reactive programming and bindings |
| swift-collections | Additional collection types |
| swift-clocks | Testable clocks for async logic |
| sentry-cocoa | Error tracking |
| KeyboardShortcuts | Global keyboard shortcut support |
| ZIPFoundation | ZIP file handling |

## Coding conventions

- **Swift** is the primary language; a small `CalendrObjC` target handles Objective-C bridging
- The app requires **macOS 14+** and must not use deprecated APIs
- Use `BehaviorSubject` and `PublishSubject` for ViewModel state; expose read-only `Observable` to consumers
- Inject all services (providers) into ViewModels via initialiser parameters — do not reference singletons directly from ViewModels
- Dispose RxSwift subscriptions with a `DisposeBag` stored on the owner
- Localised strings are code-generated via **swiftgen** into `Calendr/Constants/Strings.generated.swift` — always reference `Strings.*` constants instead of raw string literals for UI text

## File / folder organisation

```
Calendr/
  Assets/          – Images and .lproj localization files
  Calendar/        – Calendar grid view + ViewModel
  Components/      – Reusable UI components
  Constants/       – Auto-generated string constants (Strings.generated.swift)
  Editors/         – Reminder / event editor ViewControllers and ViewModels
  Enums/           – App-wide Swift enums
  Events/          – Event list, event details, context menu
  Extensions/      – Swift standard library and AppKit extensions
  Main/            – App entry point and root ViewController
  MenuBar/         – Menu bar status item components
  Models/          – Shared data models (CalendarModel, EventModel, …)
  Mocks/           – Shared mock objects (also used in tests via @testable import)
  Providers/       – System service abstractions
  Schedulers/      – Custom RxSwift schedulers
  Settings/        – Settings UI and ViewModels
  Utils/           – Utility functions

CalendrTests/      – XCTest unit tests (see CalendrTests/AGENTS.md)
```

## Localization

- All user-visible strings must be added to `Calendr/Assets/en.lproj/Localizable.strings`
- After editing localisation files, regenerate `Strings.generated.swift` with the **Generate Strings** VS Code task (uses `swiftgen`)
- Track missing translations in `MISSING_TRANSLATIONS.md`
