//
//  MockStatusItemSettings.swift
//  Calendr
//
//  Created by Paker on 22/07/23.
//

#if DEBUG

import RxSwift

class MockStatusItemSettings: StatusItemSettings {

    let showStatusItemIcon: Observable<Bool>
    let showStatusItemDate: Observable<Bool>
    let showStatusItemIconDate: Observable<Bool>
    let showStatusItemBackground: Observable<Bool>
    let statusItemDateStyle: Observable<DateStyle>
    let statusItemDateFormat: Observable<String>
    let eventStatusItemDetectNotch: Observable<Bool>

    init(
        showIcon: Bool = true,
        showDate: Bool = true,
        showIconDate: Bool = false,
        showBackground: Bool = false,
        dateStyle: DateStyle = .none,
        dateFormat: String = "E d MMM YYYY",
        detectNotch: Bool = false
    ) {
        showStatusItemIcon = .just(showIcon)
        showStatusItemDate = .just(showDate)
        showStatusItemIconDate = .just(showIconDate)
        showStatusItemBackground = .just(showBackground)
        statusItemDateStyle = .just(dateStyle)
        statusItemDateFormat = .just(dateFormat)
        eventStatusItemDetectNotch = .just(detectNotch)
    }
}


#endif
