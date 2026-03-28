# Copilot Instructions for Calendr

## Project Overview

Calendr is a **macOS menu bar calendar application** built in Swift targeting macOS 14+. It displays calendar events and reminders from the system calendar and supports weather integration, time zone display, keyboard shortcuts, and a URL scheme for opening specific dates.

## Architecture

The project follows **MVVM (Model-View-ViewModel)** with **RxSwift** for reactive bindings.

- **Models** – Plain data structures in `Calendr/Models/` (e.g. `CalendarModel`, `EventModel`)
- **ViewModels** – Reactive state/logic classes named `*ViewModel` (e.g. `CalendarViewModel`, `EventViewModel`)
- **ViewControllers / Views** – AppKit `NSViewController` / `NSView` subclasses for UI, with some SwiftUI components
- **Providers** – Service abstractions named `*Provider` in `Calendr/Providers/` (e.g. `CalendarServiceProvider`, `WeatherServiceProvider`)
- **Mocks** – Test doubles prefixed with `Mock` and stored in `CalendrTests/Mocks/`

## Key Dependencies (Package.swift)

| Package | Purpose |
|---------|---------|
| RxSwift / RxCocoa / RxTest | Reactive programming and bindings |
| swift-collections | Additional collection types |
| swift-clocks | Testable clocks for time-dependent logic |
| sentry-cocoa | Error tracking |
| KeyboardShortcuts | Global keyboard shortcut support |
| ZIPFoundation | ZIP file handling |

## Coding Conventions

- **Swift** is the primary language; a small `CalendrObjC` target handles Objective-C bridging
- Use `BehaviorSubject` and `PublishSubject` for ViewModel state; expose read-only `Observable` to consumers
- Inject all services (providers) into ViewModels via initialiser parameters — do not reference singletons directly from ViewModels
- Dispose RxSwift subscriptions with a `DisposeBag` stored on the owner
- Localised strings are code-generated via **swiftgen** into `Calendr/Constants/Strings.generated.swift` — always reference `Strings.*` constants instead of raw string literals for UI text
- Use factory helpers (`*.make(...)`) defined in `Calendr/Mocks/Factories/` when constructing model objects in tests

## File / Folder Organisation

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

CalendrTests/      – XCTest unit tests
  Mocks/           – Mock providers used in tests
  Schedulers/      – Scheduler utilities for tests
```

## Building and Testing

**Build for testing** (used in CI):
```bash
xcodebuild build-for-testing -scheme "Calendr" \
  COMPILER_INDEX_STORE_ENABLE=NO CODE_SIGNING_ALLOWED=NO
```

**Run tests** (requires a prior build step):
```bash
xcodebuild test-without-building -scheme "Calendr" | xcbeautify
```

Tests use **XCTest** with **RxTest** (`HistoricalScheduler`, `TestableObserver`) for testing reactive streams. Always write tests in `CalendrTests/` using mock providers from `CalendrTests/Mocks/`.

## Testing Patterns

- Each test class creates subjects, mock providers, and a `lazy var viewModel` in `setUp`
- Use `HistoricalScheduler` to control RxSwift time in tests
- Assert using `XCTAssert*` on values collected from observable streams
- Mock providers expose mutable `m_*` properties (e.g. `calendarService.m_events`) that tests configure before observing

## Localization

- All user-visible strings must be added to `Calendr/Assets/en.lproj/Localizable.strings`
- After editing localisation files, regenerate `Strings.generated.swift` with the **Generate Strings** VS Code task (uses `swiftgen`)
- Track missing translations in `MISSING_TRANSLATIONS.md`

## Important Notes

- The app requires macOS 14+ and must not use deprecated APIs removed before that version
- Code signing is disabled during CI (`CODE_SIGNING_ALLOWED=NO`)
- Entitlements (`Calendr.entitlements`) include WeatherKit, Apple Events, and executable-file access — avoid adding entitlements without a clear functional requirement
