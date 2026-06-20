//
//  MainViewModel.swift
//  Calendr
//
//  Created by Paker on 19/06/2026.
//

import AppKit
import RxSwift

class MainViewModel {

    enum UpdateAction: Equatable {
        case openSettings(SettingsTab)
        case installUpdate
        case openReleasePage
    }

    enum CreateMenuItem: Equatable {
        case separator
        case newEvent
        case quickReminder(title: String, offset: DateComponents)
        case newReminder
    }

    private static let quickReminderOffsets: [DateComponents] = [
        .init(minute: 5),
        .init(minute: 15),
        .init(minute: 30),
        .init(hour: 1),
        .init(day: 1)
    ]

    let selectDateObserver: AnyObserver<Date>
    let resetObserver: AnyObserver<Void>
    let prevMonthObserver: AnyObserver<Void>
    let nextMonthObserver: AnyObserver<Void>
    let navigationObserver: AnyObserver<Keyboard.Key>
    let viewDidDisappearObserver: AnyObserver<Void>
    let searchInputTextObserver: AnyObserver<String>
    let searchInputFocusObserver: AnyObserver<Bool>
    let showSearchInputObserver: AnyObserver<Void>
    let hideSearchInputObserver: AnyObserver<Void>
    let acceptSearchInputSuggestionObserver: AnyObserver<Void>
    let deeplinkObserver: AnyObserver<URL>
    let keyboardModifiersObserver: AnyObserver<NSEvent.ModifierFlags>
    let openCalendarDateObserver: AnyObserver<Date>
    let openCalendarObserver: AnyObserver<Void>

    let selectedDate: Observable<Date>
    let refreshDate: Observable<Void>
    let searchInputText: Observable<String>
    let searchInputSuggestion: Observable<DateSuggestionResult?>
    let searchInputSuggestionText: Observable<String?>
    let isSearchInputSuggestionHidden: Observable<Bool>
    let isSearchInputHidden: Observable<Bool>
    let isCreateButtonHidden: Observable<Bool>
    let updateError: Observable<UpdateError>
    let updateAction: Observable<UpdateAction>
    let showMainPopover: Observable<Void>
    let keyboardModifiers: Observable<NSEvent.ModifierFlags>

    let isShowingDetailsModal = BehaviorSubject(value: false)

    var currentSelectedDate: Date { selectedDateSubject.current }
    var currentSearchInputSuggestion: DateSuggestionResult? { searchInputSuggestionSubject.current }

    var createMenuItems: [CreateMenuItem] {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .named

        var items: [CreateMenuItem] = [.newEvent]

        if dateProvider.isDateInToday(currentSelectedDate) {
            items.append(.separator)

            for offset in Self.quickReminderOffsets {
                let title = Strings.Reminder.Options.remind(formatter.localizedString(from: offset))
                items.append(.quickReminder(title: title, offset: offset))
            }
        } else {
            items.append(.newReminder)
        }

        return items
    }

    private let disposeBag = DisposeBag()

    private let selectDate: Observable<Date>
    private let viewDidDisappear: Observable<Void>
    private let showSearchInput: Observable<Void>
    private let hideSearchInput: Observable<Void>
    private let acceptSearchInputSuggestion: Observable<Void>
    private let deeplink: Observable<URL>
    private let openCalendarDate: Observable<Date>
    private let openCalendar: Observable<Void>
    private let searchInputFocus: Observable<Bool>
    private let searchInputHiddenSubject = BehaviorSubject(value: true)

    private let selectedDateSubject: BehaviorSubject<Date>
    private let searchInputSuggestionSubject = BehaviorSubject<DateSuggestionResult?>(value: nil)

    private let dateProvider: DateProviding

