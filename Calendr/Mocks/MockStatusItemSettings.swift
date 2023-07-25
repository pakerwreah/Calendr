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
    let showStatusItemBackground: Observable<Bool>
    let statusItemIconStyle: Observable<StatusItemIconStyle>
    let statusItemDateStyle: Observable<StatusItemDateStyle>
    let statusItemDateFormat: Observable<String>
    let eventStatusItemDetectNotch: Observable<Bool>

    init(
        showIcon: Bool = true,
        showDate: Bool = true,
        showBackground: Bool = false,
        iconStyle: StatusItemIconStyle = .calendar,
        dateStyle: StatusItemDateStyle = .none,
        dateFormat: String = "E d MMM YYYY",
        detectNotch: Bool = false
    ) {
        showStatusItemIcon = .just(showIcon)
        showStatusItemDate = .just(showDate)
        showStatusItemBackground = .just(showBackground)
        statusItemIconStyle = .just(iconStyle)
        statusItemDateStyle = .just(dateStyle)
        statusItemDateFormat = .just(dateFormat)
        eventStatusItemDetectNotch = .just(detectNotch)
    }
}


#endif
