//
//  MockStatusItemSettings.swift
//  Calendr
//
//  Created by Paker on 22/07/23.
//

#if DEBUG

import RxSwift

class MockStatusItemSettings: StatusItemSettings {

    let toggleIcon: AnyObserver<Bool>
    let toggleDate: AnyObserver<Bool>
    let toggleLunarDate: AnyObserver<Bool>
    let statusItemBackgroundStyleObserver: AnyObserver<StatusItemBackgroundStyle>
    let statusItemIconStyleObserver: AnyObserver<StatusItemIconStyle>
    let statusItemDateStyleObserver: AnyObserver<StatusItemDateStyle>
    let statusItemDateFormatObserver: AnyObserver<String>
    let showEventStatusItemObserver: AnyObserver<Bool>

    let showStatusItemIcon: Observable<Bool>
    let showStatusItemDate: Observable<Bool>
    let showStatusItemLunarDate: Observable<Bool>
    let statusItemBackgroundStyle: Observable<StatusItemBackgroundStyle>
    let statusItemIconStyle: Observable<StatusItemIconStyle>
    let statusItemDateStyle: Observable<StatusItemDateStyle>
    let statusItemDateFormat: Observable<String>
    let showEventStatusItem: Observable<Bool>
    let statusItemTextScaling: Observable<Double>

    let openOnHover: Observable<Bool> = .just(false)

    init(
        showIcon: Bool = true,
        showDate: Bool = true,
        showLunarDate: Bool = false,
        backgroundStyle: StatusItemBackgroundStyle = .transparent,
        iconStyle: StatusItemIconStyle = .calendar,
        dateStyle: StatusItemDateStyle = .short,
        dateFormat: String = "",
        showNextEvent: Bool = true,
        textScaling: Double = 1
    ) {
        (showStatusItemIcon, toggleIcon) = BehaviorSubject.pipe(value: showIcon)
        (showStatusItemDate, toggleDate) = BehaviorSubject.pipe(value: showDate)
        (showStatusItemLunarDate, toggleLunarDate) = BehaviorSubject.pipe(value: showLunarDate)
        (statusItemBackgroundStyle, statusItemBackgroundStyleObserver) = BehaviorSubject.pipe(value: backgroundStyle)
        (statusItemIconStyle, statusItemIconStyleObserver) = BehaviorSubject.pipe(value: iconStyle)
        (statusItemDateStyle, statusItemDateStyleObserver) = BehaviorSubject.pipe(value: dateStyle)
        (statusItemDateFormat, statusItemDateFormatObserver) = BehaviorSubject.pipe(value: dateFormat)
        (showEventStatusItem, showEventStatusItemObserver) = BehaviorSubject.pipe(value: showNextEvent)
        statusItemTextScaling = .just(textScaling)
    }
}

#endif
