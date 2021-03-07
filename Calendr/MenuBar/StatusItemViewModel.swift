//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import RxCocoa
import RxSwift

class StatusItemViewModel {

    let text: Observable<NSAttributedString>

    init(
        dateObservable: Observable<Date>,
        settings: StatusItemSettings,
        dateProvider: DateProviding,
        notificationCenter: NotificationCenter
    ) {

        let titleIcon = NSAttributedString(string: "📅", attributes: [
            .font: Fonts.SegoeUISymbol.regular.font(size: 14),
            .baselineOffset: -1
        ])

        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .toVoid()
            .startWith(())

        let dateFormatterObservable = Observable.combineLatest(
            settings.statusItemDateStyle,
            localeChangeObservable
        )
        .map { dateStyle, _ in
            DateFormatter(locale: dateProvider.calendar.locale).with(style: dateStyle)
        }

        text = Observable.combineLatest(
            dateObservable,
            settings.showStatusItemIcon,
            settings.showStatusItemDate,
            dateFormatterObservable
        )
        .map { date, showIcon, showDate, dateFormatter in

            let title = NSMutableAttributedString()

            if showIcon {
                title.append(titleIcon)
            }

            if showDate {
                if title.length > 0 {
                    title.append(NSAttributedString(string: "  "))
                }
                title.append(NSAttributedString(string: dateFormatter.string(from: date)))
            }

            return title
        }
    }
}
