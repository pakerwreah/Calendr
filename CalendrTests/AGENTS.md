# Agent instructions

## Test setup

- Write tests in `CalendrTests/` using mock providers from `Calendr/Mocks/`
- Use factory helpers (`*.make(...)`) in [`Calendr/Mocks/Factories/`](../Calendr/Mocks/Factories/) when constructing model objects
- Tests use **XCTest** with **RxSwift** `HistoricalScheduler` and **swift-clocks** `TestClock` for async code

## XCTest expectations

Fulfill expectations where the asynchronous work actually completes. Do **not** use `DispatchQueue.async`, `asyncAfter`, or arbitrary delays to "give the test time" and then call `fulfill()`.

```swift
// Bad — fulfilling on a timer/queue instead of when the work finishes
let exp = expectation(description: "Done")
viewModel.load()
DispatchQueue.main.async {
    exp.fulfill()
}
wait(for: [exp], timeout: 0.1)

// Good — fulfill in the subscription/callback that represents the result
let exp = expectation(description: "Done")
viewModel.items.bind { items in
    XCTAssertEqual(items.count, 1)
    exp.fulfill()
}
.disposed(by: disposeBag)
viewModel.load()
wait(for: [exp], timeout: 0.1)

// Good — wire the expectation to the completion handler
let exp = expectation(description: "Should close window")
viewModel.onCloseConfirmed = exp.fulfill
viewModel.saveEvent()
waitForExpectations(timeout: 0.1)
```

When testing Rx chains, subscribe (or bind) in the test, capture/assert the value there, and fulfill inside that handler.

## Unit test dates

When writing or reviewing unit tests that involve dates:

### Use literal dates for expectations

Write expected dates with the `Date.make(...)` helper from [`Calendr/Mocks/Factories/Date+Factory.swift`](../Calendr/Mocks/Factories/Date+Factory.swift). Do **not** compute expected values by mirroring production date logic.

```swift
// Bad — expected value derived from input / calendar math
let expectedEnd = dateProvider.calendar.date(byAdding: .hour, value: 1, to: start)!
XCTAssertEqual(viewModel.endDate, expectedEnd)

// Good — literal expected date
XCTAssertEqual(viewModel.endDate, .make(year: 2025, month: 10, day: 25, hour: 12, minute: 0))
```

Prefer omitting `Date.` where Swift can infer the type (e.g. assignments to `Date` properties, function parameters). Use `let value: Date = .make(...)` when inference is not available.

### What is OK

- **Fixture setup** — building test inputs with relative offsets
- **Relationship checks** — asserting behavior relative to fixture data (e.g. refresh times are after event end times), not exact derived timestamps.
- **Scheduler / time advancement** — using durations from fixture spans to drive virtual clocks.

### Avoid fragile test init

Do not rely on convenience inits that default to `Date.now` while expectations assume `dateProvider.now`.