    init(
        dateProvider: DateProviding,
        settings: CalendarSettings,
        autoUpdater: AutoUpdating,
        isAppActive: Observable<Bool>,
        notificationCenter: NotificationCenter,
        workspace: WorkspaceServiceProviding
    ) {
        self.dateProvider = dateProvider

        let calendar = dateProvider.calendar

        let navigation: Observable<Keyboard.Key>
        let resetInput: Observable<Void>
        let prevMonth: Observable<Void>
        let nextMonth: Observable<Void>

        (selectDate, selectDateObserver) = PublishSubject.pipe()
        (navigation, navigationObserver) = PublishSubject.pipe()
        (resetInput, resetObserver) = PublishSubject.pipe()
        (prevMonth, prevMonthObserver) = PublishSubject.pipe()
        (nextMonth, nextMonthObserver) = PublishSubject.pipe()
        (viewDidDisappear, viewDidDisappearObserver) = PublishSubject.pipe()
        (searchInputText, searchInputTextObserver) = BehaviorSubject.pipe(value: "")
        (searchInputFocus, searchInputFocusObserver) = BehaviorSubject.pipe(value: false)
        (showSearchInput, showSearchInputObserver) = PublishSubject.pipe()
        (hideSearchInput, hideSearchInputObserver) = PublishSubject.pipe()
        (acceptSearchInputSuggestion, acceptSearchInputSuggestionObserver) = PublishSubject.pipe()
        (deeplink, deeplinkObserver) = PublishSubject.pipe()
        (openCalendarDate, openCalendarDateObserver) = PublishSubject.pipe()
        (openCalendar, openCalendarObserver) = PublishSubject.pipe()
        (keyboardModifiers, keyboardModifiersObserver) = BehaviorSubject.pipe(value: [])

        selectedDateSubject = BehaviorSubject(value: dateProvider.now)

        let refreshFromDisappear = viewDidDisappear
            .withLatestFrom(settings.preserveSelectedDate)
            .filter(!)
            .void()

        let calendarDayChanged = notificationCenter.rx.notification(.NSCalendarDayChanged).void()
        let didWake = workspace.notificationCenter.rx.notification(NSWorkspace.didWakeNotification).void()

        refreshDate = Observable
            .merge(refreshFromDisappear, calendarDayChanged, didWake)
            .startWith(())
            .share(replay: 1)

        let reset = Observable.merge(resetInput, refreshDate.void())

        let backspace = navigation.matching(.backspace).void()

        let keyLeft = navigation.matching(.arrow(.left)).void()
        let keyRight = navigation.matching(.arrow(.right)).void()
        let keyDown = navigation.matching(.arrow(.down)).void()
        let keyUp = navigation.matching(.arrow(.up)).void()

        let cmdUpLeft = navigation.matching(.command(.arrow(.up)), .command(.arrow(.left))).void()
        let cmdDownRight = navigation.matching(.command(.arrow(.down)), .command(.arrow(.right))).void()

        var timeZone = calendar.timeZone

        selectedDate = Observable.merge(
            reset.map { dateProvider.now },
            backspace.map { dateProvider.now },
            selectDate.startWith(dateProvider.now)
        )
        .flatMapLatest { date in
            Observable<(Calendar.Component, Int)>.merge(
                keyLeft.map { (.day, -1) },
                keyRight.map { (.day, 1) },
                keyUp.map { (.weekOfMonth, -1) },
                keyDown.map { (.weekOfMonth, 1) },
                Observable.merge(prevMonth, cmdUpLeft).map { (.month, -1) },
                Observable.merge(nextMonth, cmdDownRight).map { (.month, 1) }
            )
            .scan(date) { current, operation in
                let (component, value) = operation
                return calendar.date(byAdding: component, value: value, to: current) ?? current
            }
            .startWith(date)
        }
        .distinctUntilChanged { a, b in
            timeZone == calendar.timeZone && calendar.isDate(a, inSameDayAs: b)
        }
        .do(afterNext: { _ in
            timeZone = calendar.timeZone
        })
        .share(replay: 1)

        selectedDate
            .bind(to: selectedDateSubject)
            .disposed(by: disposeBag)

        searchInputSuggestion = searchInputSuggestionSubject.asObservable()

        let formatter = DateFormatter(calendar: dateProvider.calendar)
        formatter.dateStyle = .long

        searchInputSuggestionText = searchInputSuggestion
            .map { suggestion in
                suggestion.map { formatter.string(from: $0.date) }
            }

        isSearchInputSuggestionHidden = Observable
            .combineLatest(searchInputSuggestion, searchInputFocus, searchInputHiddenSubject)
            .map { suggestion, hasFocus, isHidden in
                suggestion == nil || !hasFocus || isHidden
            }
            .distinctUntilChanged()

        isSearchInputHidden = searchInputHiddenSubject.distinctUntilChanged()

        isCreateButtonHidden = selectedDate
            .map { date in
                dateProvider.calendar.isDate(date, lessThan: dateProvider.now, granularity: .day)
            }
            .distinctUntilChanged()

        let deeplinkDate = deeplink
            .compactMap { url -> Date? in
                guard let action = url.host, action == "date" else {
                    return nil
                }
                let result = DateSearchParser.parse(text: url.lastPathComponent, using: dateProvider)
                return result?.date
            }
            .share(replay: 1)

        showMainPopover = deeplinkDate.void()

        Observable.merge(
            openCalendarDate.map { ($0, CalendarViewMode.day) },
            Observable
                .combineLatest(selectedDate, settings.calendarAppViewMode)
                .sample(openCalendar)
        )
        .bind { date, mode in
            workspace.open(date, mode: mode)
        }
        .disposed(by: disposeBag)

        updateError = autoUpdater.error
        updateAction = autoUpdater.notificationTap.map {
            switch $0 {
            case .newVersion(.default):
                return .openSettings(.about)

            case .newVersion(.install):
                return .installUpdate

            case .updated:
                return .openReleasePage
            }
        }

        setUpBindings(deeplinkDate: deeplinkDate, isAppActive: isAppActive)
    }

    private func setUpBindings(deeplinkDate: Observable<Date>, isAppActive: Observable<Bool>) {

        searchInputText
            .map { [dateProvider] text in
                DateSearchParser.parse(text: text, using: dateProvider)
            }
            .bind(to: searchInputSuggestionSubject)
            .disposed(by: disposeBag)

        Observable.merge(hideSearchInput, viewDidDisappear)
            .map(true)
            .bind(to: searchInputHiddenSubject)
            .disposed(by: disposeBag)

        Observable.merge(
            viewDidDisappear.void(),
            isAppActive.matching(false).void()
        )
        .map([])
        .bind(to: keyboardModifiersObserver)
        .disposed(by: disposeBag)

        showSearchInput
            .map(false)
            .bind(to: searchInputHiddenSubject)
            .disposed(by: disposeBag)

        Observable.merge(
            hideSearchInput.void(),
            viewDidDisappear.void()
        )
        .map("")
        .bind(to: searchInputTextObserver)
        .disposed(by: disposeBag)

        acceptSearchInputSuggestion
            .withLatestFrom(searchInputSuggestion)
            .skipNil()
            .bind { [selectDateObserver, searchInputTextObserver] suggestion in
                selectDateObserver.onNext(suggestion.date)
                searchInputTextObserver.onNext(suggestion.result)
            }
            .disposed(by: disposeBag)

        deeplinkDate
            .bind(to: selectDateObserver)
            .disposed(by: disposeBag)
    }
}
