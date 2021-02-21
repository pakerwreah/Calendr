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
        settings: Observable<StatusItemSettings>,
        locale: Locale,
        notificationCenter: NotificationCenter
    ) {

        let titleIcon = NSAttributedString(string: "📅", attributes: [
            .font: NSFont(name: "SegoeUISymbol", size: Constants.iconPointSize)!,
            .baselineOffset: Constants.iconBaselineOffset
        ])

        let dateFormatter = DateFormatter(locale: locale)

        let currentLocaleDidChange = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .toVoid()
            .startWith(())

        text = Observable.combineLatest(
            dateObservable, settings, currentLocaleDidChange
        )
        .map { date, settings, _ in

            dateFormatter.dateStyle = settings.dateStyle

            let title = NSMutableAttributedString()

            if settings.showIcon {
                title.append(titleIcon)
            }

            if settings.showDate {
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
