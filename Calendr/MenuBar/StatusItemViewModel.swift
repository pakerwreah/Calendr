//
//  StatusItemViewModel.swift
//  Calendr
//
//  Created by Paker on 18/01/21.
//

import Cocoa
import RxSwift

class StatusItemViewModel {

    let text: Observable<NSAttributedString>

    init(
        dateObservable: Observable<Date>,
        settings: StatusItemSettings,
        dateProvider: DateProviding,
        notificationCenter: NotificationCenter
    ) {

        let localeChangeObservable = notificationCenter.rx
            .notification(NSLocale.currentLocaleDidChangeNotification)
            .void()

        let dateFormatterObservable = settings.statusItemDateStyle
            .repeat(when: localeChangeObservable)
            .map { dateStyle in
                DateFormatter(calendar: dateProvider.calendar).with(style: dateStyle)
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
                let attachment = NSTextAttachment()
                attachment.image = Icons.MenuBar.icon.with(scale: .large)
                title.append(NSAttributedString(attachment: attachment))

                if #available(macOS 12, *) {
                    title.addAttributes(
                        [.font: NSFont.systemFont(ofSize: 15), .baselineOffset: -0.5],
                        range: NSRange(location: 0, length: title.length)
                    )
                }
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
