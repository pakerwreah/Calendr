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
            .font: NSFont(name: "SegoeUISymbol", size: Constants.iconPointSize)!,
            .baselineOffset: Constants.iconBaselineOffset
        ])

        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .toVoid()
            .startWith(())

        let dateFormatterObservable = Observable.combineLatest(
            settings.statusItemDateStyle,
            localeChangeObservable
        )
        .map { dateStyle, _ -> DateFormatter in
            let dateFormatter = DateFormatter(locale: dateProvider.calendar.locale)
            dateFormatter.dateStyle = dateStyle
            return dateFormatter
        }

        text = Observable.combineLatest(
            dateObservable,
            settings.showStatusItemIcon,
            settings.showStatusItemDate,
            settings.statusItemDateStyle,
            dateFormatterObservable
        )
        .map { date, showIcon, showDate, dateStyle, dateFormatter in

            dateFormatter.dateStyle = dateStyle

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

private enum Constants {

    static let iconPointSize: CGFloat = 14
    static let iconBaselineOffset: CGFloat = -1
}
